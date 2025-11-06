# tests/api/test_public_apis.py
"""
TestForge — Public API tests (no keys)

📘 Scope
- DummyJSON: list schema, pagination shape, create echo
- JSONPlaceholder: list schema, create echo, idempotent delete
- HTTPBin: headers round-trip (resilient to upstream 5xx), status edge (via smoke)
- PokeAPI: resource shape spot-check

📎 Conventions
- ✅ Positive, ❌ Negative/edge, 🔎 Contract/schema, 🧯 Resilience
- Each test clearly states WHY, WHAT, and HOW for onboarding clarity.
- All services are public, read-only, and require no API keys.

🐞 Known Issues & Notes
- **BUG-002:** JSONPlaceholder POST may return variable types (public demo quirk).
- **BUG-003:** Occasional render timing in Web sort (UI layer only, not API-related).
- **HTTPBin Intermittency:** Upstream 5xxs are treated as environmental and marked xfail.
- **Policy:** Do not hide flaky endpoints. Track and document them using bug files under `reports/bugs/`.
  (See: `reports/bugs/BUG-002-api-schema-quirk.md` for schema quirk reference.)
"""

import pytest
import requests
from jsonschema import validate


# ---------------------------------------------------------------------
# 🔎 DummyJSON — Product list has expected shape and useful meta fields
# ---------------------------------------------------------------------
def test_api_001_dummyjson_products_list_schema(hosts, default_headers):
    """
    WHY:
      Validate the basic contract of /products for clients that list and paginate.
    WHAT:
      GET /products?limit=5 should return 200 with a 'products' array and common meta fields.
    HOW:
      Assert status, array type, a couple of stable fields on the first item, and presence of meta keys.
    """
    r = requests.get(
        f"{hosts['dummyjson']}/products?limit=5", headers=default_headers, timeout=10
    )
    assert r.status_code == 200, "Expected HTTP 200 from DummyJSON products list"

    body = r.json()
    assert isinstance(body.get("products"), list), "'products' should be an array"

    # Spot-check a couple of stable fields without overfitting to the entire schema
    if body["products"]:
        sample = body["products"][0]
        assert "id" in sample, "Each product should expose an 'id'"
        assert "title" in sample, "Each product should expose a 'title'"

    # Optional meta keys that many clients rely on for pagination
    for k in ("limit", "skip", "total"):
        assert k in body, f"Response should include meta key '{k}'"


# ---------------------------------------------------------------------
# 🔎 DummyJSON — Pagination shape and parameters are honored
# ---------------------------------------------------------------------
def test_api_002_dummyjson_pagination_shape(hosts, default_headers):
    """
    WHY:
      Clients depend on stable pagination knobs to page through lists.
    WHAT:
      GET /products?limit=3&skip=3 should reflect 'limit' and return an array shape for 'products'.
    HOW:
      Assert status, meta echo of 'limit', and type checks.
    """
    r = requests.get(
        f"{hosts['dummyjson']}/products?limit=3&skip=3",
        headers=default_headers,
        timeout=10,
    )
    assert (
        r.status_code == 200
    ), "Expected HTTP 200 from DummyJSON products list with pagination"

    body = r.json()
    assert body.get("limit") == 3, "Server should echo the requested 'limit' value"
    assert isinstance(body.get("products"), list), "'products' should be an array"


# ---------------------------------------------------------------------
# ✅ DummyJSON — Create-style echo returns the posted title
# ---------------------------------------------------------------------
def test_api_003_dummyjson_create_echo(hosts, default_headers):
    """
    WHY:
      Even when writes are mocked, clients often expect simple echo semantics.
    WHAT:
      POST /products/add should return 200/201 and echo the posted 'title'.
    HOW:
      Post a small payload and assert the round-trip on 'title'.
    """
    payload = {"title": "qa-sample", "price": 10}
    r = requests.post(
        f"{hosts['dummyjson']}/products/add",
        json=payload,
        headers=default_headers,
        timeout=10,
    )
    assert r.status_code in (
        200,
        201,
    ), "Expected HTTP 200 or 201 from DummyJSON create echo"

    data = r.json()
    assert (
        data.get("title") == payload["title"]
    ), "Title should round-trip in the response body"


# ---------------------------------------------------------------------
# 🔎 JSONPlaceholder — Posts list conforms to simple contract
# ---------------------------------------------------------------------
def test_api_004_jsonplaceholder_list_schema(hosts, default_headers):
    """
    WHY:
      Basic list endpoints should return a stable array shape for consumer safety.
    WHAT:
      GET /posts returns 200, non-empty list, and a reasonable object shape per item.
    HOW:
      Validate type, non-empty, and spot schema on the first item using jsonschema.
    """
    r = requests.get(f"{hosts['jsonph']}/posts", headers=default_headers, timeout=10)
    assert r.status_code == 200, "Expected HTTP 200 from JSONPlaceholder posts list"

    data = r.json()
    assert (
        isinstance(data, list) and len(data) > 0
    ), "Expected a non-empty list of posts"

    validate(
        instance=data[0],
        schema={"type": "object", "required": ["userId", "id", "title", "body"]},
    )


# ---------------------------------------------------------------------
# ✅ JSONPlaceholder — Create-style echo returns the posted title
# ---------------------------------------------------------------------
def test_api_005_jsonplaceholder_create_echo(hosts, default_headers):
    """
    WHY:
      Simple POST echoes are common in demo APIs and help verify client write paths.
    WHAT:
      POST /posts should return 200/201 and include the posted title.
    HOW:
      Post a minimal payload and assert the 'title' field.
    """
    payload = {"title": "qa", "body": "test", "userId": 1}
    r = requests.post(
        f"{hosts['jsonph']}/posts", json=payload, headers=default_headers, timeout=10
    )
    assert r.status_code in (
        200,
        201,
    ), "Expected HTTP 200 or 201 from JSONPlaceholder create"

    body = r.json()
    assert body.get("title") == "qa", "Title should be echoed back"
    # Note: See BUG-002-api-schema-quirk.md — JSONPlaceholder may return variable types.


# ---------------------------------------------------------------------
# ✅ JSONPlaceholder — DELETE behaves idempotently for clients that retry
# ---------------------------------------------------------------------
def test_api_006_jsonplaceholder_delete_idempotent(hosts, default_headers):
    """
    WHY:
      Real clients retry deletes; idempotency prevents accidental failures on duplicates.
    WHAT:
      DELETE /posts/1 should return a success code even if called twice.
    HOW:
      Perform two deletes back-to-back and accept 200 or 204 each time.
    """
    url = f"{hosts['jsonph']}/posts/1"

    r1 = requests.delete(url, headers=default_headers, timeout=10)
    assert r1.status_code in (200, 204), "First DELETE should succeed with 200 or 204"

    r2 = requests.delete(url, headers=default_headers, timeout=10)
    assert r2.status_code in (
        200,
        204,
    ), "Second DELETE should also succeed (idempotent pattern)"


# ---------------------------------------------------------------------
# 🧯 Postman Echo — Header round-trip (mark xfail on upstream 5xx blips)
# ---------------------------------------------------------------------
def test_api_007_postmanecho_headers_roundtrip(default_headers):
    """
    WHY:
      Many systems rely on custom headers. This confirms round-trip behavior
      against a well-known, stable public echo service.
    WHAT:
      GET /headers should return 200 and include our 'X-QA' header value.
    HOW:
      Send a request with 'X-QA: testforge', accept canonicalization of header case.
      If the service returns a 5xx or network issue, treat as environmental xfail
      rather than failing CI.
    """

    url = "https://postman-echo.com/headers"
    hdrs = dict(default_headers, **{"X-QA": "testforge"})

    try:
        r = requests.get(url, headers=hdrs, timeout=10)
    except requests.RequestException as e:
        pytest.xfail(f"Network error calling {url}: {e}")

    if r.status_code >= 500:
        pytest.xfail(
            f"Postman Echo returned {r.status_code}; treating as environmental flake"
        )

    assert r.status_code == 200, "Expected HTTP 200 from Postman Echo /headers"

    headers = r.json().get("headers", {}) or {}
    headers_lc = {k.lower(): v for k, v in headers.items()}
    assert (
        headers_lc.get("x-qa") == "testforge"
    ), "Custom header 'X-QA' should round-trip with value 'testforge'"


# ---------------------------------------------------------------------
# 🔎 PokeAPI — Resource shape spot-check (stable keys only)
# ---------------------------------------------------------------------
def test_api_008_pokeapi_resource_shape(hosts, default_headers):
    """
    WHY:
      Basic resource endpoints should expose stable identity and core fields.
    WHAT:
      GET /pokemon/pikachu returns 200 with name='pikachu', numeric id, and an abilities array.
    HOW:
      Spot-check a few keys without overfitting to the full schema.
    """
    r = requests.get(
        f"{hosts['pokeapi']}/pokemon/pikachu", headers=default_headers, timeout=10
    )
    assert r.status_code == 200, "Expected HTTP 200 from PokeAPI resource endpoint"

    data = r.json()
    assert data.get("name") == "pikachu", "Resource 'name' should be 'pikachu'"
    assert isinstance(data.get("abilities"), list), "'abilities' should be an array"
    assert isinstance(data.get("id"), int), "'id' should be a number"
