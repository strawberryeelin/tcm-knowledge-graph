"""将已验证的阶段05 CSV 整理为 Neo4j 导入包。"""

from __future__ import annotations

import argparse
import csv
import shutil
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "05_graph_construction"))
import kg_schema


默认输出目录 = Path(__file__).resolve().parent / "output"


def cypher_identifier(name: str) -> str:
    return f"`{name.replace('`', '``')}`"


def prop_expr(variable: str, field: str) -> str:
    ident = cypher_identifier(field)
    return (
        f"{variable}.{ident} = CASE WHEN trim(coalesce(row.{ident}, '')) <> '' "
        f"THEN row.{ident} ELSE {variable}.{ident} END"
    )


def 写无BOM_CSV(src: Path, dst: Path) -> None:
    with src.open("r", encoding="utf-8-sig", newline="") as in_file:
        reader = csv.DictReader(in_file)
        rows = list(reader)
        fieldnames = reader.fieldnames or []
    with dst.open("w", encoding="utf-8", newline="") as out_file:
        writer = csv.DictWriter(out_file, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def 生成节点导入语句(node_type: str) -> str:
    label = cypher_identifier(node_type)
    props = [field for field in kg_schema.节点表字段 if field != "节点ID"]
    set_lines = ",\n    ".join(prop_expr("n", field) for field in props)
    return f"""LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '{node_type}'
MERGE (n:`实体`:{label} {{`节点ID`: row.`节点ID`}})
SET {set_lines}
RETURN '{node_type}' AS 节点类型, count(n) AS 导入数量;"""


def 生成关系导入语句(pattern: tuple[str, str, str]) -> str:
    start_type, rel_type, end_type = pattern
    start_label = cypher_identifier(start_type)
    end_label = cypher_identifier(end_type)
    rel_label = cypher_identifier(rel_type)
    allowed_props = [
        field
        for field in kg_schema.关系属性模式[pattern]
        if field
        not in {
            "关系ID",
            "起点节点ID",
            "起点节点类型",
            "终点节点ID",
            "终点节点类型",
            "关系类型",
        }
    ]
    set_lines = ",\n    ".join(prop_expr("r", field) for field in allowed_props)
    return f"""LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '{start_type}'
  AND row.`关系类型` = '{rel_type}'
  AND row.`终点节点类型` = '{end_type}'
MATCH (s:`实体`:{start_label} {{`节点ID`: row.`起点节点ID`}})
MATCH (t:`实体`:{end_label} {{`节点ID`: row.`终点节点ID`}})
MERGE (s)-[r:{rel_label} {{`关系ID`: row.`关系ID`}}]->(t)
SET {set_lines}
RETURN '{start_type}-{rel_type}->{end_type}' AS 关系模式, count(r) AS 导入数量;"""


def 生成导入脚本() -> str:
    node_types = [
        node_type
        for node_type in kg_schema.节点属性模式
        if node_type in kg_schema.节点类型白名单
    ]
    relation_patterns = [
        pattern
        for pattern in kg_schema.关系属性模式
        if pattern in kg_schema.关系模式白名单
    ]
    parts = [
        """// Neo4j 导入脚本：按 kg_schema.py 生成
// 运行前：把本导入包中的 节点表.csv、关系表.csv 复制到当前 DBMS 的 import 目录。
// 设计原则：CSV 可保留“剂量、单位”列；导入时只有非空值才会写入关系属性。

CREATE CONSTRAINT `实体节点ID唯一` IF NOT EXISTS
FOR (n:`实体`) REQUIRE n.`节点ID` IS UNIQUE;

CREATE INDEX `实体节点类型名称索引` IF NOT EXISTS
FOR (n:`实体`) ON (n.`节点类型`, n.`名称`);

CALL db.awaitIndexes();""",
        *[生成节点导入语句(node_type) for node_type in node_types],
        *[生成关系导入语句(pattern) for pattern in relation_patterns],
    ]
    return "\n\n".join(parts) + "\n"


导入检查脚本 = """// Neo4j 导入检查

// 1. 节点总数和各类节点数
MATCH (n:`实体`)
RETURN n.`节点类型` AS 节点类型, count(*) AS 数量
ORDER BY 数量 DESC, 节点类型;

// 2. 关系总数和各类关系数
MATCH ()-[r]->()
RETURN type(r) AS 关系类型, count(*) AS 数量
ORDER BY 数量 DESC, 关系类型;

// 3. 缺失端点在 Neo4j 中不应存在；这里检查孤立实体节点，便于发现导入漏关系
MATCH (n:`实体`)
WHERE NOT (n)--()
RETURN n.`节点类型` AS 节点类型, n.`节点ID` AS 节点ID
ORDER BY 节点类型, 节点ID
LIMIT 50;

// 4. 当前标准化表没有剂量，导入后不应出现非空剂量/单位
MATCH ()-[r]->()
WHERE coalesce(r.`剂量`, '') <> '' OR coalesce(r.`单位`, '') <> ''
RETURN count(r) AS 非空剂量单位关系数, collect({关系类型: type(r), 关系ID: r.`关系ID`, 剂量: r.`剂量`, 单位: r.`单位`})[0..20] AS 示例;

// 5. 重点异常实体不应作为节点或三元组实体存在
MATCH (n:`实体`)
WHERE n.`名称` IN ['肉桂心','半夏钱半','附子钱半','制附子钱半','人参钱半','干姜七分','干姜一錢','口疮之病','渗留中道','渗流中道']
RETURN n.`节点类型` AS 节点类型, n.`名称` AS 名称, n.`节点ID` AS 节点ID;
"""


三类查询脚本 = """// 三类通用查询示例；执行前确认数据库已导入本批数据。

// 查询1：医案与症状体征
MATCH (c:`医案`)-[:`具有症状体征`]->(s:`症状体征`)
RETURN c.`医案编号` AS 医案编号, collect(DISTINCT s.`名称`) AS 症状体征
ORDER BY 医案编号 LIMIT 20;

// 查询2：证型分布
MATCH (c:`医案`)-[:`辨证为`]->(z:`证型`)
RETURN z.`名称` AS 证型, count(DISTINCT c) AS 医案数
ORDER BY 医案数 DESC LIMIT 20;

// 查询3：各医案方剂及其用药；按来源医案编号过滤共享方剂的组成关系
MATCH (c:`医案`)-[:`使用方剂`]->(f:`方剂`)-[r:`包含中药`]->(h:`中药`)
WHERE r.`来源医案编号` = c.`医案编号`
RETURN c.`医案编号` AS 医案编号, f.`名称` AS 方剂, collect(DISTINCT h.`名称`) AS 中药
ORDER BY 医案编号 LIMIT 20;
"""


导入说明 = """# Neo4j 导入说明

## 关于“剂量、单位”

CSV 表头和导入脚本保留 `剂量`、`单位`，因为当前 `kg_schema.py` 的关系表字段包含它们，且 `方剂-包含中药->中药` 关系属性模式允许它们。

当前构图脚本尚未提取剂量和单位，因此这些属性在新批次中可能为空。导入脚本只写入非空值；是否补充剂量需要另行核对来源和规则。

## 推荐执行顺序

1. 把本目录下 `节点表.csv`、`关系表.csv` 复制到 Neo4j DBMS 的 `import` 目录。
2. 启动数据库。
3. 在 Neo4j Browser 中切换到目标数据库，依次执行：
   - `导入脚本.cypher`
   - `导入检查.cypher`
   - `三类查询.cypher`

如果用 `cypher-shell`，示例：

```powershell
& "<DBMS_HOME>\\bin\\cypher-shell.bat" -a bolt://localhost:7687 -u neo4j -d <你的数据库名> -f "导入脚本.cypher"
& "<DBMS_HOME>\\bin\\cypher-shell.bat" -a bolt://localhost:7687 -u neo4j -d <你的数据库名> -f "导入检查.cypher"
& "<DBMS_HOME>\\bin\\cypher-shell.bat" -a bolt://localhost:7687 -u neo4j -d <你的数据库名> -f "三类查询.cypher"
```
"""


复制脚本 = r"""param(
  [Parameter(Mandatory=$true)]
  [string]$Neo4jImportDir
)

$ErrorActionPreference = "Stop"
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
New-Item -ItemType Directory -Force -Path $Neo4jImportDir | Out-Null
foreach ($name in @("节点表.csv", "关系表.csv", "三元组表.csv")) {
  $target = Join-Path $Neo4jImportDir $name
  if (Test-Path -LiteralPath $target) { throw "目标已存在：$target" }
  Copy-Item -LiteralPath (Join-Path $SourceDir $name) -Destination $target
}
Write-Host "已复制 CSV 到 Neo4j import 目录：$Neo4jImportDir"
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="按 kg_schema.py 生成 Neo4j 导入包")
    parser.add_argument("--graph-dir", type=Path, required=True, help="本次阶段05图谱 CSV 目录")
    parser.add_argument("--output-dir", type=Path, help="默认在阶段06 output/ 下按图谱批次命名")
    parser.add_argument("--neo4j-import-dir", type=Path)
    parser.add_argument("--copy-to-neo4j-import", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not args.graph_dir.is_dir():
        raise FileNotFoundError(f"图谱 CSV 目录不存在：{args.graph_dir}")
    if args.copy_to_neo4j_import and args.neo4j_import_dir is None:
        raise ValueError("复制到 Neo4j 时必须显式指定 --neo4j-import-dir")
    args.output_dir = args.output_dir or 默认输出目录 / args.graph_dir.name
    for filename in ["节点表.csv", "关系表.csv", "三元组表.csv"]:
        if not (args.graph_dir / filename).is_file():
            raise FileNotFoundError(f"缺少图谱输入：{args.graph_dir / filename}")
    args.output_dir.mkdir(parents=True, exist_ok=False)

    for filename in ["节点表.csv", "关系表.csv", "三元组表.csv"]:
        写无BOM_CSV(args.graph_dir / filename, args.output_dir / filename)

    (args.output_dir / "导入脚本.cypher").write_text(生成导入脚本(), encoding="utf-8")
    (args.output_dir / "导入检查.cypher").write_text(导入检查脚本, encoding="utf-8")
    (args.output_dir / "三类查询.cypher").write_text(三类查询脚本, encoding="utf-8")
    (args.output_dir / "Neo4j导入说明.md").write_text(导入说明, encoding="utf-8")
    (args.output_dir / "复制CSV到Neo4j导入目录.ps1").write_text(复制脚本, encoding="utf-8")

    copied_to = ""
    if args.copy_to_neo4j_import:
        args.neo4j_import_dir.mkdir(parents=True, exist_ok=True)
        for filename in ["节点表.csv", "关系表.csv", "三元组表.csv"]:
            target = args.neo4j_import_dir / filename
            if target.exists():
                raise FileExistsError(f"Neo4j import 文件已存在：{target}")
            shutil.copy2(args.output_dir / filename, target)
        copied_to = str(args.neo4j_import_dir)

    print("=" * 72)
    print("Neo4j 导入包生成完成")
    print(f"图谱CSV来源：{args.graph_dir}")
    print(f"导入包目录：{args.output_dir}")
    if copied_to:
        print(f"已复制CSV到Neo4j import目录：{copied_to}")
    print("=" * 72)


if __name__ == "__main__":
    main()
