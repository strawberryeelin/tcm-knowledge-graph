// 三类 Cypher 查询烟测

// 查询1：Case001 的方剂-中药链，确认肉桂存在且肉桂心不存在
MATCH (case1:`医案` {`名称`: 'Case001'})-[:`使用方剂`]->(f:`方剂`)-[:`包含中药`]->(h:`中药`)
RETURN case1.`名称` AS 医案,
       collect(DISTINCT f.`名称`) AS 方剂,
       collect(DISTINCT h.`名称`) AS 中药,
       '肉桂' IN collect(DISTINCT h.`名称`) AS 包含肉桂,
       '肉桂心' IN collect(DISTINCT h.`名称`) AS 错误包含肉桂心;

// 查询2：Case010 的方剂-中药链，确认附子/半夏/人参可查，且没有“钱半”实体
MATCH (case10:`医案` {`名称`: 'Case010'})-[:`使用方剂`]->(f:`方剂`)-[:`包含中药`]->(h:`中药`)
WITH case10, f, collect(DISTINCT h.`名称`) AS herbs
RETURN case10.`名称` AS 医案,
       f.`名称` AS 方剂,
       herbs AS 中药,
       all(x IN ['附子','半夏','人参'] WHERE x IN herbs) AS 包含关键中药,
       [x IN herbs WHERE x CONTAINS '钱半'] AS 错误钱半实体;

// 查询3：Case027/Case051 患者拆分是否可区分
MATCH (c:`医案`)-[:`记录患者`]->(p:`患者`)
WHERE c.`名称` IN ['Case027','Case051']
RETURN c.`名称` AS 医案, p.`姓名` AS 姓名, p.`性别` AS 性别, p.`年龄` AS 年龄
ORDER BY 医案;
