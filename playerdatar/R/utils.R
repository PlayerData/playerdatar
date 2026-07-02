#' Utility Functions
#'

#' Parse query string from URL
#'
#' @param query_string Query string (e.g., "code=abc&state=xyz")
#'
#' @return Named list of query parameters
parseQueryString <- function(query_string) {
  if (is.null(query_string) || query_string == "") {
    return(list())
  }
  params <- strsplit(query_string, "&")[[1]]
  result <- list()
  for (param in params) {
    parts <- strsplit(param, "=")[[1]]
    if (length(parts) == 2) {
      key <- utils::URLdecode(parts[1])
      value <- utils::URLdecode(parts[2])
      result[[key]] <- value
    }
  }
  return(result)
}
