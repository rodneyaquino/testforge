// ======================================================================
// ⚡ TestForge - k6 Micro-Benchmark (RD2, quiet & concise)
// ----------------------------------------------------------------------
// WHY:
//   Sanity-check latency/availability without stressing public APIs.
// WHAT (updated):
//   • 1 Virtual User (VU)
//   • ~0.66–0.7 RPS (sleep 1.5s)
//   • 20-second duration (≈13 requests)
//   • Target: https://httpbin.org/delay/1 (1 s server-side delay)
//   • SLOs: p95 < 2000 ms, error rate < 2 %
//
// HOW:
//   • Thresholds enforce latency & reliability SLOs.
//   • `check()` validates HTTP 200 on each response.
//   • `handleSummary()` prints a single concise line to stdout.
//   • Run k6 with `--quiet` to suppress progress spam.
// ======================================================================

import http from 'k6/http';
import { check, sleep } from 'k6';

// ----------------------------------------------------------------------
// 🌍 Env knobs (safe defaults; override via K6_* env vars if needed)
// ----------------------------------------------------------------------
const TARGET       = __ENV.K6_TARGET       || 'https://jsonplaceholder.typicode.com/posts/1';
const DURATION     = __ENV.K6_DURATION     || '60s';   // 60 seconds
const VUS          = Number(__ENV.K6_VUS   || 1);      // 1 VU
const TIMEOUT_MS   = Number(__ENV.K6_TIMEOUT_MS || 4000);
const SLEEP_S      = Number(__ENV.K6_SLEEP_S     || 1);     // ~1 RPS pacing
const P95_MS       = Number(__ENV.K6_P95_MS     || 2000);   // p95 < 2000 ms
const ERR_RATE_MAX = Number(__ENV.K6_ERR_RATE   || 0.02);   // errors < 2%

// ----------------------------------------------------------------------
// 🧩 k6 Options
// ----------------------------------------------------------------------
export const options = {
  discardResponseBodies: true,
  vus: VUS,
  duration: DURATION,
  thresholds: {
    http_req_duration: [`p(95)<${P95_MS}`],
    http_req_failed:   [`rate<${ERR_RATE_MAX}`],
  },
};

// ----------------------------------------------------------------------
// 🚀 Main VU Function
// ----------------------------------------------------------------------
export default function () {
  const res = http.get(TARGET, { timeout: `${TIMEOUT_MS}ms` });
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(SLEEP_S); // pacing to keep things gentle
}

// ----------------------------------------------------------------------
// 🧾 Custom end-of-test summary
// - When present, k6 will NOT print its default summary.
// - We'll output a single concise line to stdout and a JSON to file.
// ----------------------------------------------------------------------
export function handleSummary(data) {
  const p95 = data?.metrics?.http_req_duration?.values?.['p(95)'];
  const err = data?.metrics?.http_req_failed?.values?.rate;

  const line = [
    'Perf summary:',
    `p95=${(typeof p95 === 'number' ? `${p95.toFixed(0)}ms` : String(p95))}`,
    `errors=${(typeof err === 'number' ? `${(err * 100).toFixed(2)}%` : String(err))}`,
    `(SLO: p95<${P95_MS}ms, err<${(ERR_RATE_MAX * 100).toFixed(0)}%)`
  ].join(' ');

  return {
    stdout: `${line}\n`,
    'tests/perf/results/k6-summary.json': JSON.stringify(data, null, 2),
  };
}

// ----------------------------------------------------------------------
// 🧠 Flow summary:
//   • k6 launches 1 VU for 20 s.
//   • Each iteration hits TARGET once, waits 1.5 s.
//   • Run with --quiet to hide progress spam.
//   • Only a single line prints at the end (via handleSummary).
//   • Full JSON is saved to tests/perf/results/k6-summary.json.
// ----------------------------------------------------------------------