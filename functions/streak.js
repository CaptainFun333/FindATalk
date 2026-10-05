// Streak math for the ledger's admin tools — a port of
// recomputeStreakFromActiveDays() in docs/index.html. If the app's version
// ever changes how a run is counted, change this to match.

const DAY_RE = /^\d{4}-\d{2}-\d{2}$/;

// A real calendar day in the app's "yyyy-mm-dd" form (rejects 2026-02-31).
function isDay(s) {
  if (typeof s !== 'string' || !DAY_RE.test(s)) return false;
  const d = new Date(s + 'T00:00:00Z');
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s;
}

function prevDay(day) {
  const d = new Date(day + 'T00:00:00Z');
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

// Counts the consecutive run ending at the last active day. A bridged
// (forgiven) day keeps the run unbroken but isn't itself counted.
function recomputeStreak(activeDays, priorLongest, bridgedDays) {
  const days = [...new Set((activeDays || []).filter(isDay))].sort();
  const bridged = [...new Set((bridgedDays || []).filter(isDay))].sort();
  const longest = priorLongest | 0;
  if (!days.length) return { count: 0, longest, lastDate: null };
  const daySet = new Set(days);
  const bridgeSet = new Set(bridged);
  const lastDate = days[days.length - 1];
  let count = 0;
  let cursor = lastDate;
  while (daySet.has(cursor) || bridgeSet.has(cursor)) {
    if (daySet.has(cursor)) count++;
    cursor = prevDay(cursor);
  }
  return { count, longest: Math.max(longest, count), lastDate };
}

module.exports = { isDay, prevDay, recomputeStreak };
