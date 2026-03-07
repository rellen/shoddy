# AI Agent Guidelines

## Commit Messages

- Use the conventional commits format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`
- Keep the subject line under 72 characters
- Use imperative mood in the subject (e.g. "add feature" not "added feature")
- Include a body for non-trivial changes explaining the "why"

## Working with This Project

- This is an Elixir project using Mix as the build tool
- Run `mix format && mix check --no-retry` to format and verify everything before committing
- Do: `mix check --no-retry` — runs all checks (compiler, tests, credo, dialyzer, etc.) in parallel
- Don't: `mix test`, `mix compile --warnings-as-errors`, `mix credo` separately — `mix check` runs them all

## Code Style

- Follow standard Elixir conventions and the project `.formatter.exs` if present
- Do not add dependencies without discussing with the maintainer first
- Keep modules focused and small

## Branch Strategy

- Feature branches should branch from `main`
- Use descriptive branch names prefixed with the change type (e.g. `feat/add-parser`, `fix/timeout-issue`)
