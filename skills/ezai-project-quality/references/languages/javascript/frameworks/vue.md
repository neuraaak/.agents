# Quality — Vue (delta)

> **Delta** on `references/languages/javascript/quality.md`. Load the JS/TS base
> file first; this file only adds or overrides what changes when Vue is used.
> Build/test tool assumed: **Vitest** (Vite-native).

## Detection

`vue` in `dependencies`, or `vite` + `@vitejs/plugin-vue` in `devDependencies`.

## Test stack delta

Replace the base `node:test` runner with **Vitest + Vue Test Utils**.
Test the component through its rendered output and user interactions, never its
internal state.

```json
{
  "devDependencies": {
    "vitest": "^2",
    "@vue/test-utils": "^2",
    "jsdom": "^25"
  }
}
```

```typescript
// vitest.config.ts — jsdom environment for component tests
import { defineConfig } from "vitest/config";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue()],
  test: { environment: "jsdom", globals: true },
});
```

## Component test pattern

```typescript
import { mount } from "@vue/test-utils";
import { expect, test } from "vitest";
import Counter from "./Counter.vue";

test("increments on click", async () => {
  const wrapper = mount(Counter);

  await wrapper.find("button").trigger("click");

  expect(wrapper.text()).toContain("Count: 1");
});
```

- Query via **semantic selectors** (`findByRole`, accessible labels) where possible;
  avoid selecting by class name or internal structure.
- Use `trigger()` (Vue Test Utils) for DOM interactions.
- `await nextTick()` when asserting state changes after async updates.

## Mocking network — MSW, not fetch stubs

For tests, intercept at the network layer with **MSW** rather than monkey-patching `fetch`:

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

## Composable testing

Test composables in isolation with a `withSetup` helper that provides the Vue
reactive context without mounting a full component:

```typescript
import { ref } from "vue";
import { useCounter } from "./useCounter";

test("useCounter increments", () => {
  const { result } = withSetup(() => useCounter());
  result.increment();
  expect(result.count.value).toBe(1);
});

function withSetup<T>(composable: () => T) {
  let result!: T;
  const app = createApp({ setup() { result = composable(); return () => {}; } });
  app.mount(document.createElement("div"));
  return { result };
}
```

## Security delta (client)

- No secret in client code — `VITE_`-prefixed vars ship in the bundle (see the
  config skill's Vue delta). Validate any server response with Zod before use.
- `v-html` only on sanitized HTML (`DOMPurify`); prefer text rendering (Vue
  escapes by default).

## Success criteria (Vue)

- Vitest + Vue Test Utils; `environment: "jsdom"` configured.
- Components tested through rendered output and user interactions, not internal state.
- Network mocked with MSW, not raw `fetch` patching.
- Composables tested in isolation with reactive context; `nextTick` for async updates.
- No secret in client bundle; untrusted HTML sanitized before `v-html`.
