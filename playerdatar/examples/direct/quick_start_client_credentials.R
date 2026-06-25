# Quick start: client credentials OAuth flow.
#
# Sibling example: quick_start_authorization_code.R (same queries).
# Run from this directory, or from repo root, or from playerdatar/.

library(playerdatar)

candidate_dirs <- c(
  "queries",
  "examples/direct/queries",
  file.path("playerdatar", "examples", "direct", "queries")
)
queries_dir <- Find(dir.exists, candidate_dirs)
if (is.null(queries_dir)) stop("Could not locate queries directory.")
read_query <- function(filename) {
  paste(readLines(file.path(queries_dir, filename), warn = FALSE), collapse = "\n")
}

# Set your OAuth credentials (or set them as environment variables)
client_id <- Sys.getenv("CLIENT_ID")
client_secret <- Sys.getenv("CLIENT_SECRET")
club_id <- Sys.getenv("CLUB_ID", "your-club-id")

# Create the GraphQL client
client <- create_gql_client(
  client_id = client_id,
  client_secret = client_secret
)

# Example 1: Sports (simple query)
result <- execute_query(client, read_query("sports.graphql"))
print(result)

# Example 2: Club sessions
result <- execute_query(
  client,
  read_query("club_sessions.graphql"),
  query_name = "ClubSessions",
  variables = list(clubId = club_id)
)
print(result)

# Example 3: Club sessions filtered by time range
start_time <- format(Sys.time() - as.difftime(30, units = "days"), "%Y-%m-%dT%H:%M:%OS3Z")
end_time <- format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3Z")
result <- execute_query(
  client,
  read_query("club_sessions_filtered_by_time_range.graphql"),
  query_name = "ClubSessionsFilteredByTimeRange",
  variables = list(clubId = club_id, startTime = start_time, endTime = end_time)
)
print(result)

# Example 4: Session details
session_id <- "your-session-id"
result <- execute_query(
  client,
  read_query("session_details.graphql"),
  query_name = "SessionDetails",
  variables = list(sessionId = session_id)
)
print(result)

# Example 5: Session metrics
result <- execute_query(
  client,
  read_query("session_metrics.graphql"),
  query_name = "SessionMetrics",
  variables = list(sessionId = session_id)
)
print(result)

# Example 6: Session participation URLs
result <- execute_query(
  client,
  read_query("session_participations_urls.graphql"),
  query_name = "SessionParticipationsUrls",
  variables = list(ids = c("your-session-participation-id"))
)
print(result)
