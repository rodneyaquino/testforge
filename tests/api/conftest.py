# tests/api/conftest.py
# TestForge — API shared fixtures
# WHY: Single source of truth for API hosts keeps tests small and consistent.

import pytest


@pytest.fixture(scope="session")
def hosts():
    return {
        "dummyjson": "https://dummyjson.com",
        "jsonph": "https://jsonplaceholder.typicode.com",
        "httpbin": "https://httpbin.org",
        "pokeapi": "https://pokeapi.co/api/v2",
    }


@pytest.fixture(scope="session")
def default_headers():
    return {"User-Agent": "TestForge/1.0"}
