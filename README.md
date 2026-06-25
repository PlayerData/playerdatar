# Simple GraphQL R Wrapper

A simple R wrapper for making GraphQL requests with OAuth 2 authentication using the `ghql` package. Supports both client credentials and authorization code OAuth flows.

## Installation

### Option 1: Install from GitHub (recommended)

If you have access to the repository:

```r
install.packages("devtools")
devtools::install_github("PlayerData/playerdatar", subdir = "playerdatar")
```

> **Note:** Use `"PlayerData/playerdatar"` (owner/repo), not the full URL.

### Option 2: Install from a local clone

If you've cloned the repo:

```bash
cd playerdatar                    # repo root (the folder containing the playerdatar/ package subfolder)
R CMD INSTALL playerdatar          # install the package
```

Then in R:

```r
library(playerdatar)
```

## Quick Start

Load the package:

```r
library(playerdatar)
```

Create a client and execute a query:

```r
client <- create_gql_client(
  client_id = "your-client-id",
  client_secret = "your-client-secret"
)

result <- execute_query(client, '{ sports { id name } }')
```

Or run an example script:

```bash
cd playerdatar
export CLIENT_ID="your-client-id"
export CLIENT_SECRET="your-client-secret"
export CLUB_ID="your-club-id"
Rscript examples/direct/quick_start_client_credentials.R
```

## OAuth Flows

**Client Credentials** (default, server-to-server):

```r
client <- create_gql_client(
  client_id = "your-client-id",
  client_secret = "your-client-secret",
  grant_type = "client_credentials"
)
```

**Authorization Code** (requires browser login):

```r
client <- create_gql_client(
  client_id = "your-client-id",
  client_secret = "your-client-secret",
  grant_type = "authorization_code"
)
```

## Usage Examples

**Query with variables:**

```r
query <- 'query GetSessions($clubId: ID!) {
  sessions(filter: { clubIdEq: $clubId }) {
    id
    startTime
  }
}'

result <- execute_query(
  client, 
  query, 
  query_name = "GetSessions",
  variables = list(clubId = "your-club-id")
)
```

**Mutation:**

```r
mutation <- '
mutation UpdateSession($id: ID!, $attributes: SessionAttributesInput!) {
  updateSession(id: $id, attributes: $attributes) {
    errors {
      fullMessages
    }
    session {
      startTime
    }
  }
}
'

result <- execute_mutation(
  client,
  mutation,
  mutation_name = "UpdateSession",
  variables = list(
    id = "your-session-id",
    attributes = list(startTime = "2026-01-01T17:59:00.000Z") # ISO 8601 format
  )
)
```

## Folder Structure

Layout mirrors the sibling Python package [`playerdatapy`](https://github.com/PlayerData/playerdatapy) where it makes sense.

```
playerdatar/                  # repo root
├── README.md
├── LICENSE
├── playerdatar/              # R package
│   ├── AGENTS.md / CLAUDE.md # AI-assistant instructions
│   ├── DESCRIPTION
│   ├── NAMESPACE
│   ├── R/                    # Package source
│   │   ├── client.R          # GraphQL client creation
│   │   ├── oauth.R           # OAuth 2 flows
│   │   ├── operations.R      # execute_query, execute_mutation
│   │   └── utils.R           # Utilities
│   ├── examples/
│   │   └── direct/           # Raw-GraphQL quick starts
│   │       ├── queries/      # *.graphql query files
│   │       ├── quick_start_client_credentials.R
│   │       ├── quick_start_authorization_code.R
│   │       └── README.md
│   ├── schema.graphql        # Reference schema (vendored from playerdatapy)
│   ├── tests/testthat/       # Unit tests
│   ├── man/                  # roxygen2 docs
│   └── vignettes/
```

### Example Queries

GraphQL queries and mutations live as `.graphql` files in `playerdatar/examples/direct/queries/`. The example scripts load these files and pass them to `execute_query()` or `execute_mutation()`. For queries with variables, use `query_name` to match the operation name in the file (e.g. `SessionDetails` for `session_details.graphql`).

```r
read_query <- function(filename) {
  paste(readLines(file.path("examples/direct/queries", filename), warn = FALSE), collapse = "\n")
}

result <- execute_query(
  client,
  read_query("session_details.graphql"),
  query_name = "SessionDetails",
  variables = list(sessionId = "your-session-id")
)
```

## Features

- OAuth 2 authentication (client credentials & authorization code)
- Automatic token refresh and caching
- Simple API for queries and mutations
- Built on `ghql` package

See `playerdatar/examples/direct/` for runnable quick starts and the full set of example queries.

## Related Projects

- [`playerdatapy`](https://github.com/PlayerData/playerdatapy) — sibling Python package. Same API, typed `PlayerDataAPI` available alongside the direct client.
