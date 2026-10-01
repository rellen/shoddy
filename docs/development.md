# Development

This page tells a contributor how to get the tools, run the checks and add a
document. `CLAUDE.md` gives the rules for a commit message and for prose.

## Get the tools

The project uses Erlang 28.3.3 and Elixir 1.19.5. With Nix, start a shell
that has Erlang 28 and Elixir 1.19:

```sh
devenv shell
```

With mise, install the exact versions:

```sh
mise install
```

Then run these commands one time in each new clone:

```sh
mix deps.get
mix hook.install
```

`mix hook.install` tells git to use the directory `hooks`. Git then runs
`mix check` before each push.

## Run the checks

Run this command before each commit:

```sh
mix format && mix check --no-retry
```

`mix check` runs these tools in parallel:

- the compiler, with warnings as errors
- the tests
- the formatter
- Credo
- Dialyzer
- Sobelow
- `mix deps.audit`
- ExDoc
- Doctor, which examines whether each module and each public function has
  documentation and a spec

## Write tests

Each module has these tests:

- A doctest for each example in its `@doc`.
- A file with the suffix `_test.exs` in `test/`, with the usual ExUnit
  tests.
- A file with the suffix `_property_test.exs` in `test/`, with property
  tests. A property test uses StreamData to make many random inputs. It
  examines a rule that must be true for each input.

To find a gap in the tests, run mutation testing:

```sh
mix test.mutation
```

Muex makes many copies of the code, and each copy has one small change. If no
test fails for a copy, the tests have a gap. `mix check` does not run this
command, and a low score does not make the command fail.

## Add a document

`mix docs` makes the documentation in the directory `doc`. Open
`doc/index.html` to see the result. The site https://rellen.github.io/shoddy/
shows the result of the last push to `main`.

The documents follow Diátaxis, which is a method that puts each document
into one of four types. Put a new document into the directory of its type:

| Directory | Type | Content |
| --- | --- | --- |
| `docs/tutorials` | Tutorial | A lesson for a new user. The reader does each step and sees the result. |
| `docs/how-to` | How-to guide | The steps of one task, for a user who knows the library. |
| `docs/reference` | Reference | The facts about the functions, with no steps. |
| `docs/explanation` | Explanation | The design, and the reasons for it. |

The page of each module is also a reference. Its `@moduledoc` and each
`@doc` give the facts about the functions.

Then do these steps:

1. Add the document to the list `extras` in `mix.exs`.
2. Add the document to the list of documents in `README.md`.
3. Run each example of the document. No test runs the examples of a
   document in `docs`.
4. Read the text again, and compare it with the rules for prose in
   `CLAUDE.md`.

## Document a new function

Each new public function needs a document of each type that applies. Do
these steps in the commit that adds the function:

1. Reference: write the `@doc` with examples. Add the function to each
   table of `docs/reference/conventions.md` that applies. Examples are the
   tables of the modules, of the errors and of the functions as arguments.
2. How-to guide: add a section to a guide in `docs/how-to`, or write a new
   guide for a new task. Run each example.
3. Explanation: if the function makes a decision that a reader can find
   unusual, add a section to `docs/explanation/design.md`. The section tells
   the reason for the decision.
4. Tutorial: change `docs/tutorials/get-started.md` only if the function
   belongs in a first lesson.
5. Add a line to the part "Unreleased" of `CHANGELOG.md`. If the function
   changes what a module does, change its description in `README.md`.

## The workflow

`.github/workflows/check.yml` runs the checks for each pull request and for
each push to `main`. Each job runs some of the tools of `mix check`. The
comment at the start of the file gives the list.

The job `mutation` runs `mix test.mutation` after the tests succeed. It
reports the result only, and it never makes the workflow fail. The summary
of the run shows the result. For a pull request, the job also posts the
summary as a comment.

After a push to `main`, the job `pages` puts the site of `mix docs` on
GitHub Pages. The job `lint` makes the site, and it uploads the directory
`doc` when each of its steps succeeded. Thus the site and the checks come
from one build. The job `pages` needs the job `all`, so it starts only when
each check succeeded. A push to `main` with a failed check keeps the old
site.

The repository must have Pages on, with GitHub Actions as the source. A
person must turn it on in the settings of the repository, under "Pages",
because the token of a workflow cannot turn it on. A run of `pages` without
the site fails at the step `configure-pages`.

## Change the versions of Erlang and Elixir

Three files give the versions. Change the three files together:

| File | Content |
| --- | --- |
| `.tool-versions` | The exact versions. mise reads this file, and the session hook of Claude Code reads it too. |
| `.github/workflows/check.yml` | The exact versions, in the `env` block. |
| `devenv.nix` | The major and the minor version, in the names of the Nix packages. |
