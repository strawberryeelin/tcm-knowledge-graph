/** 将阶段01的拆分 JSON 导出为人工筛选用 Excel。 */
import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..", "..");
const defaultInputPath = path.join(__dirname, "output", "全部医案_按分隔线拆分.json");
const args = { inputPath: defaultInputPath, outputPath: "", runtimeNodeModules: process.env.ARTIFACT_TOOL_NODE_MODULES || path.join(projectRoot, "node_modules") };
for (let i = 2; i < process.argv.length; i += 1) {
  const key = process.argv[i];
  if (key === "--help" || key === "-h") {
    console.log("用法：node export_split_preview.mjs [--input <拆分.json>] [--output <预览.xlsx>] [--runtime-node-modules <node_modules目录>]");
    process.exit(0);
  }
  const value = process.argv[i + 1];
  if (!value || !["--input", "--output", "--runtime-node-modules"].includes(key)) throw new Error(`无效参数：${key}`);
  if (key === "--input") args.inputPath = path.resolve(value);
  if (key === "--output") args.outputPath = path.resolve(value);
  if (key === "--runtime-node-modules") args.runtimeNodeModules = path.resolve(value);
  i += 1;
}
const inputPath = args.inputPath;
const outputPath = args.outputPath || inputPath.replace(/\.json$/u, ".xlsx");
const outputDir = path.dirname(outputPath);
const inspectPath = `${outputPath}.inspect.ndjson`;
if (outputPath === inputPath || !outputPath.endsWith(".xlsx")) throw new Error("输出必须是不同于输入的 .xlsx 文件");
if (fsSync.existsSync(outputPath) || fsSync.existsSync(inspectPath)) throw new Error(`输出已存在，请使用新批次路径：${outputPath}`);
if (!fsSync.existsSync(args.runtimeNodeModules)) throw new Error("未找到 @oai/artifact-tool 运行时，请设置 ARTIFACT_TOOL_NODE_MODULES");
const requireFromRuntime = createRequire(path.join(args.runtimeNodeModules, "__resolver__.cjs"));
const artifactToolEntry = requireFromRuntime.resolve("@oai/artifact-tool");
const { SpreadsheetFile, Workbook } = await import(pathToFileURL(artifactToolEntry).href);

const raw = await fs.readFile(inputPath, "utf8");
const records = JSON.parse(raw);
if (!Array.isArray(records)) throw new Error("拆分结果必须是 JSON 数组");

const workbook = Workbook.create();
const sheet = workbook.worksheets.add("全部医案");
sheet.showGridLines = false;

const headers = ["序号", "文档名称", "具体医案"];
const rows = records.map((record) => [
  record["序号"],
  record["文档名称"],
  record["具体医案"],
]);

sheet.getRange("A1:C1").values = [headers];

if (rows.length > 0) {
  sheet.getRangeByIndexes(1, 0, rows.length, headers.length).values = rows;
}

const usedRows = rows.length + 1;
const usedRange = sheet.getRangeByIndexes(0, 0, usedRows, headers.length);

sheet.getRange("A1:C1").format = {
  fill: "#1F4E79",
  font: { bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center",
  verticalAlignment: "middle",
};

usedRange.format = {
  font: { name: "Microsoft YaHei", size: 10 },
  verticalAlignment: "top",
  wrapText: true,
};

sheet.getRange("A1:C1").format.font = { name: "Microsoft YaHei", size: 10, bold: true, color: "#FFFFFF" };
sheet.getRangeByIndexes(0, 0, usedRows, headers.length).format.borders = {
  preset: "all",
  style: "thin",
  color: "#D9E2F3",
};

sheet.getRangeByIndexes(1, 0, Math.max(rows.length, 1), 1).format.horizontalAlignment = "center";
sheet.getRangeByIndexes(1, 0, Math.max(rows.length, 1), 1).format.numberFormat = "0";
sheet.getRangeByIndexes(0, 0, usedRows, 1).format.columnWidth = 8;
sheet.getRangeByIndexes(0, 1, usedRows, 1).format.columnWidth = 38;
sheet.getRangeByIndexes(0, 2, usedRows, 1).format.columnWidth = 90;
sheet.getRange("A1:C1").format.rowHeight = 24;
sheet.getRangeByIndexes(1, 0, Math.min(rows.length, 200), 3).format.rowHeight = 96;

const table = sheet.tables.add(`A1:C${usedRows}`, true, "全部医案表");
table.showFilterButton = true;
table.showBandedRows = true;

sheet.freezePanes.freezeRows(1);

await fs.mkdir(outputDir, { recursive: true });
const xlsx = await SpreadsheetFile.exportXlsx(workbook);
await xlsx.save(outputPath);

console.log(`Excel saved: ${outputPath}`);
await fs.rm(inspectPath, { force: true });
process.exit(0);
