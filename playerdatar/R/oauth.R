#' OAuth 2 Authentication Functions
#'
#' Functions for obtaining OAuth 2 tokens using different grant types.
#'
#' @details
#' For authorization code flows, the \code{httpuv} package is recommended for better
#' OAuth callback handling. Install it with: \code{install.packages("httpuv")}

#' Get OAuth 2 token (client credentials flow)
#'
#' @param client_id OAuth 2 client ID
#' @param client_secret OAuth 2 client secret
#' @param token_url OAuth 2 token URL
#' @param token_file Path to file to store token
#'
#' @return OAuth token object
#' @export
get_oauth_token <- function(client_id, client_secret, token_url, token_file) {
  
  # Try to load existing token
  if (file.exists(token_file)) {
    tryCatch({
      token <- readRDS(token_file)
      # Check if token is still valid (simple check - could be improved)
      if (!is.null(token$expires_at) && Sys.time() < token$expires_at) {
        return(token)
      }
    }, error = function(e) {
      # If loading fails, get new token
    })
  }
  
  # Get new token
  response <- httr::POST(
    url = token_url,
    body = list(
      grant_type = "client_credentials",
      client_id = client_id,
      client_secret = client_secret
    ),
    encode = "form"
  )
  
  if (httr::status_code(response) != 200) {
    stop(paste("Failed to get OAuth token:", httr::content(response, "text")))
  }
  
  token_data <- httr::content(response, "parsed")
  
  # Calculate expiration time (default to 1 hour if not provided)
  expires_in <- if (is.null(token_data$expires_in)) 3600 else token_data$expires_in
  token <- list(
    access_token = token_data$access_token,
    token_type = if (is.null(token_data$token_type)) "Bearer" else token_data$token_type,
    expires_at = Sys.time() + expires_in,
    expires_in = expires_in
  )
  
  # Save token
  saveRDS(token, token_file)
  
  return(token)
}

#' Get OAuth 2 token using Authorization Code flow
#'
#' @param client_id OAuth 2 client ID
#' @param client_secret OAuth 2 client secret
#' @param authorize_url OAuth 2 authorization URL (default: https://app.playerdata.co.uk/oauth/authorize)
#' @param token_url OAuth 2 token URL (default: https://app.playerdata.co.uk/oauth/token)
#' @param token_file Path to file to store token (default: .token)
#' @param port Port for local callback server (default: 8080)
#' @param redirect_uri Redirect URI (default: http://localhost:port/callback)
#'
#' @return OAuth token object
#' @export
get_oauth_token_authorization_code <- function(client_id,
                                               client_secret,
                                               authorize_url = "https://app.playerdata.co.uk/oauth/authorize",
                                               token_url = "https://app.playerdata.co.uk/oauth/token",
                                               token_file = ".token",
                                               port = 8080,
                                               redirect_uri = NULL) {
  
  # Try to load existing token
  if (file.exists(token_file)) {
    tryCatch({
      token <- readRDS(token_file)
      if (!is.null(token$expires_at) && Sys.time() < token$expires_at) {
        return(token)
      }
    }, error = function(e) {
      # If loading fails, get new token
    })
  }
  
  # Set up redirect URI
  if (is.null(redirect_uri)) {
    redirect_uri <- paste0("http://localhost:", port, "/callback")
  }
  
  # Generate state for security
  state <- paste0(sample(c(letters, LETTERS, 0:9), 32, replace = TRUE), collapse = "")
  
  # Build authorization URL
  auth_url <- httr::modify_url(authorize_url, query = list(
    response_type = "code",
    client_id = client_id,
    redirect_uri = redirect_uri,
    state = state
  ))
  
  # Start local server
  if (requireNamespace("httpuv", quietly = TRUE)) {
    oauth_code_received <- FALSE
    oauth_code <- NULL
    
    # Create a closure that captures the variables
    callback_env <- environment()
    server <- httpuv::startServer("127.0.0.1", port, list(
      call = function(req) {
        query <- parseQueryString(req$QUERY_STRING)
        code <- query$code
        received_state <- query$state
        
        # Verify state
        if (!is.null(received_state) && received_state == state) {
          if (!is.null(code)) {
            assign("oauth_code", code, envir = callback_env)
            assign("oauth_code_received", TRUE, envir = callback_env)
            list(
              status = 200L,
              headers = list("Content-Type" = "text/html"),
              body = "<p>Success! Please return to the terminal</p>"
            )
          } else {
            list(
              status = 200L,
              headers = list("Content-Type" = "text/html"),
              body = "<p>Error: No authorization code received</p>"
            )
          }
        } else {
          list(
            status = 200L,
            headers = list("Content-Type" = "text/html"),
            body = "<p>Error: Invalid state parameter</p>"
          )
        }
      }
    ))
    
    # Open browser
    cat("Logging you into the GraphQL API\n")
    cat("If your browser does not open automatically, please go to:\n", auth_url, "\n")
    tryCatch({
      utils::browseURL(auth_url)
    }, error = function(e) {
      cat("Could not open browser automatically. Please visit the URL above.\n")
    })
    
    # Wait for callback (polling)
    timeout <- 300  # 5 minutes
    start_time <- Sys.time()
    while (!oauth_code_received && (Sys.time() - start_time) < timeout) {
      httpuv::service()
      Sys.sleep(0.1)
    }
    
    # Stop server
    httpuv::stopServer(server)
    
    if (!oauth_code_received || is.null(oauth_code)) {
      stop("Failed to receive authorization code. Please try again.")
    }
    
    code <- oauth_code
  } else {
    # Fallback: use oauth2.0_token from httr
    cat("Logging you into the GraphQL API\n")
    cat("Note: httpuv package recommended for better OAuth callback handling\n")
    
    app <- httr::oauth_app("playerdatar", key = client_id, secret = client_secret)
    endpoint <- httr::oauth_endpoint(
      authorize = authorize_url,
      access = token_url
    )
    
    token_obj <- httr::oauth2.0_token(
      endpoint = endpoint,
      app = app,
      cache = FALSE
    )
    
    # Convert token object to our format
    token_data <- list(
      access_token = token_obj$credentials$access_token,
      token_type = if (is.null(token_obj$credentials$token_type)) "Bearer" else token_obj$credentials$token_type,
      expires_at = if (!is.null(token_obj$credentials$expires_at)) {
        as.POSIXct(token_obj$credentials$expires_at, origin = "1970-01-01")
      } else {
        Sys.time() + 3600
      },
      expires_in = if (is.null(token_obj$credentials$expires_in)) 3600 else token_obj$credentials$expires_in
    )
    
    # Save token
    saveRDS(token_data, token_file)
    return(token_data)
  }
  
  # Exchange code for token
  response <- httr::POST(
    url = token_url,
    body = list(
      grant_type = "authorization_code",
      code = code,
      client_id = client_id,
      client_secret = client_secret,
      redirect_uri = redirect_uri
    ),
    encode = "form"
  )
  
  if (httr::status_code(response) != 200) {
    stop(paste("Failed to get OAuth token:", httr::content(response, "text")))
  }
  
  token_data <- httr::content(response, "parsed")
  
  # Calculate expiration time
  expires_in <- if (is.null(token_data$expires_in)) 3600 else token_data$expires_in
  token <- list(
    access_token = token_data$access_token,
    token_type = if (is.null(token_data$token_type)) "Bearer" else token_data$token_type,
    expires_at = Sys.time() + expires_in,
    expires_in = expires_in
  )
  
  # Save token
  saveRDS(token, token_file)
  
  cat("Login successful, token saved to file!\n")
  return(token)
}
