#!/usr/bin/env node
// Writes `totdSchedule` ("yyyy-mm-dd" -> talk key) into docs/data.json.
//
// The app, both home-screen widgets, the Siri shortcut and the ledger
// calendar all look the day's Talk of the Day up here instead of each
// recomputing it, so they cannot disagree after talks are added (the pick
// depends on the talk COUNT — see ENGINEERING_NOTES.md, Talk of the Day).
//
// Run it after ANY change to the talk list (e.g. a new conference):
//   node scripts/generate-totd-schedule.js
// Days before today + 7 are frozen (kept exactly as published, so a day
// people have already seen — or a device that cached the old list — never
// changes); days from then on are recomputed with the current list. The
// first run starts from today. Also stamps generatedAt so apps re-fetch.
//
// Options: --days N (how far ahead to publish, default 540)
//          --file PATH (a data.json other than docs/data.json, for testing)
const fs = require('fs');
const path = require('path');
const { makeAlgorithmPicker, talkKey } = require('../functions/totd');

const argFile = process.argv.indexOf('--file');
const file = argFile > -1 ? path.resolve(process.argv[argFile + 1]) : path.join(__dirname, '..', 'docs', 'data.json');
const raw = fs.readFileSync(file, 'utf8');
const data = JSON.parse(raw);

const argDays = process.argv.indexOf('--days');
const horizon = argDays > -1 ? parseInt(process.argv[argDays + 1], 10) : 540;

const pad = (n) => String(n).padStart(2, '0');
const iso = (dt) => `${dt.getUTCFullYear()}-${pad(dt.getUTCMonth() + 1)}-${pad(dt.getUTCDate())}`;
const now = new Date();
const today = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
const addDays = (dt, n) => new Date(dt.getTime() + n * 86400000);

const existing = data.totdSchedule || {};
const hadSchedule = Object.keys(existing).length > 0;
const cutoff = iso(addDays(today, hadSchedule ? 7 : 0));
const keepFrom = iso(addDays(today, -35));

const schedule = {};
for (const [date, key] of Object.entries(existing)) {
  if (date >= keepFrom && date < cutoff) schedule[date] = key;
}

const pick = makeAlgorithmPicker(data);
const start = new Date(cutoff + 'T00:00:00Z');
for (let i = 0; i <= horizon; i++) {
  const dt = addDays(start, i);
  const talk = pick(dt.getUTCFullYear(), dt.getUTCMonth() + 1, dt.getUTCDate());
  if (talk) schedule[iso(dt)] = talkKey(talk); // null = General Conference day, no entry
}

data.totdSchedule = Object.fromEntries(Object.entries(schedule).sort(([a], [b]) => (a < b ? -1 : 1)));
data.generatedAt = new Date().toISOString();
fs.writeFileSync(file, JSON.stringify(data) + (raw.endsWith('\n') ? '\n' : ''));
console.log(`totdSchedule: ${Object.keys(data.totdSchedule).length} days, ${Object.keys(data.totdSchedule)[0]} .. ${Object.keys(data.totdSchedule).pop()} (frozen before ${cutoff})`);
