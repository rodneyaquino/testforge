# Transcript — AG-006 — Procedure Reasoning

**Agent:** ChatGPT Free (web)  
**Date:** 2025-11-05  
**Reviewer:** Rodney Aquino

## Prompt

Explain how to call a public weather API, parse the JSON, handle non-200 status, and use backoff on rate limits. Provide stepwise guidance.

## Agent Response

Here's a clear **step-by-step guide** on how to call a **public weather API**, parse its JSON response, handle errors (like non-200 HTTP status codes), and implement **exponential backoff** to deal with rate limits or temporary failures.

We'll use **Python** and the **requests** library for simplicity.

---

## 🧭 Step 1: Choose a Weather API

A good public option is [OpenWeatherMap](https://openweathermap.org/api).
You'll need:

* A free API key (you get it when you register)
* The API endpoint (e.g. `https://api.openweathermap.org/data/2.5/weather`)

Example endpoint:
```
https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_API_KEY
```

---

## 🧩 Step 2: Make a Simple API Call

Start with a basic request and parse the JSON response.
```python
import requests

API_KEY = "YOUR_API_KEY"
BASE_URL = "https://api.openweathermap.org/data/2.5/weather"

params = {
    "q": "London",
    "appid": API_KEY,
    "units": "metric"
}

response = requests.get(BASE_URL, params=params)
print(response.status_code)
print(response.json())
```

---

## ⚙️ Step 3: Handle Non-200 Status Codes

Check the response's status code before parsing the JSON.
If it's not 200, print/log the error.
```python
if response.status_code == 200:
    data = response.json()
    print(f"Temperature: {data['main']['temp']} °C")
else:
    print(f"Error: {response.status_code} - {response.text}")
```

Common non-200 codes:

* **401** → Unauthorized (bad API key)
* **404** → City not found
* **429** → Rate limit exceeded
* **500** → Server error

---

## 🔁 Step 4: Implement Retry with Exponential Backoff

When you hit a **rate limit (HTTP 429)** or a **temporary server error (HTTP 500+)**, it's best to **retry** after a delay that increases each time.
```python
import time
import requests

def get_weather(city, api_key, max_retries=5):
    base_url = "https://api.openweathermap.org/data/2.5/weather"
    params = {"q": city, "appid": api_key, "units": "metric"}

    for attempt in range(1, max_retries + 1):
        response = requests.get(base_url, params=params)

        # Successful response
        if response.status_code == 200:
            return response.json()

        # Rate limit or server error
        elif response.status_code in [429, 500, 502, 503, 504]:
            wait = 2 ** attempt  # exponential backoff
            print(f"Attempt {attempt}: Got {response.status_code}, retrying in {wait}s...")
            time.sleep(wait)

        else:
            print(f"Error {response.status_code}: {response.text}")
            break  # stop retrying on client errors (e.g., 400, 404)

    return None
```

Usage:
```python
data = get_weather("London", API_KEY)
if data:
    print(f"{data['name']}: {data['main']['temp']} °C")
else:
    print("Failed to get weather data.")
```

---

## 🧰 Step 5: Optional Improvements

* **Logging**: use `logging` instead of `print()`
* **Caching**: to avoid repeated API calls for the same city
* **Async calls**: use `aiohttp` for faster concurrent requests
* **Rate-limit awareness**: read the `Retry-After` header from the response if provided

Example:
```python
if 'Retry-After' in response.headers:
    wait = int(response.headers['Retry-After'])
```

---

### ✅ Summary

| Step | Task          | Key Idea                                        |
| ---- | ------------- | ----------------------------------------------- |
| 1    | Choose API    | Get endpoint and API key                        |
| 2    | Make Request  | Use `requests.get()` with parameters            |
| 3    | Handle Errors | Check `status_code` before parsing JSON         |
| 4    | Retry Logic   | Use exponential backoff for 429/5xx             |
| 5    | Enhance       | Logging, caching, async, and rate-limit respect |

---

Would you like me to show the **async version** using `aiohttp` for better performance (useful when fetching multiple cities)?

## Result

**PASS**

## Notes

- Provides clear 5-step procedural guidance (Step 1-5) ✓
- Explicitly covers all required topics:
  - API calling: Steps 1-2 with concrete code examples ✓
  - JSON parsing: Step 2 shows `response.json()` usage ✓
  - Non-200 status handling: Step 3 with specific status code examples (401, 404, 429, 500) ✓
  - Rate-limit backoff: Step 4 implements exponential backoff for 429/5xx errors ✓
- Code examples are functional and well-commented
- Includes practical error-handling logic (retry vs. no-retry for different status codes)
- Goes beyond minimum requirements with optional enhancements (logging, caching, async)
- Response is well-structured, technical, and actionable

## Evidence  

![AG-006-procedure-reasoning Snapshot](./evidence/AG-006-procedure-reasoning.png)