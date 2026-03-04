#' GraphQL Operations
#'
#' Functions for executing GraphQL queries and mutations.

#' Execute a GraphQL query
#'
#' @param client GraphQL client object from create_gql_client
#' @param query GraphQL query string
#' @param query_name Name for the query (default: "query")
#' @param variables Optional variables list
#'
#' @return Query result
#' @export
execute_query <- function(client, query, query_name = "query", variables = NULL) {
  
  # Refresh token if needed
  if (is.null(client$token$expires_at) || Sys.time() >= client$token$expires_at) {
    refresh_client_token(client)
  }
  
  # Create query object
  qry <- ghql::Query$new()
  qry$query(query_name, query)
  
  # Execute query (use the client's exec method)
  # Pass variables directly to exec if provided (as second positional argument)
  if (!is.null(variables)) {
    result <- client$client$exec(qry$queries[[query_name]], variables)
  } else {
    result <- client$client$exec(qry$queries[[query_name]])
  }
  
  return(result)
}

#' Execute a GraphQL mutation
#'
#' @param client GraphQL client object from create_gql_client
#' @param mutation GraphQL mutation string
#' @param mutation_name Name for the mutation (default: "mutation")
#' @param variables Optional variables list
#'
#' @return Mutation result
#' @export
execute_mutation <- function(client, mutation, mutation_name = "mutation", variables = NULL) {
  
  # Refresh token if needed
  if (is.null(client$token$expires_at) || Sys.time() >= client$token$expires_at) {
    refresh_client_token(client)
  }
  
  # Create mutation object
  qry <- ghql::Query$new()
  qry$query(mutation_name, mutation)
  
  # Execute mutation (use the client's exec method)
  # Pass variables directly to exec if provided (as second positional argument)
  if (!is.null(variables)) {
    result <- client$client$exec(qry$queries[[mutation_name]], variables)
  } else {
    result <- client$client$exec(qry$queries[[mutation_name]])
  }
  
  return(result)
}
