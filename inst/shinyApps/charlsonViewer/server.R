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
    allDrugConcepts[input$drugConceptIds_rows_selected,]
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
  
  charlsonResult <- reactive({
    if (nrow(selectedDrugConcepts()) > 0) {
      if (input$dbms == "eunomia") {
        connectionDetails <- Eunomia::getEunomiaConnectionDetails()
        cdmDatabaseSchema <- "main"
      } else {
        connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = input$dbms, 
                                                                        user = input$user,
                                                                        server = input$host, 
                                                                        port = input$port, 
                                                                        extraSettings = input$extraSettings,
                                                                        password = input$password)
        cdmDatabaseSchema <- input$cdmDatabaseSchema
      }
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
      charlsonResult <- CharlsonIndexGenerator::getCharlsonForDrugCohort(connectionDetails = connectionDetails,
                                                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                                                         drugConceptIds = selectedDrugConcepts()$CONCEPT_ID,
                                                                         sqlOnly = FALSE)
      
      charlsonResult |> dplyr::select(`Person Id` = SUBJECT_ID,
                                      `Cohort Start Date` = COHORT_START_DATE,
                                      `Cohort End Date` = COHORT_END_DATE,
                                      `Charlson Index` = COVARIATE_VALUE)
    }
  })
  
  output$drugConceptIds <- renderDataTable({
    df <- allDrugConcepts |>
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
    fig <- plotly::plot_ly(data = charlsonResult(), y = ~`Charlson Index`, type = "box")
    
    fig
  })
})