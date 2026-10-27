# Neo4j 导入说明

## 关于“剂量、单位”

CSV 表头和导入脚本保留 `剂量`、`单位`，因为当前 `kg_schema.py` 的关系表字段包含它们，且 `方剂-包含中药->中药` 关系属性模式允许它们。

本轮标准化表的方剂组成已经是纯中药名，没有剂量来源。因此导入脚本采用“非空才写入”的逻辑：当前导入后不会生成非空 `剂量`、`单位` 属性；以后如果数据恢复剂量，也只会写到 `包含中药` 关系上。

## 推荐执行顺序

1. 把本目录下 `节点表.csv`、`关系表.csv` 复制到 Neo4j DBMS 的 `import` 目录。
2. 启动数据库。
3. 在 Neo4j Browser 中切换到目标数据库，依次执行：
   - `导入脚本.cypher`
   - `导入检查.cypher`
   - `三类查询.cypher`

如果用 `cypher-shell`，示例：

```powershell
& "<DBMS_HOME>\bin\cypher-shell.bat" -a bolt://localhost:7687 -u neo4j -p 12345678 -d <你的数据库名> -f "导入脚本.cypher"
& "<DBMS_HOME>\bin\cypher-shell.bat" -a bolt://localhost:7687 -u neo4j -p 12345678 -d <你的数据库名> -f "导入检查.cypher"
& "<DBMS_HOME>\bin\cypher-shell.bat" -a bolt://localhost:7687 -u neo4j -p 12345678 -d <你的数据库名> -f "三类查询.cypher"
```
