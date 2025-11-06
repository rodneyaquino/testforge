# TestForge - Test Strategy

## Scope
- **Web UI (Playwright)**: login (valid and invalid), cart plus checkout step, sort behavior, accessibility scan with axe-core.
- **Public APIs (pytest + requests + jsonschema)**: DummyJSON (list, pagination, create echo), JSONPlaceholder (list, create, idempotent delete), HTTPBin (headers and status edge cases), PokeAPI (resource shape).
- **Agentic AI**: evaluation prompts covering strict JSON extraction, citation fidelity, safety safeguards, instruction following, and multi-turn revisions.
- **Performance**: safe, low-impact micro-benchmark with k6 (1 VU, ~1 RPS, 60 seconds duration).

## Risks

- **UI Risks:**  
  Asynchronous UI updates can introduce intermittent test flakiness if tests do not account for dynamic content loading.  
  Selectors based on CSS classes or page structure may be brittle over time, requiring robust stable locators and fallback mechanisms.

- **API Risks:**  
  The reliance on public demo APIs exposes tests to upstream changes and schema inconsistencies beyond control.  
  Network instability or transient failures can cause nondeterministic test results; retry logic and defensive assertions help mitigate but not eliminate this risk.

- **Agent Evaluation Risks:**  
  Automated agent responses are susceptible to hallucinations, incorrect adherence to strict JSON schema, and poor citation fidelity.  
  Multi-turn interactions and ambiguous prompts increase complexity, leading to occasional failures or warnings in evaluation metrics.  
  Safety refusals must be carefully validated to ensure ethical compliance without false positives.

- **Performance Risks:**  
  Load testing against public APIs must maintain conservative request rates to avoid trigger throttling or service disruptions.  
  Environmental variability (network latency, service throttling) adds noise to performance metrics, requiring careful baseline and threshold definition.  
  Failures on performance gates (e.g., p95 latency breaches) require clear escalation and retest protocols.

## Test Types
- Functional: happy path flows and negative/validation scenarios.
- Regression: stable locators with explicit assertions to reduce flakiness.
- Accessibility: axe-core zero critical violations enforced on core content.
- Safety: ethical refusals enforced with rationale and alternative suggestions.
- Performance: latency and error rate thresholds based on k6 metrics.
- Observability and Metrics: pass/fail outcomes, invocation durations, a11y violation counts, agent rubric scores, and performance p95 latency.

## Data and Environments
- Public demo targets only; no private secrets or keys required.
- **Setup and Teardown**
  - Web: each test runs in a fresh browser context and page; teardown is automatic.
  - API: tests against stateless, non-persistent endpoints; idempotent deletes verified; no explicit teardown.
  - Performance: read-only GET requests only; no state mutations.
  - Agent: manual scoring based on transcripts and screenshots; no teardown needed.
- Idempotent operations enforced to ensure repeatable, side-effect-free tests.

## Entry and Exit Criteria
- **Entry:** Smoke tests must pass and all target endpoints are reachable.
- **Exit:**
  - Web: all critical flows pass, and inventory page has zero critical a11y violations.
  - API: contract and schema validations pass; expected behavior on edge/negative tests.
  - Agent: minimum 80% pass rate on the manual evaluation rubric.
  - Performance: p95 latency under 2000 ms and error rate under 2%.
  - No open Critical bug reports blocking release.

## Release Gates
- Block release on any critical UI failure, critical accessibility violation, API contract break, or performance threshold breach.
- Agent evaluations require manual confirmation with rubric score ≥ 80% and all major issues resolved.

## Tooling and Conventions
- **Web:** Playwright (TypeScript); stable role and placeholder locators; URL and visible text assertions; axe-core for accessibility scanning.
- **API:** pytest framework using requests library; JSON Schema for contract validation.
- **Performance:** k6 load testing with p95 latency and error rate thresholds enforced programmatically.
- **Orchestration:** unified Makefile entrypoint; Playwright HTML reports; API JUnit and text reports; perf JSON output; all artifacts retained for auditability.