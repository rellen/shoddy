# Development

This page tells a contributor how to get the tools, how to run the checks,
and how to add a document. `CLAUDE.md` gives the rules for a commit message
and for prose.

## The toolchain

The project uses Erlang 28.3.3 and Elixir 1.19.5. `.tool-versions` gives
these versions. Three places give the same versions:

- `devenv.nix` gives them in a Nix shell.
- `.claude/hooks/session-start.sh` reads `.tool-versions` and installs the
  versions with mise in a remote session of Claude Code.
- `.github/workflows/check.yml` gives them in the `env` block.

Change the four places together.

Run these commands one time in each new clone:

```sh
mix deps.get
mix hook.install
```

`mix hook.install` tells git to use the directory `hooks`. Git then runs
`mix check` before each push.

## The checks

Run this command before each commit:

```sh
mix format && mix check --no-retry
```

`mix check` runs these tools in parallel: the compiler, the tests, the
formatter, Credo, Dialyzer, Sobelow, `mix deps.audit`, ExDoc and Doctor.
Doctor examines whether each module and each public function has
documentation and a spec.

## The tests

The project has three kinds of tests:

- A doctest is an example in a `@doc`. `mix test` runs each example and
  compares the result with the text of the example.
- A property test uses StreamData to make many random inputs. It examines a
  rule that must be true for each input. Each module has a file with the
  suffix `_property_test.exs` in `test/`.
- Mutation testing finds a gap in the tests. Run it with this command:

  ```sh
  mix test.mutation
  ```

  Muex makes many copies of the code, and each copy has one small change.
  If no test fails for a copy, the tests have a gap. `mix check` does not
  run this command, and a low score does not make the command fail.

## The documents

`mix docs` makes the documentation with ExDoc in the directory `doc`. Open
`doc/index.html` to see the result. The site at
https://rellen.github.io/shoddy/ shows the result of the last push to
`main`.

The documents follow Diátaxis. Diátaxis is a method that puts each document
into one of four types. Put a new document in the directory of its type:

| Directory | Type | Purpose |
| --- | --- | --- |
| `docs/tutorials` | Tutorial | A lesson. The reader does each step and sees the result. |
| `docs/how-to` | How-to guide | The steps for one task. The reader already knows the library. |
| `docs/reference` | Reference | The facts about the functions, with no steps. |
| `docs/explanation` | Explanation | The design, and the reasons for it. |

The page of each module is also a reference. Its `@moduledoc` and each
`@doc` give the facts about the functions.

Add each new document to the list `extras` in `mix.exs`, and to the list of
documents in `README.md`. Write each document in ASD-STE100. `CLAUDE.md`
gives the rules.

Run each example of a new document before you commit it. A doctest runs the
examples of a `@doc`, but no test runs the examples of a document in
`docs`.

## The workflow

`.github/workflows/check.yml` runs the checks for each pull request and for
each push to `main`. Each job runs some of the tools of `mix check`. The
comment at the start of the file gives the list.

The job `mutation` runs `mix test.mutation` after the tests succeed. It
reports the result only, and it never makes the workflow fail. For a pull
request, it posts the summary as a comment on the pull request.

After a push to `main`, the job `pages` puts the site of `mix docs` on
GitHub Pages. The job `lint` makes the site, and it uploads the directory
`doc` when each of its steps succeeded. The site and the checks thus come
from one build. The job `pages` needs the last job, so it starts only when
each check succeeded. A push to `main` with a failed check keeps the old
site.

The repository must have Pages on, with GitHub Actions as the source. Turn it
on in the settings of the repository, under "Pages". The token of a workflow
cannot turn it on. A run of `pages` without the site fails at the step
`configure-pages`.
