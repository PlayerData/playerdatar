# Direct GraphQL Examples

R equivalents of the playerdatapy `examples/direct/` folder. Demonstrate using `playerdatar` by directly executing GraphQL query strings via `create_gql_client()` and `execute_query()`.

## Overview

The direct approach hands you full control over GraphQL query strings. More flexible than typed wrappers; you construct queries and handle response shape yourself.

## Quick Start

Two quick starts, one per OAuth flow:

```bash
Rscript examples/direct/quick_start_client_credentials.R
Rscript examples/direct/quick_start_authorization_code.R
```

Before running, set:

```bash
export CLIENT_ID=your_client_id
export CLIENT_SECRET=your_client_secret
export CLUB_ID=your_club_id
```

## Basic Usage Pattern

```r
library(playerdatar)

client <- create_gql_client(
  client_id = Sys.getenv("CLIENT_ID"),
  client_secret = Sys.getenv("CLIENT_SECRET")
)

query <- '
query($clubId: ID!, $startTime: ISO8601DateTime, $endTime: ISO8601DateTime) {
  sessions(filter: { clubIdEq: $clubId, startTimeGteq: $startTime, endTimeLteq: $endTime }) {
    id
    startTime
    endTime
  }
}
'

result <- execute_query(
  client,
  query,
  query_name = "ClubSessionsFilteredByTimeRange",
  variables = list(
    clubId = Sys.getenv("CLUB_ID"),
    startTime = format(Sys.time() - as.difftime(30, units = "days"), "%Y-%m-%dT%H:%M:%OS3Z"),
    endTime = format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3Z")
  )
)
print(result)
```

## Building Queries

Use the GraphiQL Playground at https://app.playerdata.co.uk/api/graphiql/ to test queries, explore the schema, and validate syntax interactively.

The query files in `queries/` mirror the set shipped in playerdatapy's `examples/direct/queries/`.

## Authentication Types

- `create_gql_client(client_id, client_secret)` — client credentials flow (default; backend-to-backend).
- `get_oauth_token_authorization_code(...)` — authorization code flow. See `quick_start_authorization_code.R`.

## When to Use Direct GraphQL

- You need full control over query strings.
- You are porting existing GraphQL queries.
- You prefer raw GraphQL syntax.

The R package is currently direct-only; there is no typed equivalent of playerdatapy's `examples/pydantic/`.
