# Vue Patterns (non-negotiable)

Auto-loaded for every session in this repo. Applies to the {{PROJECT_NAME}} Vue 3 frontend. Reviewed by the `vue-engineer` agent and gate 3 of the 6-gate post-delegation review.

## The stack (locked)

- Vue 3 Composition API + `<script setup lang="ts">`
- TypeScript strict (`tsconfig.json` extends strict)
- Pinia for state (thin stores — logic lives in services)
- vue-router 4
- vue-i18n (`useI18n()` composable, multiple locales kept at parity)
- Vite build
- Vitest (unit) + Playwright (E2E)

Do NOT introduce other state libraries (Vuex / a global event bus). Do NOT roll your own HTTP fetcher — use the project's `apiGet / apiPost / apiPatch / apiDelete` helpers.

## Core patterns

### Composition API with `<script setup>` everywhere

Single-file components use `<script setup lang="ts">`. No Options API for new code. Reactive state via `ref` / `reactive`; computed via `computed`; side-effects via `watch` / `watchEffect` / lifecycle hooks (`onMounted`, `onUnmounted`).

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useCustomerStore } from '@/stores/customer'

const { t } = useI18n()
const store = useCustomerStore()
const search = ref('')
const filtered = computed(() => store.customers.filter(c => c.name.includes(search.value)))

onMounted(() => store.load())
</script>
```

### Pinia: thin stores, fat services

Stores hold **state** and trivial mutations. Anything with branching logic, error handling, or HTTP I/O lives in a `services/` module that the store calls.

```ts
// src/stores/customer.ts — THIN
export const useCustomerStore = defineStore('customer', () => {
  const customers = ref<Customer[]>([])
  const isLoading = ref(false)
  const error = ref<Error | null>(null)

  async function load() {
    isLoading.value = true
    error.value = null
    try {
      customers.value = await customerService.list()
    } catch (e) {
      error.value = e as Error
    } finally {
      isLoading.value = false
    }
  }
  return { customers, isLoading, error, load }
})

// src/services/customer.ts — FAT
import { apiGet } from '@/lib/api'
export const customerService = {
  async list(): Promise<Customer[]> {
    const raw = await apiGet<Customer[]>('/api/v1/customers')
    return raw ?? []                        // null-safe coalesce
  },
}
```

**Verify store methods before you call them.** Refactors rename methods; callers don't always update. Before writing `store.x()`, grep the store file to confirm `x` exists.

### Service layer uses the api helpers

`apiGet / apiPost / apiPatch / apiDelete` wrap `fetch`, JWT-cookie auth, the project's response envelope, and base-URL config. NEVER add `import.meta.env.VITE_API_BASE_URL` manually in a service or component — that bypasses the helpers and breaks env-driven routing.

```ts
// CORRECT
const data = await apiGet<Customer[]>('/api/v1/customers')

// WRONG
const res = await fetch(`${import.meta.env.VITE_API_BASE_URL}/api/v1/customers`)
```

### Raw fetch (rare) — null-guard + snake-to-camel

If you must bypass `apiGet` (e.g. third-party endpoint), you take on two extra responsibilities:

1. **Null-guard the response.** Backends often return `null` for empty lists. `const rows = await rawFetch(); rows.map(...)` will crash. Coalesce: `const rows = (await rawFetch()) ?? []`.
2. **snake_case → camelCase mapping for the entire response, including nested objects.** Easy to miss the deep ones. Prefer a utility (e.g. `camelizeKeys`) over hand-mapping.

### i18n: every visible string via `t()`

Every user-facing string goes through `t('key')` via `useI18n()`. Hardcoded text is forbidden by lint (and by the reviewer). Add every new key to every locale file in the same PR — the lint catches missing keys in code but cannot catch a missing locale value.

```vue
<template>
  <button :aria-label="t('actions.save')">{{ t('actions.save') }}</button>
</template>
```

**Escape `@` in translation values.** vue-i18n treats `@` as a link to another key. Email addresses and similar need `{'@'}`:

```json
{ "help.contact": "Contact {'@'}example.com for support" }
```

### Layout in `App.vue` only

Layout components (`MainLayout.vue` / `AuthLayout.vue` / etc.) are mounted in `App.vue` based on the current route. Pages must NEVER `import MainLayout from ...` and wrap themselves — that nests layouts and breaks transitions.

```vue
<!-- App.vue — CORRECT -->
<template>
  <MainLayout v-if="layout === 'main'">
    <RouterView />
  </MainLayout>
  <AuthLayout v-else-if="layout === 'auth'">
    <RouterView />
  </AuthLayout>
</template>

<!-- src/pages/customer/CustomerList.vue — CORRECT, no layout import -->
<template>
  <div class="customer-list">...</div>
</template>
```

### Menu changes touch 3 places

Adding or renaming a menu item requires updates in:

1. The menu config file (label key, route, icon)
2. The layout's active-route matching (so the right item highlights)
3. The i18n key for the label, in every locale file

Miss any one → silent broken UX (wrong item highlights, missing label, dead link). The `vue-engineer` agent's report must confirm all three.

### Role checks: exact-spelling strings

Conditions on role / permission strings (`if (user.role === 'admin')`) MUST match the backend DB spelling exactly. Before hardcoding, curl `/api/v1/auth/me` (or the equivalent) and read the actual values. Backends sometimes use `Admin` / `ADMIN` / `admin` / `super-admin` — pick the wrong case and the check silently fails.

## Testing patterns

- **Unit (Vitest)** for stores, services, composables, components. Test behavior: given props / store state, the right elements render and the right events fire. Don't test implementation details.
- **E2E (Playwright)** for user-visible flows. Selectors via `data-testid`, not class names.
- **TDD** — write the failing test first; confirm it fails for the right reason; then implement.
- **Run the full suite after nav / router / menu changes.** Side-effect tests catch regressions you didn't think of.

## Forbidden

- Hardcoded user-facing strings (use `t()`)
- Layout component imported in a page (mount in `App.vue` only)
- Manual `import.meta.env.VITE_API_BASE_URL` in a service (use the api helpers)
- Calling `store.x()` without grep-verifying `x` exists
- Removing a `data-testid` without first migrating the E2E specs that use it
- Editing one locale file without parity edit in the others
- Bypassing `apiGet` without null-guard + snake-to-camel mapping
- Testing visual / SPA changes via `curl` (SPAs return an empty shell — use Playwright / Chrome DevTools MCP)

## Related

- `.claude/agents/vue-engineer.md` — engineer that follows this rule
- `.claude/rules/brain-hot.md` — references this rule
- `.claude/rules/sub-agent-workflow.md` — gate 3 of the 6-gate review
- `docs/setup/lesson-trigger-map.md` — file-touch → rule trigger map
