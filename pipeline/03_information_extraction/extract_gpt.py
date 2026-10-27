"""通过GPT5.5 接口抽取 医案。


"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
STAGE_DIR = Path(__file__).resolve().parent
DEFAULT_CASE_DIR = PROJECT_ROOT / "pipeline" / "02_case_preparation" / "output"
DEFAULT_MAPPING = DEFAULT_CASE_DIR / "医案映射清单.csv"
DEFAULT_PROMPT = STAGE_DIR / "prompts" / "最终提示词_单条医案_JSON版.txt"
DEFAULT_BASE_URL = "https://gptrouter.cn/v1"
DEFAULT_MODEL = "gpt-5.5"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="使用 GPT5.5 抽取已核对的医案文本")
    parser.add_argument("--case-dir", type=Path, default=DEFAULT_CASE_DIR)
    parser.add_argument("--mapping", type=Path, default=DEFAULT_MAPPING)
    parser.add_argument("--prompt", type=Path, default=DEFAULT_PROMPT)
    parser.add_argument("--result-root", type=Path, required=True, help="本次实验的全新输出目录")
    parser.add_argument("--cases", default="", help="可选的 Case ID 列表，逗号分隔；默认使用映射中的全部医案")
    parser.add_argument("--limit", type=int, default=0, help="仅处理前 N 条已选记录；0 表示全部")
    parser.add_argument("--base-url", default=os.getenv("ZHONGZHUAN_BASE_URL", DEFAULT_BASE_URL))
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--api-key-env", default="ZHONGZHUAN_API_KEY")
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--max-retries", type=int, default=3)
    parser.add_argument("--resume", action="store_true", help="仅在配置和医案文本完全相同时跳过已有响应")
    return parser.parse_args()


def read_mapping(path: Path) -> dict[str, dict[str, str]]:
    if not path.is_file():
        raise FileNotFoundError(f"缺少已核对的来源映射：{path}")
    with path.open("r", encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        required = {"医案编号", "文档名称", "文档内序号", "文本SHA256"}
        if not required.issubset(reader.fieldnames or []):
            raise ValueError("来源映射缺少医案编号、文档名称、文档内序号或文本SHA256")
        rows: dict[str, dict[str, str]] = {}
        for row in reader:
            case_id = row["医案编号"]
            if not re.fullmatch(r"Case\d+", case_id):
                raise ValueError(f"无效 Case ID：{case_id}")
            if case_id in rows:
                raise ValueError(f"来源映射存在重复 Case ID：{case_id}")
            if not row["文档名称"] or not row["文本SHA256"]:
                raise ValueError(f"来源或文本摘要缺失：{case_id}")
            rows[case_id] = row
    if not rows:
        raise ValueError("来源映射没有记录")
    return rows


def choose_cases(spec: str, mapping: dict[str, dict[str, str]], limit: int) -> list[str]:
    """保留映射中的原始编号，不按数量重新生成编号。"""
    if spec:
        ids = [part.strip() for part in spec.split(",")]
        if any(not re.fullmatch(r"Case\d+", value) for value in ids) or len(ids) != len(set(ids)):
            raise ValueError("--cases 必须是互不重复的 Case ID 列表")
        missing = [value for value in ids if value not in mapping]
        if missing:
            raise ValueError(f"指定 Case 不在已核对映射中：{', '.join(missing)}")
    else:
        ids = sorted(mapping, key=lambda value: int(value[4:]))
    if limit < 0:
        raise ValueError("--limit 不得小于零")
    if limit:
        ids = ids[:limit]
    if not ids:
        raise ValueError("没有选中的医案")
    return ids


def validate_cases(case_dir: Path, mapping: dict[str, dict[str, str]], ids: list[str]) -> dict[str, str]:
    texts: dict[str, str] = {}
    for case_id in ids:
        path = case_dir / f"{case_id}.txt"
        if not path.is_file():
            raise FileNotFoundError(f"缺少医案文本：{case_id}")
        text = path.read_text(encoding="utf-8-sig")
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
        if digest != mapping[case_id]["文本SHA256"]:
            raise ValueError(f"医案文本已变化，请重新核对来源映射：{case_id}")
        texts[case_id] = text
    return texts


def call_model(base_url: str, model: str, api_key: str, prompt: str, user_content: str, timeout: int) -> tuple[str, str]:
    """沿用历史网关的 /chat/completions、system/user 消息及 temperature=0。"""
    endpoint = f"{base_url.rstrip('/')}/chat/completions"
    payload = {"model": model, "messages": [
        {"role": "system", "content": prompt},
        {"role": "user", "content": user_content},
    ], "temperature": 0}
    request = urllib.request.Request(
        endpoint,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        data: dict[str, Any] = json.loads(response.read().decode("utf-8"))
    choices = data.get("choices") or []
    content = choices[0].get("message", {}).get("content") if choices else None
    if not isinstance(content, str) or not content.strip():
        raise ValueError("接口响应缺少非空 message.content")
    return content.strip(), str(data.get("id") or "")


def main() -> None:
    args = parse_args()
    mapping = read_mapping(args.mapping)
    ids = choose_cases(args.cases, mapping, args.limit)
    texts = validate_cases(args.case_dir, mapping, ids)
    if not args.prompt.is_file():
        raise FileNotFoundError(f"缺少提示词：{args.prompt}")
    prompt = args.prompt.read_text(encoding="utf-8-sig")
    api_key = os.getenv(args.api_key_env)
    if not api_key:
        raise RuntimeError(f"请设置 API 密钥环境变量：{args.api_key_env}")
    if args.max_retries < 1 or args.timeout < 1:
        raise ValueError("超时和重试次数必须为正数")

    result_dir = args.result_root / "抽取结果JSON"
    config_path = result_dir / "抽取运行配置.json"
    config = {
        "source": "GPT5.5", "model": args.model, "base_url": args.base_url,
        "prompt_sha256": hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
        "case_ids": ids,
        "case_sha256": {case_id: hashlib.sha256(texts[case_id].encode("utf-8")).hexdigest() for case_id in ids},
        "case_sources": {case_id: [mapping[case_id]["文档名称"], mapping[case_id]["文档内序号"]] for case_id in ids},
    }
    if args.result_root.exists() and any(args.result_root.iterdir()):
        if not args.resume or not config_path.is_file():
            raise FileExistsError(f"结果目录已有内容，请为新批次指定新目录：{args.result_root}")
        if json.loads(config_path.read_text(encoding="utf-8")) != config:
            raise ValueError("输出目录的模型、提示词、选案或文本摘要与本次运行不同，禁止复用旧响应")
    result_dir.mkdir(parents=True, exist_ok=True)
    config_path.write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    log_dir = args.result_root / "运行日志"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / f"GPT5.5抽取日志_{datetime.now():%Y%m%d_%H%M%S}.csv"
    log_rows: list[dict[str, str]] = []

    for case_id in ids:
        output_path = result_dir / f"{case_id}.txt"
        if output_path.exists():
            if not args.resume:
                raise FileExistsError(f"响应已存在：{output_path}")
            print(f"[跳过已有响应] {case_id}")
            continue
        source = mapping[case_id]
        user_content = (
            f"医案编号：{case_id}\n来源文档：{source['文档名称']}\n"
            f"文档内序号：{source['文档内序号']}\n医案原文：\n{texts[case_id]}"
        )
        content = ""
        request_id = ""
        error_summary = ""
        for attempt in range(1, args.max_retries + 1):
            try:
                content, request_id = call_model(args.base_url, args.model, api_key, prompt, user_content, args.timeout)
                break
            except urllib.error.HTTPError as error:
                error_summary = f"HTTP {error.code}"
            except Exception as error:
                error_summary = type(error).__name__
            if attempt < args.max_retries:
                time.sleep(2 ** attempt)
        if content:
            output_path.write_text(content + "\n", encoding="utf-8")
        log_rows.append({
            "医案编号": case_id, "状态": "成功" if content else "失败", "来源": "GPT5.5",
            "模型": args.model, "输出文件": str(output_path) if content else "",
            "请求ID": request_id, "错误信息": error_summary if not content else "",
            "运行时间": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        })
        print(f"{case_id}: {'成功' if content else '失败'}")
    fields = ["医案编号", "状态", "来源", "模型", "输出文件", "请求ID", "错误信息", "运行时间"]
    with log_path.open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        writer.writerows(log_rows)
    print(f"响应目录：{result_dir}\n运行日志：{log_path}")
    failures = [row["医案编号"] for row in log_rows if row["状态"] == "失败"]
    if failures:
        raise RuntimeError(f"以下医案未取得响应，请检查本地日志后在相同配置下 --resume：{', '.join(failures)}")


if __name__ == "__main__":
    main()
