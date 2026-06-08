# Quality — Python

## Test structure

```txt
tests/
├── conftest.py          ← shared fixtures, custom markers registration
├── unit/                ← fast, isolated, no real I/O
└── integration/         ← hits real infra (DB, external APIs)
```

```toml
# pyproject.toml — document custom markers
[tool.pytest.ini_options]
markers = [
    "slow: marks tests as slow",
    "integration: requires external services",
]
```

## Parametrize & property-based

```python
import pytest
from hypothesis import given, strategies as st

@pytest.mark.parametrize("value, expected", [
    (1, True),
    (0, False),
    (-1, True),
])
def test_is_nonzero(value: int, expected: bool) -> None:
    assert bool(value) == expected

@given(st.lists(st.integers()))
def test_sort_preserves_length(items: list[int]) -> None:
    assert len(sorted(items)) == len(items)
```

Use `parametrize` for variant inputs. Use `hypothesis` for invariants.

## Fakes for Ports

```python
class InMemoryOrderRepository:
    def __init__(self) -> None:
        self._store: dict[int, Order] = {}

    def save(self, order: Order) -> None:
        self._store[order.id] = order

    def find_by_id(self, order_id: int) -> Order | None:
        return self._store.get(order_id)
```

Prefer fakes over `unittest.mock` — they test real behavior, not mock expectations.

## Input validation at boundaries

```python
from pydantic import BaseModel, field_validator

class UserInput(BaseModel):
    username: str
    email: str

    @field_validator("username")
    @classmethod
    def no_special_chars(cls, v: str) -> str:
        if any(c in v for c in "<>;&|"):
            raise ValueError("Invalid characters")
        return v

payload = UserInput.model_validate(request_data)  # fail fast at boundary
```

Validate at every I/O boundary: HTTP, files, DB reads, LLM responses.

## Secret management

```python
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("API_KEY") or ""
```

- **Dev:** `.env` (git-ignored) + `python-dotenv`
- **Prod:** AWS Secrets Manager, HashiCorp Vault, or equivalent
- **Audit:** `trufflehog` or `ggshield` before open-sourcing

## Security rules

- `secrets` module for tokens/keys; `bcrypt` or `argon2` for passwords. Never `random`.
- Parameterized queries for SQL — never f-strings into SQL.
- `subprocess` with list args, never `shell=True`.
- Sanitize all LLM-generated content before execution or storage.

## Structured logging

```python
import logging, json
from contextvars import ContextVar

request_id: ContextVar[str] = ContextVar("request_id", default="")

class JSONFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        return json.dumps({
            "level": record.levelname,
            "message": record.getMessage(),
            "request_id": request_id.get(),
        })
```

Always include correlation IDs for distributed tracing.

## Success criteria

- Tests are modular and independent — no shared mutable state.
- Business invariants covered by property-based tests.
- Fakes preferred over mocks for Port implementations.
- All I/O boundaries schema-validated with Pydantic.
- No secrets in source code or logs.
- Coverage 80–90% on business logic.
