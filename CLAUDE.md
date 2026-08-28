# AI Agent Guidelines

## Critical: Write All Documentation in ASD-STE100

**All documentation in this repository must obey ASD-STE100 Simplified
Technical English. This rule is not optional. Do not write documentation in
any other style.**

This document says STE for ASD-STE100 after this point. STE keeps text
short, active, and unambiguous. A reader who does not speak
English as a first language can then read the text correctly. A machine
translation of the text also stays correct. A reader must never need to guess
what a sentence means.

This rule applies to all of these:

- `README.md` and every other Markdown file
- Every `@moduledoc`, `@doc`, and `@typedoc`
- Every code comment, in Elixir files and in shell scripts
- Every description in a `test` block or a `describe` block
- Every message that a script prints
- The `description` field in `mix.exs`

Obey these nine rules each time you write or change that text:

1. Write one instruction in one sentence. Keep a procedural sentence shorter
   than 20 words. Keep a descriptive sentence shorter than 25 words.
2. Use the active voice. Write "The function ignores a falsy value". Do not
   write "Falsy values are skipped".
3. Do not use the -ing form. Write "Functions that operate on maps". Do not
   write "Functions for working with maps". The -ing form is permitted only
   inside a technical name, such as "functional programming".
4. Write complete sentences. Do not remove words to make a sentence shorter.
   Give every sentence a subject.
5. Use articles. Write "an ok tuple". Do not write "ok tuple".
6. Use one term for one thing. Do not use a second word for variety. This
   repository says "puts a value into". It never says "wraps a value in".
7. Do not use slang, idiom, or undefined jargon. Define each technical term
   at the place where you first use it.
8. Keep the punctuation simple. Do not use an em dash. Do not use a slash
   between two words. Use a vertical list for complex text.
9. Do not use an abbreviation that this repository does not define. Write
   "for example". Do not write "e.g.".

There is one permitted exception. The summary line of a `@doc` can keep the
usual Elixir form. That line can start with a verb, as in "Applies a function
to a value". That line is the title of the entry in the generated
documentation, and STE permits a short form in a title.

Read your text again before each commit. Check it against the nine rules
above. A change that adds documentation in another style is not complete.

## Commit Messages

- Use the conventional commits format: `type(scope): description`.
- Use one of these types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`,
  `ci`.
- Keep the subject line shorter than 72 characters.
- Write the subject in the imperative mood. For example, write "add feature",
  not "added feature".
- Add a body to each commit that is not trivial. In the body, tell why you
  made the change.
- Write the body in ASD-STE100. Obey the rules in the first section.

## How to Work on This Project

- This project uses Elixir. Mix is the build tool.
- Run `mix format && mix check --no-retry` before each commit. This command
  formats the code and does all the checks.
- Use `mix check --no-retry`. It does all the checks in parallel. The checks
  include the compiler, the tests, Credo, and Dialyzer.
- Do not run `mix test`, `mix compile --warnings-as-errors`, or `mix credo` as
  separate commands. `mix check` does all of them.
- Run `mix hook.install` one time in each new clone. That command tells git to
  use the `hooks` directory of this project. Git then runs `mix check` before
  each push.

## Code Style

- Obey the usual Elixir conventions and the `.formatter.exs` file of the
  project, if that file is present.
- Write every comment, `@moduledoc`, `@doc`, `@typedoc`, and test
  description in ASD-STE100. Obey
  the rules in the first section.
- Do not add a dependency before you discuss it with the maintainer.
- Keep each module small. Give each module one clear purpose.

## Branch Strategy

- Make each feature branch from `main`.
- Give each branch a descriptive name. Put the change type at the start of the
  name. For example: `feat/add-parser` or `fix/timeout-issue`.
