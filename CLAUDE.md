# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Prerequisites

### Required Tools
- **uv**: Python package manager - [Installation guide](https://docs.astral.sh/uv/getting-started/installation/)
- **pnpm**: Node.js package manager - Install via `npm install -g pnpm`
- **Docker**: For database and containerized development
- **Python 3.12+** and **Node.js**

See [docs/get-started.md](docs/get-started.md) for complete setup instructions.

## Architecture Overview

This is a **Next.js + FastAPI full-stack template** with end-to-end type safety. The key architectural pattern is the **hot-reload type-safe API workflow**:

1. **Backend changes trigger client regeneration**: The backend watcher (`fastapi_backend/watcher.py`) monitors `main.py`, `schemas.py`, and `app/routes/*.py` files
2. **OpenAPI schema auto-generation**: When backend files change, it runs mypy checks and regenerates the OpenAPI schema to `local-shared-data/openapi.json`
3. **Frontend client auto-generation**: The frontend watcher (`nextjs-frontend/watcher.js`) detects OpenAPI changes and automatically regenerates TypeScript clients in `app/openapi-client/`
4. **Type safety maintained**: This ensures frontend and backend API contracts stay synchronized during development

## Development Commands

### Quick Start (Recommended)
```bash
# Backend with hot reload and watcher
make start-backend

# Frontend with hot reload
make start-frontend
```

### Frontend Commands
```bash
cd nextjs-frontend

# Development
pnpm dev                    # Start Next.js dev server
pnpm build                  # Build for production  
pnpm generate-client        # Regenerate TypeScript API client

# Code Quality
pnpm lint                   # ESLint
pnpm tsc                    # TypeScript type checking
pnpm prettier               # Format code

# Testing
pnpm test                   # Jest tests
pnpm coverage               # Jest with coverage
```

### Backend Commands
```bash
cd fastapi_backend

# Development
uv run fastapi dev app/main.py --host 0.0.0.0 --port 8000 --reload
uv run python watcher.py   # File watcher for schema regeneration

# Code Quality  
uv run mypy app             # Type checking
uv run pytest              # Run tests

# Database
uv run alembic upgrade head # Apply migrations
uv run alembic revision --autogenerate -m "description"  # Create migration

# OpenAPI
uv run python -m commands.generate_openapi_schema  # Manual schema generation
```

### Docker Development
```bash
# Build and run containers
make docker-build
make docker-start-backend
make docker-start-frontend

# Database operations
make docker-migrate-db
make docker-db-schema migration_name="your description"

# Testing in containers
make docker-test-backend
make docker-test-frontend
```

## Critical Workflow Patterns

### Type-Safe API Development
1. Modify backend routes/schemas in `fastapi_backend/app/`
2. Backend watcher automatically runs mypy and regenerates OpenAPI schema
3. Frontend watcher detects schema changes and regenerates `app/openapi-client/`
4. Use the generated client: `import { DefaultService } from "@/app/openapi-client"`

### Authentication System
- Uses `fastapi-users` with JWT tokens stored in cookies
- Routes protected by `nextjs-frontend/middleware.ts`
- Password reset flow with email templates in `fastapi_backend/app/email_templates/`

### Database Management
- SQLAlchemy async models in `fastapi_backend/app/models.py`
- Alembic migrations in `fastapi_backend/alembic_migrations/versions/`
- Separate test database (port 5433) for isolation

## Testing

### Backend Tests
```bash
cd fastapi_backend
uv run pytest              # All tests
uv run pytest tests/routes/test_items.py  # Specific test
uv run pytest -v           # Verbose output
```

### Frontend Tests  
```bash
cd nextjs-frontend
pnpm test                   # All tests
pnpm test login.test.tsx    # Specific test
pnpm coverage               # With coverage report
```

## Environment Configuration

### Development Setup
- Backend: Copy `.env.example` to `.env` in `fastapi_backend/`
- Frontend: Copy `.env.local.example` to `.env.local` in `nextjs-frontend/`
- Key variable: `OPENAPI_OUTPUT_FILE` points to shared OpenAPI schema location

### Shared Schema Location
- OpenAPI schema: `local-shared-data/openapi.json`
- This file is shared between backend generation and frontend consumption

## Code Quality Tools

Always run these before committing:
```bash
# Backend
cd fastapi_backend && uv run mypy app && uv run pytest

# Frontend  
cd nextjs-frontend && pnpm tsc && pnpm lint && pnpm test
```

Pre-commit hooks handle automated formatting and basic checks.

## Deployment

### Local Development
- Uses Docker Compose with PostgreSQL, MailHog email testing
- Frontend: http://localhost:3000
- Backend: http://localhost:8000
- Email UI: http://localhost:8025

### Production (Vercel)
- Both frontend and backend deploy to Vercel as serverless functions
- Backend uses `fastapi_backend/vercel.json` configuration
- Frontend uses standard Next.js Vercel deployment

## Package Managers
- Backend: **uv** (faster Python package manager)
- Frontend: **pnpm** (faster Node.js package manager)