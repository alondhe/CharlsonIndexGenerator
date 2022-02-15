connectionDetails <- Eunomia::getEunomiaConnectionDetails()
connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
drugConceptIds <- c(1322184)
cdmDatabaseSchema <- "main"

result <- CharlsonIndexGenerator::getCharlsonForDrugCohort(connectionDetails = connectionDetails,
                                                           cdmDatabaseSchema = cdmDatabaseSchema, 
                                                           drugConceptIds = drugConceptIds,
                                                           sqlOnly = FALSE)

result <- CharlsonIndexGenerator::getCharlsonForDrugCohort(connectionDetails = list(dbms = "sql server"),
                                                           cdmDatabaseSchema = cdmDatabaseSchema, 
                                                           drugConceptIds = drugConceptIds,
                                                           sqlOnly = TRUE)

SqlRender::writeSql(sql = result, targetFile = "~/git/charlsonTest.sql")
