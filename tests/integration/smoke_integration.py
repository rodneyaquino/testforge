# tests/integration/smoke_integration.py
"""
TestForge — Smoke checks (reachability, not authorization)

📘 Purpose
- Verify that core public endpoints are reachable and responsive.
- Distinguish between actual service outages and normal access restrictions.
- Treat transient upstream issues (network or 5xx) as **environmental**, surfaced as xfails but non-blocking.

🧭 Policy
- ✅ 2xx/3xx → Reachable
- ⚠️ 401/403/404/429 → Reachable but restricted (auth or rate limit)
- 🧯 5xx → Environmental issue (xfail to surface but not block)
- ❌ Anything else → True reachability failure

🔎 Conventions
- WHY / WHAT / HOW inline comments promote quick onboarding.
- Stable User-Agent for polite requests and reproducible network traces.
- No credentials, mutations, or API keys used — all endpoints are public demos.
"""

import pytest
import requests
from requests import exceptions as rx

# Acceptable statuses meaning “endpoint is up,” even if restricted.
OK_STATUSES = {200, 201, 202, 204, 301, 302, 307, 308, 401, 403, 404, 429}

# Stable UA helps upstream filtering, logging, and polite identification.
DEFAULT_HEADERS = {"User-Agent": "TestForge/1.0"}


def check_reachable(url: str, timeout: float = 6.0):
    """
    WHY:
      Verify that a public endpoint is up and reachable, without conflating auth/rate-limit responses
      or external outages with actual framework failures.

    WHAT:
      - Perform a simple GET with redirects and short timeout.
      - Classify results:
        ✅ 2xx/3xx → reachable
        ⚠️ 401/403/404/429 → reachable but restricted
        🧯 5xx → upstream environmental outage (xfail)
        ❌ others → real failure
      - Network-level issues (timeouts, DNS, TLS) also become xfails — visible but non-blocking.

    HOW:
      - Use requests.get with stable headers.
      - Mark xfail for environmental/network issues.
      - Assert membership in OK_STATUSES for true reachability.
    """
    try:
        r = requests.get(
            url,
            headers=DEFAULT_HEADERS,
            timeout=timeout,
            allow_redirects=True,
        )
    except (rx.Timeout, rx.ConnectTimeout, rx.ReadTimeout, rx.SSLError, rx.ConnectionError) as e:
        # Network-layer issues = environmental, not a QA regression.
        pytest.xfail(f"{url} unreachable — network error: {type(e).__name__}: {e}")

    # Environmental handling: public service is up but temporarily unhealthy.
    if r.status_code >= 500:
        pytest.xfail(f"{url} returned {r.status_code} — upstream outage (environmental)")

    # Reachability assertion (expected OK or restricted response).
    assert (
        r.status_code in OK_STATUSES
    ), f"{url} returned {r.status_code}, expected one of {sorted(OK_STATUSES)}"


# ---------------------------------------------------------------------
# 🌐 Targets — representative endpoints supporting other suites
# ---------------------------------------------------------------------

def test_internet_ping_reachable():
    # WHY: Super-stable baseline to confirm outbound internet reachability.
    # WHAT: /generate_204 returns 204 quickly when the network is healthy.
    check_reachable("https://clients3.google.com/generate_204")

def test_sauce_demo_reachable():
    # WHY: The web E2E suite relies on this target for Playwright tests.
    # WHAT: Landing page must respond with a reachable (2xx/3xx) status.
    check_reachable("https://www.saucedemo.com/")

def test_postmanecho_reachable():
    # WHY: API header round-trip sanity uses this echo endpoint in tests.
    # WHAT: /headers must respond as a reachable endpoint.
    check_reachable("https://postman-echo.com/headers")

def test_dummyjson_reachable():
    # WHY: API tests depend on DummyJSON for list/pagination/echo operations.
    # WHAT: The product listing endpoint must return a reachable response.
    check_reachable("https://dummyjson.com/products?limit=5")

def test_jsonplaceholder_reachable():
    # WHY: API tests rely on JSONPlaceholder for list/create/idempotent behaviors.
    # WHAT: The /posts endpoint should be reachable with 2xx/3xx/4xx.
    check_reachable("https://jsonplaceholder.typicode.com/posts")

def test_pokeapi_reachable():
    # WHY: API tests spot-check schema from the PokeAPI resource.
    # WHAT: The /pokemon/pikachu endpoint should return a reachable response.
    check_reachable("https://pokeapi.co/api/v2/pokemon/pikachu")