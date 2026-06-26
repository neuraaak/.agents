# Quality — FastAPI (delta)

> **Delta** on `references/languages/python/quality.md`. Load the Python base
> file first; this file only adds or overrides what changes when FastAPI is used.

## Detection

`fastapi` in `dependencies`, or an ASGI entrypoint (`uvicorn`/`hypercorn`) in the
project.

## Test stack delta

FastAPI's `TestClient` is built on **httpx** — keep `httpx` in the dev group (the
config skill's FastAPI delta already adds it). Use `pytest` (base) as the runner.

```python
# tests/conftest.py — shared client fixture
import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client() -> TestClient:
    return TestClient(app)
```

## Endpoint test pattern

```python
def test_create_user_returns_201(client: TestClient) -> None:
    response = client.post("/users", json={"email": "ada@example.com"})
    assert response.status_code == 201
    assert response.json()["email"] == "ada@example.com"

def test_invalid_email_returns_422(client: TestClient) -> None:
    response = client.post("/users", json={"email": "not-an-email"})
    assert response.status_code == 422  # Pydantic validation, automatic
```

- Pydantic request models give you **422 on bad input for free** — assert it,
  don't re-validate manually.
- Assert on status code **and** body shape.

## Dependency overrides — fakes over mocks

FastAPI's `app.dependency_overrides` is the idiomatic seam. Inject the
in-memory fake (base rule: prefer fakes over `unittest.mock`):

```python
from app.deps import get_repository

def test_uses_fake_repo(client: TestClient) -> None:
    app.dependency_overrides[get_repository] = lambda: InMemoryOrderRepository()
    try:
        response = client.get("/orders/1")
        assert response.status_code == 404
    finally:
        app.dependency_overrides.clear()  # never leak across tests
```

## Async tests

For async endpoints or coroutine units, use `httpx.AsyncClient` with the ASGI
transport (needs `pytest-asyncio` in dev):

```python
import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_async_endpoint() -> None:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/health")
    assert response.status_code == 200
```

## Security delta

- Validation is automatic via Pydantic request models — keep the boundary in the
  model, not in the handler body.
- Auth: `OAuth2PasswordBearer` + a verified-token dependency; never trust a raw
  header. Test both the 200 (valid token) and 401 (missing/invalid) paths.
- Hash passwords with `bcrypt`/`argon2` (base rule) — never store plaintext.

## Success criteria (FastAPI)

- `TestClient` (httpx) via a shared `client` fixture; `pytest` runner.
- Bad input asserted as automatic Pydantic 422 — no manual re-validation.
- Dependencies swapped via `app.dependency_overrides` with in-memory fakes; cleared after each test.
- Async paths tested with `httpx.AsyncClient` + `ASGITransport`.
- Auth dependency tested on both 200 and 401 paths; passwords hashed.
