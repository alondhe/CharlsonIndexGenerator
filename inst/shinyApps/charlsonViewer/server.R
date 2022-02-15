library(shiny)
library(shinyjs)
library(shinyWidgets)
library(plotly)
library(DT)
library(shinydashboard)
library(shinycssloaders)

shinyServer(function(input, output, session) {
  
  switchPage <- function(i) {
    updateTabsetPanel(inputId = "wizard", selected = sprintf("page_%d", i))
  }
  
  selectedDrugConcepts <- reactive({
    allDrugConcepts()[input$drugConceptIds_rows_selected,]
  })
  
  cohortName <- reactive({
    sprintf("Patients exposed to: %s", paste(selectedDrugConcepts()$CONCEPT_NAME, collapse = ", "))
  })
  
  observe({
    fields <- c("host", "cdmDatabaseSchema", "port", "user", "password", "extraSettings")
    if (input$dbms == "eunomia") {
      for (field in fields) {
        shinyjs::disable(id = field)
      }
    } else {
      for (field in fields) {
        shinyjs::enable(id = field)
      }
    }
  })
  
  observe({
    if (nrow(selectedDrugConcepts()) > 0) {
      shinyjs::enable(id = "page_23")
    } else {
      shinyjs::disable(id = "page_23")
    }
  })
  
  observeEvent(input$page_23, {
    if (nrow(selectedDrugConcepts()) > 0) {
      switchPage(3)
    }
  })
  
  observeEvent(input$page_21, {
    switchPage(1)
  })
  
  observeEvent(input$page_12, {
    switchPage(2)
  })
  
  observeEvent(input$page_32, {
    switchPage(2)
  })
  
  theseConnectionDetails <- reactive({
    if (input$dbms == "eunomia") {
      connectionDetails <- Eunomia::getEunomiaConnectionDetails()
      cdmDatabaseSchema <- "main"
    } else {
      connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = input$dbms, 
                                                                      user = input$user,
                                                                      server = input$host, 
                                                                      port = input$port, 
                                                                      extraSettings = input$extraSettings,
                                                                      password = input$password, 
                                                                      pathToDriver = "www")
      cdmDatabaseSchema <- input$cdmDatabaseSchema
    }
    list(connectionDetails = connectionDetails,
         cdmDatabaseSchema = cdmDatabaseSchema)
  })
  
  allDrugConcepts <- reactive({
    connection <- DatabaseConnector::connect(connectionDetails = theseConnectionDetails()$connectionDetails)
    sql <- sprintf("select distinct concept_id, concept_name, concept_class_id
                    from %s.concept
                    where domain_id = 'Drug' and standard_concept = 'S' and invalid_reason is null", 
                   theseConnectionDetails()$cdmDatabaseSchema)
    allDrugConcepts <- DatabaseConnector::querySql(connection = connection, 
                                                   sql = sql)
    DatabaseConnector::disconnect(connection = connection)
    allDrugConcepts
  })
  
  charlsonResult <- reactive({
    if (nrow(selectedDrugConcepts()) > 0) {
      connection <- DatabaseConnector::connect(connectionDetails = theseConnectionDetails()$connectionDetails)
      charlsonResult <- CharlsonIndexGenerator::getCharlsonForDrugCohort(connectionDetails = theseConnectionDetails()$connectionDetails,
                                                                         cdmDatabaseSchema = theseConnectionDetails()$cdmDatabaseSchema,
                                                                         drugConceptIds = selectedDrugConcepts()$CONCEPT_ID,
                                                                         sqlOnly = FALSE)
      DatabaseConnector::disconnect(connection = connection)
      charlsonResult |> dplyr::select(`Person Id` = SUBJECT_ID,
                                      `Age` = AGE,
                                      `Cohort Start Date` = COHORT_START_DATE,
                                      `Cohort End Date` = COHORT_END_DATE,
                                      `Charlson Index` = COVARIATE_VALUE,
                                      `Charlson (age-adjusted)` = AGE_ADJUSTED_VALUE)
    }
  })
  
  output$drugConceptIds <- renderDataTable({
    df <- allDrugConcepts() |>
      dplyr::select(`Concept Id` = CONCEPT_ID,
                    `Concept Name` = CONCEPT_NAME,
                    `Concept Class Id` = CONCEPT_CLASS_ID)
    
    DT::datatable(.factorizeDf(df),
                  filter = "top",
                  style = "bootstrap4",
                  selection = "multiple",
                  rownames = FALSE,
                  class = "cell-border strip hover",
                  options = list(autoWidth = TRUE))
  }, server = FALSE)
  
  output$cohortRows <- renderDataTable({
    DT::datatable(charlsonResult(),
                  filter = "top",
                  style = "bootstrap4",
                  selection = "multiple",
                  rownames = FALSE,
                  class = "cell-border strip hover",
                  options = list(autoWidth = TRUE))
  })
  
  output$boxplot <- renderPlotly({
    fig <- plotly::plot_ly(data = charlsonResult(), y = ~`Charlson (age-adjusted)`, type = "box", name = "Charlson (age-adjusted)") |>
      plotly::add_trace(y = ~`Charlson Index`, name = "Charlson (unadjusted)")
    
    fig
  })
  
  output$charlsonScoring <- renderDataTable({
    df <- charlsonScoring |>
      dplyr::select(`Diagnosis Category Id` = diag_category_id,
                    `Diagnosis Category Name` = diag_category_name,
                    Weight = weight)
    
    DT::datatable(df,
                  filter = "top",
                  style = "bootstrap4",
                  selection = "multiple",
                  rownames = FALSE,
                  class = "cell-border strip hover",
                  options = list(autoWidth = TRUE))
  })
  
  output$charlsonConcepts <- renderDataTable({
    df <- charlsonConcepts |>
      dplyr::select(`Diagnosis Category Id` = diag_category_id,
                    `Ancestor Concept Id` = ancestor_concept_id)
    
    DT::datatable(df,
                  filter = "top",
                  style = "bootstrap4",
                  selection = "multiple",
                  rownames = FALSE,
                  class = "cell-border strip hover",
                  options = list(autoWidth = TRUE))
  })
  
  output$cohortMeta <- renderUI({
    div(h3(cohortName()))
  })
})