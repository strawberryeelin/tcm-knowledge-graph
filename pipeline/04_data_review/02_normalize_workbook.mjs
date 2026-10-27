/** 输出需人工复核。 */
import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..", "..");
const defaultRuntimeNodeModules = path.join(projectRoot, "node_modules");

const baseHeaders = [
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
const outputHeaders = [...baseHeaders, "标准化备注"];
const outputIndex = new Map(baseHeaders.map((header, index) => [header, index]));

const symptomMap = new Map([
  ["纳差", "食欲不振"],
  ["食少", "食欲不振"],
  ["胃口差", "食欲不振"],
  ["食欲差", "食欲不振"],
  ["纳呆", "食欲不振"],
  ["胃脘胀", "胃脘胀满"],
  ["胃脘胀满不舒", "胃脘胀满"],
  ["胃胀", "胃脘胀满"],
  ["腹部胀满", "腹胀"],
]);

const tcmDiseaseMap = new Map([
  ["胃痛", "胃脘痛"],
]);

const pulseMap = new Map([
  ["脉细弦", "脉弦细"],
  ["细弦脉", "脉弦细"],
  ["弦细脉", "脉弦细"],
]);

const herbReplacements = [
  ["麸炒白术", "白术"],
  ["制附片", "制附子"],
  ["熟附子", "制附子"],
  ["鲜生姜", "生姜"],
  ["炙甘草", "甘草"],
  ["炙甘∴", "甘草"],
  ["姜半夏", "半夏"],
  ["法半夏", "半夏"],
  ["清半夏", "半夏"],
  ["制半夏", "半夏"],
  ["炒半夏", "半夏"],
  ["炒白术", "白术"],
  ["炒薏苡仁", "薏苡仁"],
  ["炒枣仁", "酸枣仁"],
  ["炒山药", "山药"],
  ["全蝎粉", "全蝎"],
  ["白芍药", "白芍"],
  ["大白芍", "白芍"],
  ["云茯苓", "茯苓"],
  ["广陈皮", "陈皮"],
  ["全当归", "当归"],
  ["煨姜", "生姜"],
  ["红枣", "大枣"],
  ["炮姜", "干姜"],
  ["淡干姜", "干姜"],
  ["千姜", "干姜"],
  ["于姜", "干姜"],
  ["生栀子", "栀子"],
  ["栀仁", "栀子"],
  ["白蔻仁", "白豆蔻"],
  ["白寇仁", "白豆蔻"],
  ["瓜蒌仁", "瓜蒌"],
  ["生龙骨", "龙骨"],
  ["元明粉", "芒硝"],
  ["玄明粉", "芒硝"],
  ["生晒参", "人参"],
  ["红参", "人参"],
  ["银花", "金银花"],
  ["麦门冬", "麦冬"],
  ["辽细辛", "细辛"],
  ["川厚朴", "厚朴"],
  ["川连", "黄连"],
  ["生大黄", "大黄"],
  ["酒大黄", "大黄"],
  ["江枳实", "枳实"],
  ["炒枳壳", "枳壳"],
  ["炒枳实", "枳实"],
  ["附片", "附子"],
];

const herbRegexReplacements = [
  [/生地(?!黄)/gu, "生地黄", "生地"],
  [/熟地(?!黄)/gu, "熟地黄", "熟地"],
];

function parseArgs(argv) {
  const args = {
    inputPath: "",
    outputPath: "",
    runtimeNodeModules:
      process.env.ARTIFACT_TOOL_NODE_MODULES ||
      process.env.CODEX_ARTIFACT_TOOL_NODE_MODULES ||
      defaultRuntimeNodeModules,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--input" && value) {
      args.inputPath = path.resolve(value);
      args.outputPath = deriveOutputPath(args.inputPath);
      i += 1;
    } else if (key === "--output" && value) {
      args.outputPath = path.resolve(value);
      i += 1;
    } else if (key === "--runtime-node-modules" && value) {
      args.runtimeNodeModules = path.resolve(value);
      i += 1;
    } else if (key === "--help" || key === "-h") {
      console.log([
        "用法：node 02_normalize_workbook.mjs --input <本批未标准化.xlsx> [--output <新文件.xlsx>] [选项]",
        "",
        "选项：",
        "  --input <文件.xlsx>             未标准化输入 Excel",
        "  --output <文件.xlsx>            标准化输出 Excel",
        "  --runtime-node-modules <目录>   @oai/artifact-tool 所在 node_modules",
      ].join("\n"));
      process.exit(0);
    } else {
      throw new Error(`无法识别参数：${key}`);
    }
  }

  if (!args.inputPath) throw new Error("必须指定 --input，避免读取历史批次");
  return args;
}

function deriveOutputPath(inputPath) {
  const parsed = path.parse(inputPath);
  const name = parsed.name.includes("_未标准化")
    ? parsed.name.replace("_未标准化", "_标准化")
    : `${parsed.name}_标准化`;
  return path.join(parsed.dir, `${name}${parsed.ext || ".xlsx"}`);
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

function normalizeText(value) {
  if (value === null || value === undefined || value === "") {
    return "N";
  }
  return String(value).trim() || "N";
}

function addChange(changes, field, from, to) {
  if (!from || !to || from === to) {
    return;
  }
  changes.add(`${field}：${from}->${to}`);
}

function normalizeDelimited(value, field, normalizer, changes) {
  const text = normalizeText(value);
  if (text === "N") {
    return text;
  }

  const parts = text.split("、").map((part) => part.trim()).filter(Boolean);
  if (parts.length === 0) {
    return text;
  }

  const normalized = parts.map((part) => {
    const next = normalizer(part);
    addChange(changes, field, part, next);
    return next;
  });
  return normalized.join("、");
}

function normalizeSymptom(term) {
  return symptomMap.get(term) ?? term;
}

function normalizePulse(term) {
  if (pulseMap.has(term)) {
    return pulseMap.get(term);
  }
  if (term.startsWith("脉象") && term.length > 2) {
    return `脉${term.slice(2)}`;
  }
  return term;
}

function normalizeTcmDisease(term) {
  return tcmDiseaseMap.get(term) ?? term;
}

function normalizeSyndrome(term) {
  if (term.endsWith("之症") && term.length > 2) {
    return term.slice(0, -2);
  }
  if (term.endsWith("证") && term.length > 1) {
    return term.slice(0, -1);
  }
  return term;
}

function normalizeFormulaName(term) {
  const match = term.match(/^(.+?)(加减方?|化裁)$/u);
  return match ? match[1] : term;
}

function normalizeHerbs(value, changes) {
  let text = normalizeText(value);
  if (text === "N") {
    return text;
  }

  for (const [from, to] of herbReplacements) {
    if (!text.includes(from)) {
      continue;
    }
    text = text.split(from).join(to);
    addChange(changes, "方剂组成", from, to);
  }

  for (const [regex, to, label] of herbRegexReplacements) {
    if (!regex.test(text)) {
      regex.lastIndex = 0;
      continue;
    }
    regex.lastIndex = 0;
    text = text.replace(regex, to);
    addChange(changes, "方剂组成", label, to);
  }

  return text;
}

function normalizeRow(row, headerIndex) {
  const changes = new Set();
  const next = baseHeaders.map((header) => normalizeText(row[headerIndex.get(header)]));

  next[outputIndex.get("症状体征")] = normalizeDelimited(
    next[outputIndex.get("症状体征")],
    "症状体征",
    normalizeSymptom,
    changes,
  );
  next[outputIndex.get("脉象")] = normalizeDelimited(
    next[outputIndex.get("脉象")],
    "脉象",
    normalizePulse,
    changes,
  );
  next[outputIndex.get("中医病名")] = normalizeDelimited(
    next[outputIndex.get("中医病名")],
    "中医病名",
    normalizeTcmDisease,
    changes,
  );
  next[outputIndex.get("证型")] = normalizeDelimited(
    next[outputIndex.get("证型")],
    "证型",
    normalizeSyndrome,
    changes,
  );
  next[outputIndex.get("方剂名称")] = normalizeDelimited(
    next[outputIndex.get("方剂名称")],
    "方剂名称",
    normalizeFormulaName,
    changes,
  );
  next[outputIndex.get("方剂组成")] = normalizeHerbs(next[outputIndex.get("方剂组成")], changes);

  next.push(changes.size > 0 ? [...changes].join("；") : "N");
  return next;
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
  if (args.outputPath === args.inputPath || fsSync.existsSync(args.outputPath) || fsSync.existsSync(inspectPath)) {
    throw new Error(`标准化输出已存在或与输入相同：${args.outputPath}`);
  }
  const { FileBlob, SpreadsheetFile, Workbook } = await loadSpreadsheetApis(args.runtimeNodeModules);

  const source = await SpreadsheetFile.importXlsx(await FileBlob.load(args.inputPath));
  const sourceSheet = source.worksheets.getItemAt(0);
  const values = sourceSheet.getUsedRange().values;
  const headers = values[0].map((value) => normalizeText(value));
  const headerIndex = new Map(headers.map((header, index) => [header, index]));

  const missingHeaders = baseHeaders.filter((header) => !headerIndex.has(header));
  if (missingHeaders.length > 0) {
    throw new Error(`输入表缺少列：${missingHeaders.join("、")}`);
  }

  const dataRows = values.slice(1);
  const rows = dataRows.map((row) => normalizeRow(row, headerIndex));
  const changedRows = rows.filter((row) => row[row.length - 1] !== "N").length;

  const workbook = Workbook.create();
  const sheet = workbook.worksheets.add("标准化抽取结果");
  sheet.showGridLines = false;

  const rowCount = rows.length + 1;
  const colCount = outputHeaders.length;
  const endCell = `${columnLetter(colCount - 1)}${rowCount}`;

  sheet.getRangeByIndexes(0, 0, 1, colCount).values = [outputHeaders];
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

  const widths = [14, 42, 12, 8, 10, 30, 58, 50, 32, 32, 36, 30, 30, 34, 34, 30, 72, 52, 82];
  widths.forEach((width, index) => {
    sheet.getRangeByIndexes(0, index, rowCount, 1).format.columnWidth = width;
  });
  sheet.getRangeByIndexes(1, 0, rows.length, colCount).format.rowHeight = 84;
  sheet.getRangeByIndexes(1, 0, rows.length, 1).format.horizontalAlignment = "center";
  sheet.getRangeByIndexes(1, 3, rows.length, 2).format.horizontalAlignment = "center";

  const table = sheet.tables.add(`A1:${endCell}`, true, "EntityExtractionStandardizedTable");
  table.showFilterButton = true;
  table.showBandedRows = true;

  sheet.freezePanes.freezeRows(1);

  await fs.mkdir(path.dirname(args.outputPath), { recursive: true });
  const xlsx = await SpreadsheetFile.exportXlsx(workbook);
  await fs.writeFile(args.outputPath, xlsx.data);
  await fs.rm(inspectPath, { force: true });

  console.log(`输入文件：${args.inputPath}`);
  console.log(`输出文件：${args.outputPath}`);
  console.log(`记录数：${rows.length}`);
  console.log(`列数：${colCount}`);
  console.log(`发生标准化变更的记录数：${changedRows}`);
  process.exit(0);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
