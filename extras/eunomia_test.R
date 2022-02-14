connectionDetails <- Eunomia::getEunomiaConnectionDetails()
connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
drugConceptIds <- c(1322184)
cdmDatabaseSchema <- "main"
pathToSqlFile <- "~/"
sqlOnly <- FALSE
result <- CharlsonIndexGenerator::getCharlsonForDrugCohort(connectionDetails = connectionDetails,
                                                           cdmDatabaseSchema = cdmDatabaseSchema, 
                                                           cohortName = "Clopidogrel", 
                                                           pathToSqlFile = pathToSqlFile,
                                                           drugConceptIds = drugConceptIds,
                                                           sqlOnly = sqlOnly)
