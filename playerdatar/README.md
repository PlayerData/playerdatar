# Simple GraphQL R Wrapper

A simple R wrapper for making GraphQL requests with OAuth 2 authentication using the `ghql` package. Supports both client credentials and authorization code OAuth flows.

## Installation

### Install Dependencies

```r
install.packages(c("ghql", "httr", "jsonlite"))
```

For authorization code flow, `httpuv` is recommended:

```r
install.packages("httpuv")
```

### Install Package
Install the package from the command line:
From the command line in the `playerdatar` directory:

```bash
R CMD INSTALL .
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

Or run the example script:

```bash
export CLIENT_ID="your-client-id"
export CLIENT_SECRET="your-client-secret"
Rscript example_using_client_credentials.r
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

## Project Structure

```
playerdatar/
├── R/                    # Package source
│   ├── client.R          # GraphQL client creation
│   ├── oauth.R           # OAuth 2 flows
│   ├── operations.R      # execute_query, execute_mutation
│   └── utils.R           # Utilities
├── queries/              # Example GraphQL queries and mutations
│   ├── sports.graphql
│   ├── club_sessions.graphql
│   ├── club_sessions_filtered_by_time_range.graphql
│   ├── session_details.graphql
│   ├── session_metrics.graphql
│   ├── session_participations_urls.graphql
│   └── update_session.graphql
├── example_using_client_credentials.r
├── example_using_authorization_code.r
└── vignettes/
```

### Example Queries

GraphQL queries and mutations are stored as `.graphql` files in `playerdatar/queries/`. The example scripts load these files and pass them to `execute_query()` or `execute_mutation()`. For queries with variables, use `query_name` to match the operation name in the file (e.g. `SessionDetails` for `session_details.graphql`).

```r
# Load a query from file
read_query <- function(filename) {
  paste(readLines(file.path("queries", filename), warn = FALSE), collapse = "\n")
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

See `example_using_client_credentials.r` and `example_using_authorization_code.r` for more examples.
