# Example of exporting raw session data via the PlayerData API.
#
# Mirrors the Python example in the "Exporting Raw Data" documentation:
#   1. Find a session participation
#   2. Request a GPS export
#   3. Poll until the export is READY
#   4. Download the file (and read it into a dataframe)
#
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

client_id <- Sys.getenv("CLIENT_ID")
client_secret <- Sys.getenv("CLIENT_SECRET")
club_id <- Sys.getenv("CLUB_ID", "your-club-id")

client <- create_gql_client(
  client_id = client_id,
  client_secret = client_secret
)

# Poll a raw-data export mutation until it reaches a terminal status.
# Works for both requestRawDataExport (per-participation) and
# requestSessionRawDataExport (whole session): the result field name is
# passed in via `result_field`.
poll_export <- function(client,
                        mutation,
                        mutation_name,
                        result_field,
                        variables,
                        poll_interval = 15,
                        timeout = 900) {
  deadline <- Sys.time() + timeout
  repeat {
    response <- execute_mutation(
      client,
      mutation,
      mutation_name = mutation_name,
      variables = variables
    )
    result <- response$data[[result_field]]

    if (length(result$errors) > 0) {
      messages <- unlist(lapply(result$errors, `[[`, "fullMessages"))
      stop(sprintf("Export failed: %s", paste(messages, collapse = "; ")))
    }
    if (identical(result$status, "READY")) {
      return(result)
    }
    if (identical(result$status, "UNAVAILABLE")) {
      stop(sprintf("No %s data is available", variables$dataType))
    }
    if (Sys.time() > deadline) {
      stop(sprintf("Export still preparing after %.0fs", timeout))
    }
    Sys.sleep(poll_interval)
  }
}

# --- Per-participation export: one athlete, one session ---------------------

# Step 1: pick a session participation to export.
start_time <- format(
  Sys.time() - as.difftime(30, units = "days"),
  "%Y-%m-%dT%H:%M:%OS3Z"
)
end_time <- format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3Z")
sessions <- execute_query(
  client,
  read_query("club_sessions_filtered_by_time_range.graphql"),
  query_name = "ClubSessionsFilteredByTimeRange",
  variables = list(clubId = club_id, startTime = start_time, endTime = end_time)
)
session_id <- sessions$data$sessions[[1]]$id

details <- execute_query(
  client,
  read_query("session_details.graphql"),
  query_name = "SessionDetails",
  variables = list(sessionId = session_id)
)
participation <- details$data$session$sessionParticipations[[1]]
message(sprintf("Exporting GPS data for %s", participation$athlete$name))

# Step 2 and 3: request the export and poll until it is READY.
export <- poll_export(
  client,
  mutation = read_query("request_raw_data_export.graphql"),
  mutation_name = "RequestRawDataExport",
  result_field = "requestRawDataExport",
  variables = list(id = participation$id, dataType = "GPS", format = "CSV")
)

# Step 4: download the CSV. The link is valid for 15 minutes.
download.file(export$downloadUrl, "gps.csv", mode = "wb")
message("saved gps.csv")

# To load straight into a dataframe instead of (or as well as) saving the file:
#   gps <- read.csv(export$downloadUrl)                # base R
#   gps <- readr::read_csv(export$downloadUrl)         # tidyverse

# --- Whole-session export: one zip for every athlete ------------------------
#
# The session mutation polls identically; it just returns a zip plus the IDs
# of any athletes left out of the export (no data of this type recorded, or
# device still uploading). Requires staff-level access to the club.

session_export <- poll_export(
  client,
  mutation = read_query("request_session_raw_data_export.graphql"),
  mutation_name = "RequestSessionRawDataExport",
  result_field = "requestSessionRawDataExport",
  variables = list(id = session_id, dataType = "GPS", format = "CSV"),
  timeout = 1800
)

download.file(session_export$downloadUrl, "session_gps.zip", mode = "wb")
unavailable <- session_export$unavailableParticipationIds
if (length(unavailable) > 0) {
  message(sprintf("%d athletes had no GPS data and were left out", length(unavailable)))
}
print(unzip("session_gps.zip", list = TRUE))

# To read one athlete's CSV straight from the zip without extracting it:
#   participation_id <- participation$id
#   con <- unz("session_gps.zip", file.path(participation_id, "gps.csv"))
#   gps <- read.csv(con)
