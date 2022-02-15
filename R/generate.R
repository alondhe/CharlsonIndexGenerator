
.getCharlsonScoringSql <- function() {
  scoring <- read.csv(system.file("csv/charlsonScoring.csv", package = "CharlsonIndexGenerator"), 
                      as.is = TRUE, stringsAsFactors = FALSE)
  sqls <- apply(scoring, 1, function(s) {
    sprintf("select %d as diag_category_id, %s as diag_category_name, %d as weight",
            as.integer(s[["diag_category_id"]][[1]]),
            s[["diag_category_name"]][[1]],
            as.integer(s[["weight"]][[1]]))
  })
  paste(sqls, collapse = "\n union all \n")
}

.getCharlsonConceptSql <- function() {
  concepts <- read.csv(system.file("csv/charlsonConcepts.csv", package = "CharlsonIndexGenerator"))
  sqls <- apply(concepts, 1, function(s) {
    sprintf("select %d as diag_category_id, %d as ancestor_concept_id",
            as.integer(s[["diag_category_id"]][[1]]),
            as.integer(s[["ancestor_concept_id"]][[1]]))
  })
  paste(sqls, collapse = "\n union all \n")
}


#' Get Charlson Index for a Drug cohort
#' 
#' @param connectionDetails       An R object of type\cr\code{connectionDetails} created using the function
#'                                \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema       The fully qualified name of the CDM schema
#' @param drugConceptIds          A list of drug concepts
#' @param sqlOnly                 Should we just export a SQL file, or actually run the query?
#' 
#' @export
getCharlsonForDrugCohort <- function(connectionDetails,
                                     cdmDatabaseSchema,
                                     drugConceptIds = c(),
                                     sqlOnly = FALSE) {
  
  charlsonScoringSql <- .getCharlsonScoringSql()
  charlsonConceptSql <- .getCharlsonConceptSql()
  
  cohortSql <- SqlRender::loadRenderTranslateSql(sqlFilename = "createDrugCohort.sql", 
                                                 packageName = "CharlsonIndexGenerator", 
                                                 dbms = "sql server",
                                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                                 drugConceptIds = paste(drugConceptIds, collapse = ","))
  charlsonSql <- SqlRender::loadRenderTranslateSql(sqlFilename = "computeCharlson.sql",
                                                   packageName = "CharlsonIndexGenerator", 
                                                   dbms = "sql server",
                                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                                   charlsonScoringSql = charlsonScoringSql,
                                                   charlsonConceptSql = charlsonConceptSql)
  finalSql <- SqlRender::loadRenderTranslateSql(sqlFilename = "finalQuery.sql", 
                                                packageName = "CharlsonIndexGenerator",
                                                dbms = connectionDetails$dbms,
                                                cohortSql = cohortSql,
                                                charlsonSql = charlsonSql)
  
  
  if (!sqlOnly) {
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    on.exit(DatabaseConnector::disconnect(connection = connection))
    result <- DatabaseConnector::querySql(connection = connection, sql = finalSql)
    return (result)
  }
  
  return (finalSql)
}

