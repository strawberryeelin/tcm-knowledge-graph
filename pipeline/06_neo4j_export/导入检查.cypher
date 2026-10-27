// Neo4j 导入检查

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
RETURN n.`节点类型` AS 节点类型, n.`名称` AS 名称, n.`节点ID` AS 节点ID
ORDER BY 节点类型, 名称
LIMIT 50;

// 4. 当前标准化表没有剂量，导入后不应出现非空剂量/单位
MATCH ()-[r]->()
WHERE coalesce(r.`剂量`, '') <> '' OR coalesce(r.`单位`, '') <> ''
RETURN count(r) AS 非空剂量单位关系数, collect({关系类型: type(r), 关系ID: r.`关系ID`, 剂量: r.`剂量`, 单位: r.`单位`})[0..20] AS 示例;

// 5. 重点异常实体不应作为节点或三元组实体存在
MATCH (n:`实体`)
WHERE n.`名称` IN ['肉桂心','半夏钱半','附子钱半','制附子钱半','人参钱半','干姜七分','干姜一錢','口疮之病','渗留中道','渗流中道']
RETURN n.`节点类型` AS 节点类型, n.`名称` AS 名称, n.`节点ID` AS 节点ID;
