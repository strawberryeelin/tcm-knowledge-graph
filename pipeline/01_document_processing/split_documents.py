"""读取原始 DOCX 的普通段落，按分隔线生成待人工筛选的医案片段。"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

项目根目录 = Path(__file__).resolve().parents[2]
默认输入目录 = 项目根目录 / "data" / "raw"
默认输出目录 = Path(__file__).resolve().parent / "output"


def 读取段落文本(文档路径: Path) -> str:
    from docx import Document

    文档 = Document(str(文档路径))
    段落列表: list[str] = []

    for 段落 in 文档.paragraphs:
        文本 = "".join(run.text for run in 段落.runs).strip()
        if 文本:
            段落列表.append(文本)

    return "\n".join(段落列表)


def 标准化文本(文本: str) -> str:
    文本 = 文本.replace("\r\n", "\n").replace("\r", "\n")
    文本 = re.sub(r"[ \t]+\n", "\n", 文本)
    文本 = re.sub(r"\n{3,}", "\n\n", 文本)
    return 文本.strip()


def 拆分医案(文本: str) -> list[str]:
    文本 = 标准化文本(文本)

    # 文档中既有中文长横线，也有 OCR/Word 转换后的连续半角横线。
    分隔线模式 = re.compile(
        r"(?:\n|^)\s*(?:[-－—–―﹣]{6,})\s*(?:\n|$)"
    )

    片段列表 = [
        标准化文本(片段)
        for 片段 in 分隔线模式.split(文本)
    ]

    return [
        片段
        for 片段 in 片段列表
        if 片段
    ]


def 文档排序键(文件路径: Path) -> tuple[str, str]:
    return (
        文件路径.name.casefold(),
        文件路径.name,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="按分隔线拆分 DOCX 医案，输出供人工筛选的 JSON")
    parser.add_argument("--input-dir", type=Path, default=默认输入目录)
    parser.add_argument("--output-dir", type=Path, default=默认输出目录)
    args = parser.parse_args()
    输入目录 = args.input_dir
    输出目录 = args.output_dir
    输出路径 = 输出目录 / "全部医案_按分隔线拆分.json"

    if not 输入目录.is_dir():
        raise FileNotFoundError(f"输入目录不存在：{输入目录}")
    if 输出路径.exists():
        raise FileExistsError(f"输出已存在，换用新批次目录以保留人工修改：{输出路径}")

    文档列表 = sorted(
        [
            文件
            for 文件 in 输入目录.glob("*.docx")
            if not 文件.name.startswith("~$")
        ],
        key=文档排序键,
    )

    if not 文档列表:
        raise RuntimeError(f"未找到 docx 文档：{输入目录}")

    输出记录: list[dict[str, object]] = []
    全局序号 = 1

    for 文档路径 in 文档列表:
        文本 = 读取段落文本(文档路径)
        医案列表 = 拆分医案(文本)

        for 文档内序号, 医案文本 in enumerate(医案列表, start=1):
            输出记录.append(
                {
                    "序号": 全局序号,
                    "文档名称": 文档路径.name,
                    "文档内序号": 文档内序号,
                    "具体医案": 医案文本,
                }
            )
            全局序号 += 1

    输出目录.mkdir(parents=True, exist_ok=True)
    输出路径.write_text(
        json.dumps(输出记录, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    文档统计 = {
        文档.name: 0
        for 文档 in 文档列表
    }
    for 记录 in 输出记录:
        文档统计[str(记录["文档名称"])] += 1

    print("=" * 60)
    print("医案拆分完成")
    print("=" * 60)
    print(f"输入目录：{输入目录}")
    print(f"文档数量：{len(文档列表)}")
    print(f"医案数量：{len(输出记录)}")
    print(f"输出文件：{输出路径}")
    print("-" * 60)
    for 文档名, 数量 in 文档统计.items():
        print(f"{文档名}\t{数量}")


if __name__ == "__main__":
    main()
