// Server-side port of the app's Talk of the Day pick (talkForDate, cyclePick
// and CURATED_HOLIDAYS in docs/index.html). It must stay identical to the
// app's version — if that algorithm changes, change this too.
//
// Takes plain calendar dates (year, month 1-12, day). The app seeds from the
// device's local midnight, which for time zones west of UTC is this same day
// number; devices east of UTC land one day earlier, so this matches what
// U.S. users saw.

function splitmix32(seed) {
  const h = (seed + 0x9e3779b9) >>> 0;
  let z = h;
  z = Math.imul(z ^ (z >>> 16), 0x21f0aaad) >>> 0;
  z = Math.imul(z ^ (z >>> 15), 0x735a2d97) >>> 0;
  z = (z ^ (z >>> 15)) >>> 0;
  return z >>> 0;
}

function seededShuffledIndices(count, seed) {
  const idx = Array.from({ length: count }, (_, i) => i);
  let state = seed >>> 0;
  for (let i = count - 1; i > 0; i--) {
    state = splitmix32(state);
    const j = state % (i + 1);
    [idx[i], idx[j]] = [idx[j], idx[i]];
  }
  return idx;
}

// Returns [month 1-12, day] of Easter Sunday.
function easterSunday(year) {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  return [Math.floor((h + l - 7 * m + 114) / 31), ((h + l - 7 * m + 114) % 31) + 1];
}

// weekday: 0=Sunday..6=Saturday; n: 1 = first occurrence in the month.
const nthWeekday = (weekday, n) => (y, m, d, dow) => dow === weekday && Math.floor((d - 1) / 7) + 1 === n;
const fixed = (day) => (y, m, d) => d === day;

// Same order as CURATED_HOLIDAYS in docs/index.html: [topic, month, matcher].
const HOLIDAYS = [
  ['hope', 1, fixed(1)],
  ['love', 2, fixed(14)],
  ['relief-society', 3, fixed(17)],
  ['easter', null, (y, m, d) => { const [em, ed] = easterSunday(y); return m === em && d === ed; }],
  ['restoration', 4, fixed(6)],
  ['motherhood', 5, nthWeekday(0, 2)],
  ['priesthood', 5, fixed(15)],
  ['fatherhood', 6, nthWeekday(0, 3)],
  ['freedom', 7, fixed(4)],
  ['pioneers', 7, fixed(24)],
  ['gratitude', 11, nthWeekday(4, 4)],
  ['christmas', 12, fixed(25)],
];

// Port of isConferenceDay() in docs/index.html — keep in sync. General
// Conference is the first Sunday of April and of October plus the Saturday
// before it (which can land on the last day of March or September). The app
// shows no Talk of the Day on those days: a card asks "Are you participating
// in General Conference today?" instead.
function isConferenceDay(y, m, d) {
  const date = new Date(Date.UTC(y, m - 1, d));
  const dow = date.getUTCDay();
  if (dow !== 0 && dow !== 6) return false;
  const sunday = dow === 0 ? date : new Date(Date.UTC(y, m - 1, d + 1));
  const month = sunday.getUTCMonth() + 1;
  return (month === 4 || month === 10) && sunday.getUTCDate() <= 7;
}

const talkKey = (t) => `${t[2]}|${t[3]}|${t[4]}`;

// data is the parsed data.json. Returns (year, month, day) => talk tuple, or
// null on a General Conference day.
function makeTotdPicker(data) {
  const sorted = [...data.talks].sort((a, b) => {
    const ka = talkKey(a), kb = talkKey(b);
    return ka < kb ? -1 : ka > kb ? 1 : 0;
  });
  const orders = {};
  return (y, m, d) => {
    if (!sorted.length) return null;
    if (isConferenceDay(y, m, d)) return null;
    const utc = Date.UTC(y, m - 1, d);
    const dow = new Date(utc).getUTCDay();
    for (const [topic, month, matches] of HOLIDAYS) {
      if ((month === null || month === m) && matches(y, m, d, dow)) {
        const eligible = sorted.filter((t) => (data.topicLookup[talkKey(t)] || []).includes(topic));
        if (eligible.length) return eligible[splitmix32(y ^ 0x5a5a5a5a) % eligible.length];
        break;
      }
    }
    const dayNumber = Math.floor(utc / 86400000);
    const cycle = Math.floor(dayNumber / sorted.length);
    const order = orders[cycle] || (orders[cycle] = seededShuffledIndices(sorted.length, splitmix32(cycle)));
    return sorted[order[dayNumber % sorted.length]];
  };
}

module.exports = { makeTotdPicker, talkKey, isConferenceDay };
