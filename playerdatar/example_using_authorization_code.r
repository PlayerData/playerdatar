# Simple example of using the GraphQL R wrapper (authorization code flow)
#
# Uses the same query files as example_using_client_credentials.r.
# Run from playerdatar/playerdatar/ or adjust queries_dir.

library(playerdatar)

# Path to queries directory (relative to working directory)
queries_dir <- "queries"
if (!dir.exists(queries_dir)) {
  queries_dir <- file.path("playerdatar", "queries")
}
if (!dir.exists(queries_dir)) {
  stop("Could not find queries directory. Run from playerdatar/playerdatar/ or playerdatar/")
}

# Helper to load a query from file
read_query <- function(filename) {
  path <- file.path(queries_dir, filename)
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

# Set your OAuth credentials (or set them as environment variables)
client_id <- Sys.getenv("CLIENT_ID")
client_secret <- Sys.getenv("CLIENT_SECRET")
club_id <- Sys.getenv("CLUB_ID", "your-club-id")

# Create the GraphQL client
client <- create_gql_client(
  client_id = client_id,
  client_secret = client_secret,
  grant_type = "authorization_code"
)

# Example 1: Sports (simple query, no variables)
query <- read_query("sports.graphql")
result <- execute_query(client, query)
print(result)

# Example 2: Club sessions (filter by club ID)
query <- read_query("club_sessions.graphql")
result <- execute_query(
  client,
  query,
  query_name = "ClubSessions",
  variables = list(clubId = club_id)
)
print(result)

# Example 3: Club sessions filtered by time range (last 30 days)
start_time <- format(Sys.time() - as.difftime(30, units = "days"), "%Y-%m-%dT%H:%M:%OS3Z")
end_time <- format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3Z")

query <- read_query("club_sessions_filtered_by_time_range.graphql")
result <- execute_query(
  client,
  query,
  query_name = "ClubSessionsFilteredByTimeRange",
  variables = list(
    clubId = club_id,
    startTime = start_time,
    endTime = end_time
  )
)
print(result)

# Example 4: Session details (participations, athletes, segments)
session_id <- "your-session-id"  # Replace with actual session ID from Example 2 or 3
query <- read_query("session_details.graphql")
result <- execute_query(
  client,
  query,
  query_name = "SessionDetails",
  variables = list(sessionId = session_id)
)
print(result)

# Example 5: Session metrics (aggregate and per-participation metrics)
query <- read_query("session_metrics.graphql")
result <- execute_query(
  client,
  query,
  query_name = "SessionMetrics",
  variables = list(sessionId = session_id)
)
print(result)

# Example 6: Session participation URLs (raw data file URLs)
# Get session participation IDs from Example 4 response first
session_participation_ids <- c("your-session-participation-id")  # Replace with actual IDs
query <- read_query("session_participations_urls.graphql")
result <- execute_query(
  client,
  query,
  query_name = "SessionParticipationsUrls",
  variables = list(ids = session_participation_ids)
)
print(result)

# Example 7: Mutation - Update session
mutation <- read_query("update_session.graphql")
result <- execute_mutation(
  client,
  mutation,
  mutation_name = "UpdateSession",
  variables = list(
    id = "your-session-id",
    attributes = list(startTime = "2026-01-01T17:59:00.000Z")  # ISO 8601 format
  )
)
print(result)
