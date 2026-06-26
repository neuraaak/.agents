# Quality — React (delta)

> **Delta** on `references/languages/javascript/quality.md`. Load the JS/TS base
> file first; this file only adds or overrides what changes when React is used.
> Build/test tool assumed: **Vitest** (Vite-native).

## Detection

`react` / `react-dom` in `dependencies`, or `vite` + `@vitejs/plugin-react` in
`devDependencies`.

## Test stack delta

Replace the base `node:test` runner with **Vitest + React Testing Library**.
Test the component through its rendered output and user interactions, never its
internal state.

```json
{
  "devDependencies": {
    "vitest": "^2",
    "@testing-library/react": "^16",
    "@testing-library/user-event": "^14",
    "jsdom": "^25"
  }
}
```

```typescript
// vitest.config.ts — jsdom environment for component tests
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: { environment: "jsdom", globals: true, setupFiles: "./src/test/setup.ts" },
});
```

```typescript
// src/test/setup.ts
import "@testing-library/jest-dom/vitest"; // adds toBeInTheDocument(), etc.
```

## Component test pattern

```typescript
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, test, vi } from "vitest";
import { Counter } from "./Counter";

test("increments on click", async () => {
  const user = userEvent.setup();
  render(<Counter />);

  await user.click(screen.getByRole("button", { name: /increment/i }));

  expect(screen.getByText("Count: 1")).toBeInTheDocument();
});
```

- Query by **accessible role / label** (`getByRole`, `getByLabelText`), not by
  test id or class — this couples tests to user-visible behavior.
- Drive interactions with `userEvent` (realistic), not `fireEvent`.
- `findBy*` (async) for elements that appear after an effect or fetch.

## Mocking network — MSW, not fetch stubs

Validation already happens at the boundary (base rule, Zod). For tests, intercept
at the network layer with **MSW** rather than monkey-patching `fetch`:

```typescript
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";

const server = setupServer(
  http.get("/api/user", () => HttpResponse.json({ id: 1, name: "Ada" })),
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

## Hooks testing

```typescript
import { renderHook, act } from "@testing-library/react";
import { useCounter } from "./useCounter";

test("useCounter increments", () => {
  const { result } = renderHook(() => useCounter());
  act(() => result.current.increment());
  expect(result.current.count).toBe(1);
});
```

Wrap every state update in `act(...)`.

## Security delta (client)

- No secret in client code — `VITE_`-prefixed vars ship in the bundle (see the
  config skill's React delta). Validate any server response with Zod before use.
- `dangerouslySetInnerHTML` only on sanitized HTML (`DOMPurify`); prefer text
  rendering, which React escapes by default.

## Success criteria (React)

- Vitest + React Testing Library; `environment: "jsdom"` configured.
- Queries by accessible role/label; interactions via `userEvent`.
- Network mocked with MSW, not raw `fetch` patching.
- Hooks tested via `renderHook` with updates wrapped in `act`.
- No secret in client bundle; untrusted HTML sanitized before `dangerouslySetInnerHTML`.
