# TestForge — Perf and Resilience Plan (Lightweight Micro-Benchmark)

## 🎯 Objective
Validate the responsiveness and reliability of public endpoints under a respectful, controlled load.  
This plan focuses on a **lightweight, ethical benchmark** that verifies latency and error behavior without impacting shared infrastructure.

---

## 🧩 Scope
- **Target:** `https://jsonplaceholder.typicode.com/posts/1`  
  (Public read-only endpoint used for consistent response timing)
- **Load Profile:** 1 virtual user (VU), ~1 request per second, 60 seconds total  
- **Nature of Test:** Read-only GETs — no write or mutation operations  
- **Execution Context:** Local or CI runner via `make test-perf`  

---

## 📊 Service Level Objectives (SLOs)
| Metric | Target | Error Budget | Purpose |
|--------|---------|--------------|----------|
| **p95 Latency** | < 2000 ms | 5% above threshold | Maintain fast response under light load |
| **Error Rate** | < 2% | 0.5% tolerance | Capture transient or network-based issues |
| **Availability** | ≥ 99% | ≤ 1% window | Ensure endpoint reachability |

SLOs are codified as **k6 thresholds**, providing immediate pass/fail signals and long-term metrics for observability.

---

## 🛠 Implementation Overview
1. **Execution**
   - The micro-benchmark runs via `make test-perf`, invoking a k6 script configured for 1 VU over 60 seconds.  
   - Each iteration performs a GET request against the target endpoint.  
   - Test pacing is controlled by a one-second sleep, maintaining approximately one request per second.

2. **Data Export**
   - Run results are captured to `tests/perf/results/k6-summary.json`.  
   - k6 also streams metrics to **InfluxDB** or **Prometheus** for historical storage when configured.
    - example : 
      - For future observability integration, k6 can stream metrics directly to Prometheus using the remote write adapter:
      - `k6 run --out prometheus-remote-write=http://prometheus:9090/api/v1/write baseline_perf.js`
   - These feeds enable trend tracking of latency, success rate, and uptime across multiple runs.

3. **Observability**
   - **Grafana** consumes the metrics from InfluxDB/Prometheus to visualize:
     - p95 latency and error trends  
     - Iteration rate and success distribution  
     - Historical compliance with defined SLOs  
   - Dashboards highlight deviations visually, giving instant insight into system health.

4. **Alerting & Automation**
   - Grafana alert rules monitor threshold breaches (`p95 > 2000 ms` or error rate > 2%).  
   - Alerts post to **Slack** via webhooks, ensuring engineers are notified within seconds.  
   - This pipeline closes the loop from test execution → metric storage → alerting → team visibility.

---

## ⚙️ Operational Notes
- **Abort Rule:** If more than 20% of requests fail within the first 10 iterations, the test halts early.  
- **Respectful Load:** The 1 RPS limit prevents undue stress on public services.  
- **Run Frequency:** Once per CI cycle or daily on schedule for baseline tracking.  
- **Artifacts:** Console logs and JSON summaries are archived to allow performance trend comparison over time.  

---

## ✅ Success Criteria
- p95 latency remains below 2000 ms  
- Error rate stays under 2 percent  
- No alerts triggered in Grafana over three consecutive runs  
- SLO dashboard shows all metrics in green  

---

**Result:**  
A transparent, low-impact performance and resilience signal that validates baseline reliability today  
and provides a clear path forward for richer observability tomorrow. The plan positions TestForge to  
integrate cleanly with Grafana dashboards and Slack alerts in future phases, enabling automated insight  
and proactive monitoring once those integrations are in place.