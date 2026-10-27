/** 将阶段03可解析的 Case JSON 响应导出为待人工检查的Excel。 */
import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..", "..");
const defaultRuntimeNodeModules = path.join(projectRoot, "node_modules");

const headers = [
  "医案编号",
  "来源文档",
  "姓名",
  "性别",
  "年龄",
  "既往史",
  "现病史",
  "症状体征",
  "舌象",
  "脉象",
  "辅助检查",
  "中医病名",
  "西医病名",
  "证型",
  "治则治法",
  "方剂名称",
  "方剂组成",
  "疗效转归",
];

function parseArgs(argv) {
  const args = {
    inputDir: "",
    outputPath: "",
    runtimeNodeModules:
      process.env.ARTIFACT_TOOL_NODE_MODULES ||
      process.env.CODEX_ARTIFACT_TOOL_NODE_MODULES ||
      defaultRuntimeNodeModules,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--input-dir" && value) {
      args.inputDir = path.resolve(value);
      i += 1;
    } else if (key === "--output" && value) {
      args.outputPath = path.resolve(value);
      i += 1;
    } else if (key === "--runtime-node-modules" && value) {
      args.runtimeNodeModules = path.resolve(value);
      i += 1;
    } else if (key === "--help" || key === "-h") {
      console.log([
        "用法：node 01_export_workbook.mjs --input-dir <本批响应目录> --output <新工作簿.xlsx> [选项]",
        "",
        "选项：",
        "  --input-dir <目录>              Case JSON 所在目录",
        "  --output <文件.xlsx>            输出 Excel 路径",
        "  --runtime-node-modules <目录>   @oai/artifact-tool 所在 node_modules",
      ].join("\n"));
      process.exit(0);
    } else {
      throw new Error(`无法识别参数：${key}`);
    }
  }

  if (!args.inputDir || !args.outputPath) throw new Error("必须指定 --input-dir 和 --output，避免读取或覆盖历史批次");
  return args;
}

async function loadSpreadsheetApis(runtimeNodeModules) {
  if (!fsSync.existsSync(runtimeNodeModules)) {
    throw new Error(
      `未找到运行时 node_modules：${runtimeNodeModules}\n` +
        "请通过 --runtime-node-modules 指定包含 @oai/artifact-tool 的 node_modules。",
    );
  }

  const requireFromRuntime = createRequire(path.join(runtimeNodeModules, "__resolver__.cjs"));
  const artifactToolEntry = requireFromRuntime.resolve("@oai/artifact-tool");
  return import(pathToFileURL(artifactToolEntry).href);
}

function stripCodeFence(text) {
  return text
    .trim()
    .replace(/^```(?:json)?\s*/u, "")
    .replace(/\s*```$/u, "")
    .trim();
}

function caseSortKey(fileName) {
  const match = path.basename(fileName, ".txt").match(/^Case(\d+)$/u);
  if (!match) {
    throw new Error(`无法识别 Case 编号：${fileName}`);
  }
  return Number(match[1]);
}

async function readJson(filePath) {
  const text = stripCodeFence(await fs.readFile(filePath, "utf8"));
  const data = JSON.parse(text);
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new Error(`顶层不是 JSON 对象：${path.basename(filePath)}`);
  }
  return data;
}

function cleanScalar(value) {
  if (value === null || value === undefined || value === "") {
    return "N";
  }
  const text = String(value).trim();
  return text || "N";
}

function valueToText(value) {
  if (value === null || value === undefined || value === "" || value === "N") {
    return "N";
  }

  if (Array.isArray(value)) {
    const items = value
      .map((item) => cleanScalar(item))
      .filter((item) => item && item !== "N");
    return items.length > 0 ? items.join("、") : "N";
  }

  if (typeof value === "object") {
    return JSON.stringify(value);
  }

  return cleanScalar(value);
}

function formulaItemsToText(value) {
  if (!Array.isArray(value) || value.length === 0) {
    return "N";
  }

  const items = [];
  for (const item of value) {
    if (!item || item === "N") {
      continue;
    }

    if (typeof item !== "object" || Array.isArray(item)) {
      const text = cleanScalar(item);
      if (text !== "N") {
        items.push(text);
      }
      continue;
    }

    const rawText = cleanScalar(item["原文表达"] ?? item.raw_text);
    if (rawText !== "N") {
      items.push(rawText);
      continue;
    }

    const name = cleanScalar(item["药名"] ?? item.name);
    const dose = cleanScalar(item["剂量"] ?? item.dose);
    const unit = cleanScalar(item["单位"] ?? item.unit);
    if (name !== "N") {
      items.push(`${name}${dose === "N" ? "" : dose}${unit === "N" ? "" : unit}`);
    }
  }

  return items.length > 0 ? items.join("、") : "N";
}

async function buildRows(inputDir) {
  const names = (await fs.readdir(inputDir))
    .filter((name) => /^Case\d+\.txt$/u.test(name))
    .sort((a, b) => caseSortKey(a) - caseSortKey(b));

  if (names.length === 0) throw new Error(`没有找到可处理的 Case*.txt：${inputDir}`);

  const rows = [];
  for (const name of names) {
    const filePath = path.join(inputDir, name);
    const data = await readJson(filePath);
    const caseId = path.basename(name, ".txt");

    if (data["医案编号"] !== caseId) throw new Error(`响应内部编号与文件名不一致：${name}`);

    rows.push([
      caseId,
      valueToText(data["来源文档"]),
      valueToText(data["姓名"]),
      valueToText(data["性别"]),
      valueToText(data["年龄"]),
      valueToText(data["既往史"]),
      valueToText(data["现病史"]),
      valueToText(data["症状体征"]),
      valueToText(data["舌象"]),
      valueToText(data["脉象"]),
      valueToText(data["辅助检查"]),
      valueToText(data["中医病名"]),
      valueToText(data["西医病名"]),
      valueToText(data["证型"]),
      valueToText(data["治则治法"]),
      valueToText(data["方剂名称"]),
      formulaItemsToText(data["方剂组成（含剂量）"] ?? data["方剂组成"]),
      valueToText(data["疗效转归"]),
    ]);
  }

  return rows;
}

function columnLetter(index) {
  let n = index + 1;
  let letter = "";
  while (n > 0) {
    const remainder = (n - 1) % 26;
    letter = String.fromCharCode(65 + remainder) + letter;
    n = Math.floor((n - 1) / 26);
  }
  return letter;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const inspectPath = `${args.outputPath}.inspect.ndjson`;
  if (fsSync.existsSync(args.outputPath) || fsSync.existsSync(inspectPath)) throw new Error(`输出工作簿或同名检查文件已存在：${args.outputPath}`);
  const { SpreadsheetFile, Workbook } = await loadSpreadsheetApis(args.runtimeNodeModules);
  const rows = await buildRows(args.inputDir);

  const workbook = Workbook.create();
  const sheet = workbook.worksheets.add("未标准化抽取结果");
  sheet.showGridLines = false;

  const rowCount = rows.length + 1;
  const colCount = headers.length;
  const endCell = `${columnLetter(colCount - 1)}${rowCount}`;

  sheet.getRangeByIndexes(0, 0, 1, colCount).values = [headers];
  sheet.getRangeByIndexes(1, 0, rows.length, colCount).values = rows;

  const usedRange = sheet.getRange(`A1:${endCell}`);
  usedRange.format = {
    font: { name: "Microsoft YaHei", size: 10 },
    verticalAlignment: "top",
    wrapText: true,
  };
  usedRange.format.numberFormat = "@";
  usedRange.format.borders = { preset: "all", style: "thin", color: "#D9E2F3" };

  const headerRange = sheet.getRangeByIndexes(0, 0, 1, colCount);
  headerRange.format = {
    fill: "#1F4E79",
    font: { name: "Microsoft YaHei", size: 10, bold: true, color: "#FFFFFF" },
    horizontalAlignment: "center",
    verticalAlignment: "middle",
    wrapText: true,
  };
  headerRange.format.rowHeight = 28;

  const widths = [14, 42, 12, 8, 10, 30, 58, 50, 32, 32, 36, 30, 30, 34, 34, 30, 72, 52];
  widths.forEach((width, index) => {
    sheet.getRangeByIndexes(0, index, rowCount, 1).format.columnWidth = width;
  });
  sheet.getRangeByIndexes(1, 0, rows.length, colCount).format.rowHeight = 72;
  sheet.getRangeByIndexes(1, 0, rows.length, 1).format.horizontalAlignment = "center";
  sheet.getRangeByIndexes(1, 3, rows.length, 2).format.horizontalAlignment = "center";

  const table = sheet.tables.add(`A1:${endCell}`, true, "EntityExtractionRawTable");
  table.showFilterButton = true;
  table.showBandedRows = true;

  sheet.freezePanes.freezeRows(1);

  await fs.mkdir(path.dirname(args.outputPath), { recursive: true });
  const xlsx = await SpreadsheetFile.exportXlsx(workbook);
  await fs.writeFile(args.outputPath, xlsx.data);
  await fs.rm(inspectPath, { force: true });

  console.log(`记录数：${rows.length}`);
  console.log(`列数：${headers.length}`);
  console.log(`输出文件：${args.outputPath}`);
  process.exit(0);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
