# 🐛 BUG-003 — API: DummyJSON mutation persistence failure

**Title:** API: DummyJSON PUT/PATCH mutations return success but do not persist data changes

**Environment:**
- **OS:** macOS 15.4.1 (Sequoia)
- **API Under Test:** https://dummyjson.com/users
- **Test Tools:** curl 8.7.1, jq 1.7.1

---

## Steps to Reproduce
1. Send a PUT request to update user 2's `lastName`:
```bash
   curl -s -X PUT "https://dummyjson.com/users/2" \
     -H "Content-Type: application/json" \
     -d '{"lastName": "OwaisUpdated"}' | jq '.lastName'
```
2. Observe the response shows the updated value: `"OwaisUpdated"`
3. Immediately fetch the same user to verify persistence:
```bash
   curl -s "https://dummyjson.com/users/2" | jq '.lastName'
```
4. Compare the `lastName` value from both responses

---

## Expected Behavior
- When a PUT/PATCH request receives a 200 OK response with the updated data, the change should persist in the backend.
- Subsequent GET requests to the same resource should return the updated value.
- Standard CRUD workflow:
```
  PUT /users/2 → {"lastName": "OwaisUpdated"} → 200 OK
  GET /users/2 → {"lastName": "OwaisUpdated"} ✓
```

---

## Actual Behavior
- The PUT request returns 200 OK with the updated `lastName` in the response body, indicating success.
- However, the subsequent GET request returns the original, unchanged value.
- The mutation was **simulated only** and never persisted to the backend.

Example output:
```bash
# Step 1: PUT request response
"OwaisUpdated"

# Step 2: GET request response (immediately after)
"Williams"  # ← Original value, unchanged
```

---

## Evidence
| Source | Result |
|--------|--------|
| **PUT Request Response** | `"lastName": "OwaisUpdated"` — appears successful |
| **GET Request Response** | `"lastName": "Williams"` — original value unchanged |
| **API Documentation** | States mutations are "simulated" but returns 200 OK responses |
| **Multiple Endpoints Tested** | Same behavior on `/users`, `/products`, `/posts` — affects all mutation operations |

**Test commands:**
```bash
# Update attempt
curl -s -X PUT "https://dummyjson.com/users/2" \
  -H "Content-Type: application/json" \
  -d '{"lastName": "OwaisUpdated"}' | jq '.lastName'

# Verification
curl -s "https://dummyjson.com/users/2" | jq '.lastName'
```

**Output comparison:**
```
PUT response:  "OwaisUpdated"
GET response:  "Williams"
```

**Actual Test | Terminal Output**
```
% curl -s -X PUT "https://dummyjson.com/users/2" \
     -H "Content-Type: application/json" \
     -d '{"lastName": "OwaisUpdated"}' | jq '.lastName'
"OwaisUpdated"
% curl -s "https://dummyjson.com/users/2" | jq '.lastName'
"Williams"

```

---

## Severity & Priority
| Field | Value | Rationale |
|-------|-------|-----------|
| **Severity** | **High** | Breaks CRUD test automation workflows; misleading success responses cause false positives in test suites |
| **Priority** | **Medium** | Documented limitation but should be clearly indicated in API responses (e.g., 202 Accepted, or warning header) |

---

## Suspected Cause
- DummyJSON is a mock API that simulates mutations without actual database persistence.
- The API returns optimistic responses (200 OK with updated data) but never commits changes to storage.
- This is likely intentional design to prevent state pollution in a shared public API, but the HTTP semantics are misleading.
- No indication in response headers or status codes that the mutation was simulated only.

---

## Fix Hypothesis
**Option 1: Change HTTP status codes for simulated operations**
```http
HTTP/1.1 202 Accepted
X-Mutation-Simulated: true
Content-Type: application/json

{
  "lastName": "OwaisUpdated",
  "message": "This is a simulated response. Data is not persisted."
}
```

**Option 2: Add response header indicating simulation**
```http
HTTP/1.1 200 OK
X-DummyJSON-Simulated: true
Warning: 299 - "Mutation simulated only, not persisted"
```

**Option 3: Document clearly and provide persistent test endpoints**
- Create a `/sandbox/users/2` namespace where mutations actually persist for testing
- Reserve `/users/2` for read-only or simulated operations

---

## Retest Plan
1. Send PUT request to `/users/2` with updated data
2. Check response status code and headers for simulation indicators
3. Confirm:
   - Response includes `X-Mutation-Simulated: true` header OR
   - Status code is 202 Accepted instead of 200 OK OR
   - Documentation clearly states mutations are not persisted
4. Verify GET request returns either:
   - Original unchanged data (with clear expectation) OR
   - Updated data if using persistent sandbox endpoint

---

**Status:** ⏳ Open — API design decision needed