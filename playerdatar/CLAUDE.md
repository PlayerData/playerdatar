# Claude Code instructions

Repo-specific guidance for AI assistants (Claude Code, Cursor, etc.). Humans, skim this too.

## Project shape

- R package `playerdatar` — thin GraphQL client for the PlayerData API, built on `ghql` + `httr`.
- Sibling Python package: [`playerdatapy`](https://github.com/PlayerData/playerdatapy). Structure here mirrors that repo where it makes sense (`examples/direct/`, `schema.graphql`, `tests/`).
- Reference GraphQL schema vendored at `schema.graphql` (copy of playerdatapy's). Use it when authoring new queries.
- Examples in `examples/direct/` (raw GraphQL via `execute_query()`). No typed-codegen path exists in R; the package is direct-only.

## Layout

- `R/` — package source (`client.R`, `oauth.R`, `operations.R`, `utils.R`).
- `man/` — roxygen2-generated documentation. Do not hand-edit; regenerate with `devtools::document()`.
- `NAMESPACE` — roxygen2-generated. Do not hand-edit.
- `examples/direct/` — runnable quick-start scripts plus `queries/*.graphql`.
- `tests/testthat/` — unit tests. Run with `devtools::test()`.
- `vignettes/` — long-form usage docs.

## Conventions

- Write tests first (RED, GREEN, REFACTOR). New behavior gets a `tests/testthat/test-*.R`.
- No code comments except roxygen2 doc blocks. Write expressive code.
- After editing roxygen blocks, run `devtools::document()` so `man/` and `NAMESPACE` stay in sync.
- No Claude attribution in commit messages.

## Common commands

```r
devtools::load_all()    # iterate
devtools::test()        # run tests
devtools::document()    # regenerate man/ + NAMESPACE
devtools::check()       # full R CMD check
```

## Running examples

```bash
export CLIENT_ID=...
export CLIENT_SECRET=...
export CLUB_ID=...
Rscript examples/direct/quick_start_client_credentials.R
```
