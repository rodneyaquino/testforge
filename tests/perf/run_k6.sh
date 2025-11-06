#!/usr/bin/env bash
set -euo pipefail

PERF_DIR=${1:-tests/perf/results}
PERF_JSON="$PERF_DIR/k6-export.json"
PERF_OUT="$PERF_DIR/k6-output.txt"
PERF_STD="$PERF_DIR/k6-stdout.txt"
PERF_WARN="$PERF_DIR/k6-warn.log"
PERF_MARK="$PERF_DIR/.perf_status"

mkdir -p "$PERF_DIR"

# Defaults; allow env overrides from Makefile or CI
: "${K6_LOG_LEVEL:=error}"
: "${K6_PROGRESS:=0}"
: "${K6_VUS:=1}"
: "${K6_DURATION:=60s}"
: "${K6_TARGET:=https://jsonplaceholder.typicode.com/posts/1}"

rc=0
if [[ "${CI:-}" == "true" || -n "${GITHUB_ACTIONS:-}" ]]; then
  # CI/Linux: run k6 directly (avoid 'script' incompat)
  set +e
  k6 run \
    --summary-export="$PERF_JSON" \
    tests/perf/baseline_perf.js \
    2> "$PERF_WARN" | tee "$PERF_STD"
  rc=${PIPESTATUS[0]}
  set -e
else
  # macOS/local: preserve live progress bar via BSD 'script'
  set +e
  script -q /dev/null k6 run \
    --console-output="$PERF_OUT" \
    --summary-export="$PERF_JSON" \
    tests/perf/baseline_perf.js \
    2> "$PERF_WARN" | tee "$PERF_STD"
  rc=${PIPESTATUS[0]}
  set -e
fi

# Mark and exit
if [[ $rc -eq 0 ]]; then
  echo "PASS" > "$PERF_MARK"
  exit 0
else
  echo "FAIL" > "$PERF_MARK"
  exit $rc
fi