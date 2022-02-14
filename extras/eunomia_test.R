connectionDetails <- Eunomia::getEunomiaConnectionDetails()
connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
drugConceptIds <- c(1322184)
cdmDatabaseSchema <- "main"
CharlsonIndexGenerator::getCharlsonForDrugCohort(connectionDetails = connectionDetails,
                                                 cdmDatabaseSchema = cdmDatabaseSchema, 
                                                 cohortName = "Clopidogrel", drugConceptIds = drugConceptIds)
