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
    if (nrow(selectedDrugConcepts() == 0)) {
      shinyjs::disable(id = "page_23")
    } else {
      shinyjs::enable(id = "page_23")
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
  
  observeEvent(input$page_23, {
    switchPage(3)
  })
  
  observeEvent(input$page_12, {
    switchPage(2)
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
})