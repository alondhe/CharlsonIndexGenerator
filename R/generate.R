

#' Generate a Drug Cohort
#' 
#' @param connectionDetails       An R object of type\cr\code{connectionDetails} created using the function
#'                                \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema       The fully qualified name of the CDM schema
#' @param resultsDatabaseSchema   The fully qualified name of the Results schema to store the cohort
#' @param drugConceptIds          A list of drug concepts
#' 
#' @export
generateDrugCohort <- function(connectionDetails,
                               cdmDatabaseSchema,
                               resultsDatabaseSchema,
                               drugConceptIds = c()) {
  
}


generateCohortAndCharlson <- function(connectionDetails,
                                      cdmDatabaseSchema,
                                      drugConceptIds = c()) {
  
}