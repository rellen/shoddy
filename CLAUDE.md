# AI Agent Guidelines

## Commit Messages

- Use the conventional commits format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`
- Keep the subject line under 72 characters
- Use imperative mood in the subject (e.g. "add feature" not "added feature")
- Include a body for non-trivial changes explaining the "why"

## Working with This Project

- This is an Elixir project using Mix as the build tool
- Run `mix test` before committing to ensure tests pass
- Run `mix format` to format code before committing
- Run `mix compile --warnings-as-errors` to check for compiler warnings

## Code Style

- Follow standard Elixir conventions and the project `.formatter.exs` if present
- Do not add dependencies without discussing with the maintainer first
- Keep modules focused and small

## Branch Strategy

- Feature branches should branch from `main`
- Use descriptive branch names prefixed with the change type (e.g. `feat/add-parser`, `fix/timeout-issue`)
