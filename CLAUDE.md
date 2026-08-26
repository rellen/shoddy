# AI Agent Guidelines

## Commit Messages

- Use the conventional commits format: `type(scope): description`.
- Use one of these types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`,
  `ci`.
- Keep the subject line shorter than 72 characters.
- Write the subject in the imperative mood. For example, write "add feature",
  not "added feature".
- Add a body to each commit that is not trivial. In the body, tell why you
  made the change.

## How to Work on This Project

- This project uses Elixir. Mix is the build tool.
- Run `mix format && mix check --no-retry` before each commit. This command
  formats the code and does all the checks.
- Use `mix check --no-retry`. It does all the checks in parallel. The checks
  include the compiler, the tests, Credo, and Dialyzer.
- Do not run `mix test`, `mix compile --warnings-as-errors`, or `mix credo` as
  separate commands. `mix check` does all of them.

## Code Style

- Obey the usual Elixir conventions and the `.formatter.exs` file of the
  project, if that file is present.
- Do not add a dependency before you discuss it with the maintainer.
- Keep each module small. Give each module one clear purpose.

## Branch Strategy

- Make each feature branch from `main`.
- Give each branch a descriptive name. Put the change type at the start of the
  name. For example: `feat/add-parser` or `fix/timeout-issue`.
