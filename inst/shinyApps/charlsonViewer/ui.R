library(shiny)
library(shinyjs)
library(shinyWidgets)
library(plotly)
library(DT)
library(shinydashboard)
library(shinycssloaders)
library(magrittr)

ui <- dashboardPage(
  dashboardHeader(title = "CharlsonViewer", titleWidth = "250px",
                  dropdownMenuOutput(outputId = "tasksDropdown"),
                  tags$li(a(href = "http://www.ohdsi.org", target = "_blank",
                            img(src = "ohdsi_logo_mini.png",
                                title = "OHDSI", height = "30px"),
                            style = "padding-top:10px; padding-bottom:10px;"),
                          class = "dropdown")),
  dashboardSidebar(width = "250px",
                   sidebarMenu(
                     id = "tabs",
                     menuItem(text = "Introduction", tabName = "intro", selected = TRUE, icon = icon("info")),
                     menuItem(text = "Generate Charlson Results", tabName = "charlson", icon = icon("prescription"))
                   )
  ),
  dashboardBody(
    shinyjs::useShinyjs(),
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")),
    tabItems(
      tabItem("intro",
              box(width = 12,
                  title = "Introduction",
                  p(charlsonIntro),
                  p(appIntro)),
              box(width = 12, title = "References",
                  tags$ol(
                    lapply(references, function(r) {
                      tags$li(r)
                    }))
              )
      ),
      tabItem("charlson",
              tabsetPanel(id = "wizard", type = "hidden",
                          tabPanel("page_1",
                                   box(width = 12,
                                       title = "Configure Connection",
                                       selectizeInput(inputId = "dbms", label = "DBMS", 
                                                      choices = dbmsChoices),
                                       textInput(inputId = "cdmDatabaseSchema", label = "CDM Database Schema"),
                                       textInput(inputId = "host", label = "Host URL", width = "100%"),
                                       textInput(inputId = "user", label = "User Name", width = "100%"),
                                       textInput(inputId = "port", label = "Port", width = "100%"),
                                       textInput(inputId = "extraSettings", label = "Extra Settings", width = "100%"),
                                       passwordInput(inputId = "password", label = "Password", value = "", width = NULL, placeholder = NULL)
                                   ),
                                   box(width = 12,
                                       actionButton(inputId = "page_12", label = "Next: Select Drug Concepts"))
                          ),
                          tabPanel("page_2",
                                   box(width = 12,
                                       title = "Select Drug Concepts for Cohort",
                                       DT::dataTableOutput(outputId = "drugConceptIds") |> 
                                        shinycssloaders::withSpinner()),
                                   box(width = 12,
                                       actionButton(inputId = "page_21", label = "Previous: Configure Connection"),
                                       actionButton(inputId = "page_23", label = "Next: View Charlson Results"))
                          ),
                          tabPanel("page_3",
                                   box(width = 12,
                                       uiOutput(outputId = "cohortMeta")),
                                   box(width = 6,
                                       plotlyOutput(outputId = "boxplot") |> 
                                         shinycssloaders::withSpinner()),
                                   box(width = 6,
                                       DT::dataTableOutput(outputId = "cohortRows") |> 
                                         shinycssloaders::withSpinner()),
                                   box(width = 12,
                                       actionButton(inputId = "page_32", label = "Previous: Select Drug Concepts"))
                          )
              )
      )
    )
  )
)