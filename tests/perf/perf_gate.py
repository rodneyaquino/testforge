# tests/perf/perf_gate.py
# TestForge — Performance Gate (micro)
# WHY: Turn raw k6 output into a pass/fail quality signal.
# WHAT: Read p95 latency + error rate from k6 JSON; compare to SLOs.
# HOW: Exit code == 0 means PASS; 1 means FAIL (CI-friendly).

import json, sys, os

# 1) Find the summary JSON (default path; override allowed via arg)
summary_path = sys.argv[1] if len(sys.argv) > 1 else "tests/perf/results/k6-summary.json"
if not os.path.exists(summary_path):
    print(f"⚠  No k6 summary found at: {summary_path}")
    sys.exit(0)  # Non-blocking if the file doesn't exist (adjust to your preference)

# 2) Load the JSON
with open(summary_path, "r") as f:
    data = json.load(f)

# 3) Extract metrics with safe defaults if missing
metrics = data.get("metrics", {})
p95 = metrics.get("http_req_duration", {}).get("p(95)")
err_rate = metrics.get("http_req_failed", {}).get("rate")

# 4) Thresholds (sync with PERF_PLAN one-pager; allow env overrides)
P95_MS = float(os.environ.get("K6_P95_MS", 2000))   # default 2000ms
ERR_RATE = float(os.environ.get("K6_ERR_RATE", 0.02))  # default 2%

def fmt_ms(x): return f"{x:.0f} ms" if isinstance(x, (int, float)) else str(x)
def fmt_rate(x): return f"{x:.2%}" if isinstance(x, (int, float)) else str(x)

print("— Perf Summary —")
print(f"p95 latency : {fmt_ms(p95)}  (SLO < {P95_MS:.0f} ms)")
print(f"error rate  : {fmt_rate(err_rate)} (SLO < {ERR_RATE:.2%})")

p95_ok = (p95 is not None) and (p95 <= P95_MS)
err_ok = (err_rate is not None) and (err_rate <= ERR_RATE)

print(f"Gate p95: {'PASS' if p95_ok else 'FAIL'}")
print(f"Gate err: {'PASS' if err_ok else 'FAIL'}")

sys.exit(0 if (p95_ok and err_ok) else 1)