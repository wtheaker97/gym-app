# Gym App

Personal gym app: a PWA for tracking workouts at the gym, built as an architecture exercise with domain-driven design.

## Structure

- `backend/` — Python 3.14 + FastAPI. DDD: pure-Python domain, in-memory-first repositories, ATDD workflow. Managed with [uv](https://docs.astral.sh/uv/).
- `frontend/` — React + TypeScript + Vite PWA. Ports & adapters with in-memory and network implementations.

See `CLAUDE.md` for the architectural conventions and working agreements.

## Development

```sh
# Backend
cd backend
uv run pytest
uv run ruff check .

# Frontend
cd frontend
npm install
npm run dev
```
