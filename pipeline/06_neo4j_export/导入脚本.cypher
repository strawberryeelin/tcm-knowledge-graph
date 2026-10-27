// Neo4j 导入脚本：按 kg_schema.py 生成
// 运行前：把本导入包中的 节点表.csv、关系表.csv 复制到当前 DBMS 的 import 目录。
// 设计原则：CSV 可保留“剂量、单位”列；导入时只有非空值才会写入关系属性。

CREATE CONSTRAINT `实体节点ID唯一` IF NOT EXISTS
FOR (n:`实体`) REQUIRE n.`节点ID` IS UNIQUE;

CREATE INDEX `实体节点类型名称索引` IF NOT EXISTS
FOR (n:`实体`) ON (n.`节点类型`, n.`名称`);

CALL db.awaitIndexes();

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '医案'
MERGE (n:`实体`:`医案` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '医案' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '患者'
MERGE (n:`实体`:`患者` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '患者' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '症状体征'
MERGE (n:`实体`:`症状体征` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '症状体征' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '舌象'
MERGE (n:`实体`:`舌象` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '舌象' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '脉象'
MERGE (n:`实体`:`脉象` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '脉象' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '辅助检查'
MERGE (n:`实体`:`辅助检查` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '辅助检查' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '中医病名'
MERGE (n:`实体`:`中医病名` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '中医病名' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '西医病名'
MERGE (n:`实体`:`西医病名` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '西医病名' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '证型'
MERGE (n:`实体`:`证型` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '证型' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '治则治法'
MERGE (n:`实体`:`治则治法` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '治则治法' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '方剂'
MERGE (n:`实体`:`方剂` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '方剂' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '中药'
MERGE (n:`实体`:`中药` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '中药' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///节点表.csv' AS row
WITH row
WHERE row.`节点类型` = '疗效转归'
MERGE (n:`实体`:`疗效转归` {`节点ID`: row.`节点ID`})
SET n.`节点类型` = CASE WHEN trim(coalesce(row.`节点类型`, '')) <> '' THEN row.`节点类型` ELSE n.`节点类型` END,
    n.`名称` = CASE WHEN trim(coalesce(row.`名称`, '')) <> '' THEN row.`名称` ELSE n.`名称` END,
    n.`规范名称` = CASE WHEN trim(coalesce(row.`规范名称`, '')) <> '' THEN row.`规范名称` ELSE n.`规范名称` END,
    n.`医案编号` = CASE WHEN trim(coalesce(row.`医案编号`, '')) <> '' THEN row.`医案编号` ELSE n.`医案编号` END,
    n.`来源文档` = CASE WHEN trim(coalesce(row.`来源文档`, '')) <> '' THEN row.`来源文档` ELSE n.`来源文档` END,
    n.`姓名` = CASE WHEN trim(coalesce(row.`姓名`, '')) <> '' THEN row.`姓名` ELSE n.`姓名` END,
    n.`性别` = CASE WHEN trim(coalesce(row.`性别`, '')) <> '' THEN row.`性别` ELSE n.`性别` END,
    n.`年龄` = CASE WHEN trim(coalesce(row.`年龄`, '')) <> '' THEN row.`年龄` ELSE n.`年龄` END,
    n.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE n.`来源医案编号` END,
    n.`既往史` = CASE WHEN trim(coalesce(row.`既往史`, '')) <> '' THEN row.`既往史` ELSE n.`既往史` END,
    n.`现病史` = CASE WHEN trim(coalesce(row.`现病史`, '')) <> '' THEN row.`现病史` ELSE n.`现病史` END,
    n.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE n.`原文表达` END
RETURN '疗效转归' AS 节点类型, count(n) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '记录患者'
  AND row.`终点节点类型` = '患者'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`患者` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`记录患者` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-记录患者->患者' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '具有症状体征'
  AND row.`终点节点类型` = '症状体征'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`症状体征` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`具有症状体征` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-具有症状体征->症状体征' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '具有舌象'
  AND row.`终点节点类型` = '舌象'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`舌象` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`具有舌象` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-具有舌象->舌象' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '具有脉象'
  AND row.`终点节点类型` = '脉象'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`脉象` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`具有脉象` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-具有脉象->脉象' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '包含辅助检查'
  AND row.`终点节点类型` = '辅助检查'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`辅助检查` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`包含辅助检查` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-包含辅助检查->辅助检查' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '中医诊断为'
  AND row.`终点节点类型` = '中医病名'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`中医病名` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`中医诊断为` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-中医诊断为->中医病名' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '西医诊断为'
  AND row.`终点节点类型` = '西医病名'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`西医病名` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`西医诊断为` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-西医诊断为->西医病名' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '辨证为'
  AND row.`终点节点类型` = '证型'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`证型` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`辨证为` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-辨证为->证型' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '采用治法'
  AND row.`终点节点类型` = '治则治法'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`治则治法` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`采用治法` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-采用治法->治则治法' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '使用方剂'
  AND row.`终点节点类型` = '方剂'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`方剂` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`使用方剂` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-使用方剂->方剂' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '方剂'
  AND row.`关系类型` = '包含中药'
  AND row.`终点节点类型` = '中药'
MATCH (s:`实体`:`方剂` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`中药` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`包含中药` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END,
    r.`剂量` = CASE WHEN trim(coalesce(row.`剂量`, '')) <> '' THEN row.`剂量` ELSE r.`剂量` END,
    r.`单位` = CASE WHEN trim(coalesce(row.`单位`, '')) <> '' THEN row.`单位` ELSE r.`单位` END
RETURN '方剂-包含中药->中药' AS 关系模式, count(r) AS 导入数量;

LOAD CSV WITH HEADERS FROM 'file:///关系表.csv' AS row
WITH row
WHERE row.`起点节点类型` = '医案'
  AND row.`关系类型` = '转归为'
  AND row.`终点节点类型` = '疗效转归'
MATCH (s:`实体`:`医案` {`节点ID`: row.`起点节点ID`})
MATCH (t:`实体`:`疗效转归` {`节点ID`: row.`终点节点ID`})
MERGE (s)-[r:`转归为` {`关系ID`: row.`关系ID`}]->(t)
SET r.`来源医案编号` = CASE WHEN trim(coalesce(row.`来源医案编号`, '')) <> '' THEN row.`来源医案编号` ELSE r.`来源医案编号` END,
    r.`原文术语` = CASE WHEN trim(coalesce(row.`原文术语`, '')) <> '' THEN row.`原文术语` ELSE r.`原文术语` END,
    r.`原文表达` = CASE WHEN trim(coalesce(row.`原文表达`, '')) <> '' THEN row.`原文表达` ELSE r.`原文表达` END
RETURN '医案-转归为->疗效转归' AS 关系模式, count(r) AS 导入数量;
