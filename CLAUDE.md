# Gym app project

Personal gym app (started 2026-10-07) — both an architecture experiment and a tool actually used at the gym. PWA with a distinct frontend and backend.

## Stack

- **Backend:** Python 3.14 + FastAPI, SQLAlchemy + Alembic, pytest, uv, ruff.
- **Frontend:** React + TypeScript + Vite (vite-plugin-pwa). Patterns drawn from the W&B POS example app (see below).

## Working agreements

- The user architects and makes the calls; Claude implements; the user reviews like a tech lead. On the frontend Claude takes more of a lead, but it must be well-architected.
- Backend is built with **acceptance-test-driven development**: for each feature, first write an acceptance test plus any relevant DSL (speaking the ubiquitous language, e.g. `start_workout()` / `log_set(...)`), then implement via regular TDD.
- **Acceptance tests are per-side, not cross-stack**: backend acceptance tests drive the API endpoints; frontend acceptance tests drive the UI against the in-memory adapters (stubbed API). The API contract is the seam — there is no end-to-end test harness spanning both.
- Yes to tests, migrations, linting. Commit message quality is not a priority.

## Backend architecture

- **Domain-driven design**: think in domain objects and features; the structure is driven by the domain, NOT by the framework. FastAPI stays at the edges; the domain layer is pure Python (no FastAPI/SQLAlchemy imports).
- Structure by domain concept, not technical layer — no global `routers/`/`models/`/`schemas/` buckets. Hold off hard-coding package boundaries until the core domain is sketched.
- **Repositories/read models are implemented in-memory first** within the TDD cycle; the SQLAlchemy/ORM implementation is added only when necessary. Both implementations satisfy the same port contract via shared contract tests.
- Ports defined in the domain, adapters (SQLAlchemy, FastAPI routers) in infrastructure; routers call application-layer use cases and never touch the ORM.

## Decoupling constraints

- Database and hosting must be completely decoupled from the logic so they can be swapped when scaling to other users: DB behind repository ports; hosting via twelve-factor config (all env-specific values from env vars in one config module at the composition root; the container image knows nothing about the host).
- Multi-tenancy insurance: model an owner/user identity in the domain from the first acceptance test, even while single-user, so adding users later is an auth feature rather than a domain/schema migration.

## Frontend patterns (from ~/Workspace/wolfandbadger/pos)

The example project is React Native/Expo + TypeScript. Patterns to replicate:

- **Ports & adapters per feature**: each IO feature defines a TS interface — `XHandler.handle(command)` for writes, `XReadModel` for reads — with an `InMemory`/`Local` adapter and a `Network` adapter. Both throw the same named domain error classes; the network adapter translates `HttpError` into them. Static factories: `XFactory.buildForLocal()` / `buildForNetwork(httpClient)`.
- **Vertical slices**: organized by business capability (`<domain>/features/<feature>/` with handler, readModel, serializer, hook, UI, tests co-located). `shared/` only for code used by 2+ domains.
- **Parse, don't validate**: Zod serializers at the boundary turn `unknown` responses into domain types, throwing named errors. Never `as`-cast API data.
- **Composition at the edges**: no DI container; route layouts are composition roots, passing adapters into domain context providers exposed via hooks. Navigation injected as callbacks — feature code never imports the router.
- **Rich domain entities** with behavior, rebuilt via factories so React re-renders.

Deliberate improvements over the POS app (its known warts):

- Depend on the `NetworkClient` interface, not the concrete `HttpClient` class.
- One consistent factory style.
- Single route tree with one composition root selecting the adapter set via mode/env switch (POS duplicates demo/ and live/ trees).
- Actually finish the acceptance-test DSL + swappable LocalDriver/NetworkDriver pattern.
- Don't swallow original errors in network adapters without logging.
- No hard-coded env module (POS `env.ts` hard-codes local) — twelve-factor config instead.

## Deferred decisions (revisit when first needed)

- Offline-first vs online-only client — design API/client state layer so offline can be retrofitted (gyms have bad signal).
- Container runtime (Docker vs Podman) — defer until first containerization; keep the image definition vanilla/OCI-compatible so either works.
- Hosting target (leaning Cloudflare Pages + Railway/Fly + Neon Postgres or SQLite) — defer until walking skeleton exists.
- ORM/real database — defer until in-memory repositories are no longer sufficient.
- Frontend server-state approach: POS-style providers + handlers (leaning) vs TanStack Query — settle during frontend design.
