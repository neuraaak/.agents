# Quality — Django (delta)

> **Delta** on `references/languages/python/quality.md`. Load the Python base
> file first; this file only adds or overrides what changes when Django is used.

## Detection

`django` in `dependencies`, or a `manage.py` / `DJANGO_SETTINGS_MODULE` present
in the project.

## Test stack delta

Django tests run with **pytest-django** (not bare pytest). The plugin wires
`DJANGO_SETTINGS_MODULE` and the test database automatically.

```toml
# pyproject.toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings.local"
```

```python
# tests/conftest.py
import pytest

@pytest.fixture
def api_client():
    from rest_framework.test import APIClient  # DRF projects only
    return APIClient()
```

- Use `from rest_framework.test import APIClient` for DRF endpoints; use
  Django's built-in `django.test.Client` for plain HTML/form views.

## Database tests — `@pytest.mark.django_db`

Django's test runner creates a real test DB. Mark tests that need it — never
mock the ORM.

```python
import pytest
from myapp.models import Order

@pytest.mark.django_db
def test_create_order_persists():
    order = Order.objects.create(status="pending")
    assert Order.objects.filter(status="pending").count() == 1
```

- Never mock `QuerySet` or `Manager` methods — use the real test DB.
- `@pytest.mark.django_db(transaction=True)` for tests involving `commit`.

## Object factories — factory-boy over fixtures

Use `factory-boy` to build ORM objects; avoid hand-rolled `setUp` data.

```python
# tests/factories.py
import factory
from myapp.models import Order, User

class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User
    username = factory.Sequence(lambda n: f"user{n}")
    email = factory.LazyAttribute(lambda obj: f"{obj.username}@example.com")

class OrderFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Order
    user = factory.SubFactory(UserFactory)
    status = "pending"
```

```python
@pytest.mark.django_db
def test_order_belongs_to_user():
    order = OrderFactory()
    assert order.user is not None
```

## View / endpoint test pattern

```python
@pytest.mark.django_db
def test_order_list_returns_200(client):  # Django test Client
    UserFactory()
    response = client.get("/api/orders/")
    assert response.status_code == 200

@pytest.mark.django_db
def test_unauthenticated_returns_401(api_client):  # DRF APIClient
    response = api_client.get("/api/orders/")
    assert response.status_code == 401
```

## Settings override

For tests that need a different setting (e.g. disabling email backends), use
Django's `@override_settings` decorator:

```python
from django.test import override_settings

@pytest.mark.django_db
@override_settings(EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend")
def test_sends_welcome_email(client):
    response = client.post("/register/", {"email": "a@b.com"})
    from django.core.mail import outbox
    assert len(outbox) == 1
```

## Security delta

- CSRF: Django's `Client` handles tokens automatically in tests; `APIClient` sets
  `enforce_csrf_checks=False` by default — test CSRF separately if needed.
- Auth: `api_client.force_authenticate(user=user)` to bypass auth in DRF tests;
  test the 401/403 path explicitly with an unauthenticated client.
- Never store plaintext passwords — use `User.objects.create_user()` or
  `UserFactory` (factory-boy calls `create_user` automatically).

## Success criteria (Django)

- `pytest-django` runner with `DJANGO_SETTINGS_MODULE` set; no bare `pytest` run.
- ORM tests marked `@pytest.mark.django_db`; ORM never mocked.
- `factory-boy` factories for all ORM objects; no hand-rolled setUp data.
- Both authenticated (200) and unauthenticated (401/403) paths tested explicitly.
- `@override_settings` used for env-dependent test branches; no monkey-patching.
