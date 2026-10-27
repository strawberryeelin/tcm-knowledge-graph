"""校验阶段05图谱 CSV 的 Schema、ID 和关系端点。"""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "05_graph_construction"))
import kg_schema



异常精确术语 = {
    "肉桂心",
    "半夏钱半",
    "附子钱半",
    "制附子钱半",
    "人参钱半",
    "干姜七分",
    "干姜一錢",
    "口疮之病",
    "吐狂血",
    "渗流中道",
    "渗留中道",
    "白术g",
    "法夏",
    "生草",
    "炙草",
    "煅瓦楞",
    "生石膏",
    "乌贼骨",
    "元胡",
    "吴萸",
    "广木香",
    "良姜",
    "丹皮",
    "萎蕤",
    "苏叶",
    "川棟子",
}
关注术语 = sorted(异常精确术语 | {"肉桂", "附子", "半夏", "人参", "吐血", "口疮"})
剂量样式 = re.compile(
    r"(钱半|錢半|(?:\d+(?:\.\d+)?|[零一二三四五六七八九十百千万半两]+)"
    r"(?:mg|mL|ml|g|克|毫克|枚|片|个|条|两|钱|錢|分|厘|升)|(?:mg|mL|ml|g|克|毫克)$)"
)


def 读取(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open("r", encoding="utf-8-sig", newline="") as csv_file:
        reader = csv.DictReader(csv_file)
        return list(reader.fieldnames or []), list(reader)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="验证按 kg_schema.py 生成的中文图谱 CSV")
    parser.add_argument("--dir", type=Path, required=True, help="本次阶段05生成的图谱 CSV 目录")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    paths = {
        "节点表": args.dir / "节点表.csv",
        "关系表": args.dir / "关系表.csv",
        "三元组表": args.dir / "三元组表.csv",
    }
    节点字段, 节点 = 读取(paths["节点表"])
    关系字段, 关系 = 读取(paths["关系表"])
    三元组字段, 三元组 = 读取(paths["三元组表"])
    三元组期望字段 = [
        "医案编号",
        "头节点ID",
        "头节点类型",
        "头实体",
        "关系",
        "尾节点ID",
        "尾节点类型",
        "尾实体",
        "原文术语",
        "原文表达",
        "剂量",
        "单位",
    ]

    节点ID集合 = {行["节点ID"] for 行 in 节点}
    节点类型计数: dict[str, int] = {}
    for 行 in 节点:
        节点类型计数[行["节点类型"]] = 节点类型计数.get(行["节点类型"], 0) + 1

    关系类型计数: dict[str, int] = {}
    for 行 in 关系:
        关系类型计数[行["关系类型"]] = 关系类型计数.get(行["关系类型"], 0) + 1

    包含统计 = {}
    for 术语 in 关注术语:
        包含统计[术语] = {
            "节点名称或规范名称精确": sum(
                行.get("名称") == 术语 or 行.get("规范名称") == 术语
                for 行 in 节点
            ),
            "三元组头尾实体精确": sum(
                行.get("头实体") == 术语 or 行.get("尾实体") == 术语
                for 行 in 三元组
            ),
            "全字段文本包含": sum(
                术语 in json.dumps(行, ensure_ascii=False)
                for 行 in [*节点, *关系, *三元组]
            ),
        }

    报告 = {
        "files": {名称: str(path) for 名称, path in paths.items()},
        "sizes": {名称: path.stat().st_size for 名称, path in paths.items()},
        "rows": {
            "节点表": len(节点),
            "关系表": len(关系),
            "三元组表": len(三元组),
        },
        "header_check": {
            "节点表字段匹配kg_schema": 节点字段 == list(getattr(kg_schema, "节点表字段", [])),
            "关系表字段匹配kg_schema": 关系字段 == list(getattr(kg_schema, "关系表字段", [])),
            "三元组表字段匹配脚本约定": 三元组字段 == 三元组期望字段,
            "节点表字段": 节点字段,
            "关系表字段": 关系字段,
            "三元组表字段": 三元组字段,
        },
        "node_types": 节点类型计数,
        "relation_types": 关系类型计数,
        "bad_node_types": sorted({
            行["节点类型"]
            for 行 in 节点
            if 行["节点类型"] not in kg_schema.节点类型白名单
        }),
        "bad_relation_patterns": sorted({
            (行["起点节点类型"], 行["关系类型"], 行["终点节点类型"])
            for 行 in 关系
            if (行["起点节点类型"], 行["关系类型"], 行["终点节点类型"])
            not in kg_schema.关系模式白名单
        }),
        "missing_endpoint_count": sum(
            行["起点节点ID"] not in 节点ID集合 or 行["终点节点ID"] not in 节点ID集合
            for 行 in 关系
        ),
        "bad_relation_attrs_by_schema": [
            {
                "关系ID": 行["关系ID"],
                "关系模式": [
                    行["起点节点类型"],
                    行["关系类型"],
                    行["终点节点类型"],
                ],
                "schema外非空字段": sorted(
                    key for key, value in 行.items()
                    if str(value or "").strip()
                    and key not in set(
                        kg_schema.关系属性模式.get(
                            (行["起点节点类型"], 行["关系类型"], 行["终点节点类型"]),
                            kg_schema.通用关系属性,
                        )
                    )
                ),
            }
            for 行 in 关系
            if any(
                str(value or "").strip()
                and key not in set(
                    kg_schema.关系属性模式.get(
                        (行["起点节点类型"], 行["关系类型"], 行["终点节点类型"]),
                        kg_schema.通用关系属性,
                    )
                )
                for key, value in 行.items()
            )
        ],
        "nonblank_dose_unit_relationships": [
            行 for 行 in 关系
            if str(行.get("剂量", "") or "").strip() or str(行.get("单位", "") or "").strip()
        ],
        "nonblank_dose_unit_triples": [
            行 for 行 in 三元组
            if str(行.get("剂量", "") or "").strip() or str(行.get("单位", "") or "").strip()
        ],
        "bad_node_exact": [
            行 for 行 in 节点
            if 行.get("名称") in 异常精确术语 or 行.get("规范名称") in 异常精确术语
        ],
        "bad_triple_entity_exact": [
            行 for 行 in 三元组
            if 行.get("头实体") in 异常精确术语 or 行.get("尾实体") in 异常精确术语
        ],
        "medicine_nodes_with_dose_like_name": [
            行 for 行 in 节点
            if 行.get("节点类型") == "中药" and 剂量样式.search(行.get("名称", ""))
        ],
        "contains": 包含统计,

    }

    for key in (
        "nonblank_dose_unit_relationships", "nonblank_dose_unit_triples",
        "bad_node_exact", "bad_triple_entity_exact", "medicine_nodes_with_dose_like_name",
    ):
        报告[key] = len(报告[key])
    节点ID列表 = [行["节点ID"] for 行 in 节点]
    关系ID列表 = [行["关系ID"] for 行 in 关系]
    报告["duplicate_node_ids"] = len(节点ID列表) - len(set(节点ID列表))
    报告["duplicate_relation_ids"] = len(关系ID列表) - len(set(关系ID列表))
    报告["valid"] = (
        all(报告["header_check"][key] for key in (
            "节点表字段匹配kg_schema", "关系表字段匹配kg_schema", "三元组表字段匹配脚本约定"
        ))
        and not 报告["bad_node_types"] and not 报告["bad_relation_patterns"]
        and not 报告["bad_relation_attrs_by_schema"]
        and 报告["missing_endpoint_count"] == 0
        and 报告["duplicate_node_ids"] == 0 and 报告["duplicate_relation_ids"] == 0
    )

    print(json.dumps(报告, ensure_ascii=False, indent=2))
    if not 报告["valid"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
