#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");

const VERSION = "2026.3.17";
const BACKUP_DIR = ".mobile-chat-backup";

console.log("╔════════════════════════════════════════════════════════╗");
console.log("║  OpenClaw Mobile Chat Installer v" + VERSION + "             ║");
console.log("║  Hands-Free · Bluetooth · Phone Capabilities          ║");
console.log("╚════════════════════════════════════════════════════════╝");
console.log("");

const SCRIPT_DIR = __dirname;
const FILES_DIR = path.join(SCRIPT_DIR, "files");

function detectOpenClaw(arg) {
  if (arg && fs.existsSync(arg) && fs.statSync(arg).isDirectory()) return path.resolve(arg);
  const home = process.env.HOME || process.env.USERPROFILE || "";
  const candidates = [path.join(home, "openclaw"), path.resolve("openclaw"), path.resolve(".")];
  for (const c of candidates) {
    if (fs.existsSync(path.join(c, "package.json")) && fs.existsSync(path.join(c, "dist"))) return path.resolve(c);
  }
  return null;
}

const OPENCLAW_ROOT = detectOpenClaw(process.argv[2]);

if (!OPENCLAW_ROOT) {
  console.log("ERROR: Could not find OpenClaw installation.");
  console.log("Usage: node install-node.cjs /path/to/openclaw");
  process.exit(1);
}

if (!fs.existsSync(FILES_DIR)) {
  console.log("ERROR: files/ directory not found next to this script.");
  process.exit(1);
}

console.log("OpenClaw root: " + OPENCLAW_ROOT);
console.log("");

const BACKUP_PATH = path.join(OPENCLAW_ROOT, BACKUP_DIR);
const INSTALLED_LIST = path.join(BACKUP_PATH, "installed-files.txt");
const BACKED_UP_LIST = path.join(BACKUP_PATH, "backed-up-files.txt");

fs.mkdirSync(BACKUP_PATH, { recursive: true });

function walkDir(dir, base) {
  base = base || dir;
  let results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) results = results.concat(walkDir(full, base));
    else results.push(path.relative(base, full));
  }
  return results;
}

const files = walkDir(FILES_DIR).sort();
const backedUp = [];
const installed = [];

console.log("[1/2] Backing up files that will be overwritten...");

for (const rel of files) {
  const target = path.join(OPENCLAW_ROOT, rel);
  if (fs.existsSync(target)) {
    const backupTarget = path.join(BACKUP_PATH, rel);
    fs.mkdirSync(path.dirname(backupTarget), { recursive: true });
    fs.copyFileSync(target, backupTarget);
    backedUp.push(rel);
  }
}

fs.writeFileSync(BACKED_UP_LIST, backedUp.join("\n") + (backedUp.length ? "\n" : ""));
console.log("  Backed up " + backedUp.length + " existing files to " + BACKUP_DIR + "/");
console.log("");

console.log("[2/2] Installing Mobile Chat files...");

for (const rel of files) {
  const src = path.join(FILES_DIR, rel);
  const target = path.join(OPENCLAW_ROOT, rel);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(src, target);
  installed.push(rel);
}

fs.writeFileSync(INSTALLED_LIST, installed.join("\n") + "\n");
const newFiles = installed.length - backedUp.length;

console.log("  Installed " + installed.length + " files (" + newFiles + " new, " + backedUp.length + " updated)");
console.log("");

console.log("════════════════════════════════════════════════════════");
console.log("  INSTALL COMPLETE");
console.log("════════════════════════════════════════════════════════");
console.log("");
console.log("  Files installed: " + installed.length);
console.log("  Backed up:       " + backedUp.length);
console.log("  New files:       " + newFiles);
console.log("");
console.log("  Access Mobile Chat at:");
console.log("    https://your-openclaw-domain/mobile-chat.html");
console.log("");
console.log("  Quick Start:");
console.log("    1. Pair phone to car via Bluetooth");
console.log("    2. Open Mobile Chat page in Chrome on your phone");
console.log("    3. Tap Drive or press Play on car radio");
console.log("    4. Speak naturally - 2 second pause sends your message");
console.log("");
