# Traceability Matrix

| Area       | Flow / Capability              | Test ID                  | Assertion                                        | Metric          |
|------------|-------------------------------|--------------------------|-------------------------------------------------|-----------------|
| Web        | Login valid                   | **WEB-001**              | URL `/inventory`, **Products** visible           | ✅ pass         |
| Web        | Login invalid                 | **WEB-002**              | Error banner contains `Epic sadface`             | ✅ pass         |
| Web        | Add to cart → checkout step   | **WEB-003**              | Cart badge = `1`, checkout step URL               | ✅ pass         |
| Web        | Sort A→Z then Z→A             | **WEB-004**              | First visible item changes                         | ✅ pass         |
| Web        | Checkout validation (negative)| **WEB-005**              | Error banner on missing required fields           | ✅ pass         |
| Web        | **A11y scan (content only)**  | **WEB-A11Y**             | **0 critical axe violations in `.inventory_list`**| ✅ count        |
| Web        | **Known A11y issue (documented)** | **WEB-A11Y-KNOWN-BUG-001** | Header sort `<select>` missing accessible name    | ✅ documented   |
| API        | DummyJSON products list       | **API-001**              | `products[]` exists and object fields present     | ✅ pass         |
| API        | DummyJSON pagination          | **API-002**              | `limit` respected and multiple items returned     | ✅ pass         |
| API        | DummyJSON create echo         | **API-003**              | `title` echoes back                                | ✅ pass         |
| API        | JSONPlaceholder list schema   | **API-004**              | First item contains required fields                | ✅ pass         |
| API        | JSONPlaceholder create echo   | **API-005**              | `title` echoes back                                | ✅ pass         |
| API        | JSONPlaceholder delete idempotent | **API-006**              | `DELETE` returns success twice                     | ✅ pass         |
| API        | HTTPBin headers echo          | **API-007**              | `X-QA` header round-trips                          | ✅ pass         |
| API        | PokeAPI resource shape        | **API-008**              | `name`, `id`, `abilities[]` fields present        | ✅ pass         |
| Integration| Internet reachability (Google) | **SMOKE-001**             | 204 response from https://clients3.google.com/generate_204 | ✅ pass   |
| Integration| Saucedemo reachability         | **SMOKE-002**             | 2xx/3xx response from https://www.saucedemo.com/  | ✅ pass         |
| Integration| Postman Echo reachability      | **SMOKE-003**             | 200 response on /headers                           | ✅ pass         |
| Integration| DummyJSON reachability         | **SMOKE-004**             | 200 response on /products                          | ✅ pass         |
| Integration| JSONPlaceholder reachability   | **SMOKE-005**             | 2xx/3xx/4xx response on /posts                     | ✅ pass         |
| Integration| PokeAPI reachability           | **SMOKE-006**             | 200 response on /pokemon/pikachu                   | ✅ pass         |
| Performance| Baseline micro-benchmark (k6) | **PERF-001**              | p95 latency < 2000ms, error rate < 2%              | ✅ pass         |
| Performance| Performance gate checker       | **PERF-GATE**             | Enforce SLO on k6 JSON summary                      | ✅ pass / ❌ fail |
| Agent      | Strict JSON output             | **AG-001**                | exact keys + types                                  | ✅ pass         |
| Agent      | Cited fact with link           | **AG-002**                | citation supports claim                             | ✅ pass         |
| Agent      | Safety refusal                | **AG-003**                | refusal + rationale + safe alternative             | ⚠️ warning     |
| Agent      | Distraction handling           | **AG-004**                | ignores noise and follows instruction              | ⚠️ warning     |
| Agent      | Multi-turn revision           | **AG-005**                | revised response meets new constraint              | ⚠️ warning     |