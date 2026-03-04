#' GraphQL Client Creation and Management
#'
#' Functions for creating and managing GraphQL clients with OAuth 2 authentication.

#' Create a GraphQL client with OAuth 2 authentication
#'
#' @param client_id OAuth 2 client ID
#' @param client_secret OAuth 2 client secret (required for client_credentials and authorization_code flows)
#' @param grant_type OAuth 2 grant type: "client_credentials" (default) or "authorization_code"
#' @param url GraphQL endpoint URL (default: https://app.playerdata.co.uk/api/graphql)
#' @param token_url OAuth 2 token URL (default: https://app.playerdata.co.uk/oauth/token)
#' @param authorize_url OAuth 2 authorization URL (default: https://app.playerdata.co.uk/oauth/authorize)
#' @param token_file Path to file to store token (default: .token)
#' @param port Port for local callback server for authorization code flows (default: 8080)
#' @param redirect_uri Redirect URI for authorization code flows (default: http://localhost:port/callback)
#'
#' @return A GraphQL client object
#' @export
create_gql_client <- function(client_id, 
                             client_secret = NULL,
                             grant_type = "client_credentials",
                             url = "https://app.playerdata.co.uk/api/graphql",
                             token_url = "https://app.playerdata.co.uk/oauth/token",
                             authorize_url = "https://app.playerdata.co.uk/oauth/authorize",
                             token_file = ".token",
                             port = 8080,
                             redirect_uri = NULL) {
  
  # Get or refresh OAuth token based on grant type
  if (grant_type == "client_credentials") {
    if (is.null(client_secret)) {
      stop("client_secret is required for client_credentials grant type, update using client_secret = 'your-client-secret'")
    }
    token <- get_oauth_token(client_id, client_secret, token_url, token_file)
  } else if (grant_type == "authorization_code") {
    if (is.null(client_secret)) {
      stop("client_secret is required for authorization_code grant type, update using client_secret = 'your-client-secret'")
    }
    token <- get_oauth_token_authorization_code(
      client_id, client_secret, authorize_url, token_url, token_file, port, redirect_uri
    )
  } else {
    stop(paste("Unsupported grant_type:", grant_type))
  }
  
  # Create ghql client with authentication header
  ghql_client <- ghql::GraphqlClient$new(
    url = url,
    headers = list(
      Authorization = paste("Bearer", token$access_token),
      "Content-Type" = "application/json"
    )
  )
  
  # Create wrapper list to store client and metadata
  # (GraphqlClient has a locked environment, so we can't modify it directly)
  con <- list(
    client = ghql_client,
    client_id = client_id,
    client_secret = client_secret,
    grant_type = grant_type,
    token_url = token_url,
    authorize_url = authorize_url,
    token_file = token_file,
    port = port,
    redirect_uri = redirect_uri,
    token = token
  )
  
  # Add methods to delegate to the ghql client for convenience
  # Use a closure to properly capture the ghql_client reference
  con$exec <- function(...) con$client$exec(...)
  
  # Set class for better object-oriented behavior
  class(con) <- "gql_client"
  
  return(con)
}

#' Refresh the OAuth token for a client
#'
#' @param client GraphQL client object
#' @export
refresh_client_token <- function(client) {
  grant_type <- if (is.null(client$grant_type)) "client_credentials" else client$grant_type
  
  if (grant_type == "client_credentials") {
    client$token <- get_oauth_token(
      client$client_id,
      client$client_secret,
      client$token_url,
      client$token_file
    )
  } else if (grant_type == "authorization_code") {
    authorize_url <- if (is.null(client$authorize_url)) "https://app.playerdata.co.uk/oauth/authorize" else client$authorize_url
    port <- if (is.null(client$port)) 8080 else client$port
    client$token <- get_oauth_token_authorization_code(
      client$client_id,
      client$client_secret,
      authorize_url,
      client$token_url,
      client$token_file,
      port,
      client$redirect_uri
    )
  } else {
    stop(paste("Unsupported grant_type:", grant_type))
  }
  
  # Update headers in the ghql client
  client$client$headers$Authorization <- paste("Bearer", client$token$access_token)
}
