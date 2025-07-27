library(shiny)
library(shinydashboard)
library(plotly)
library(reactable)
library(dplyr)
library(arrow)
library(lubridate)
library(shinyWidgets)
library(httr)
library(jsonlite)

# Mock data
team_members <- tibble::tibble(
  Name = c("Akbar", "Amanda", "Steve", "Romina"),
  Role = c("Manager", "Senior DS", "Senior DS", "Junior DS"),
  Weekly_Capacity_Hours = c(20, 40, 40, 15)
)
initial_projects <- tibble::tibble(
  Project = c("HNI 360", "Readmission GenAI", "DUR Risk Flag"),
  Owner = c("Amanda", "Steve", "Akbar"),
  Start_Date = as.Date(c("2024-08-01", "2024-09-01", "2024-08-20")),
  End_Date = as.Date(c("2024-11-01", "2024-10-15", "2024-09-20")),
  Category = c("Evaluation", "GenAI", "ML"),
  Status = c("Active", "Active", "Active")
)
allocations <- tibble::tibble(
  Week = rep(seq(as.Date("2024-08-01"), by = "week", length.out = 6), each = 4),
  Name = rep(c("Akbar", "Amanda", "Steve", "Romina"), times = 6),
  Project = rep(c("DUR Risk Flag", "HNI 360", "Readmission GenAI", NA), times = 6),
  Hours_Allocated = c(10,30,35,0,10,30,35,0,10,30,35,0,10,30,35,0,10,30,35,0,10,30,35,0)
)

ui <- dashboardPage(
  dashboardHeader(title = "Taktica"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("tachometer-alt")),
      menuItem("Projects", tabName = "projects", icon = icon("tasks")),
      menuItem("Add Project", tabName = "add", icon = icon("plus")),
      menuItem("Capacity", tabName = "capacity", icon = icon("chart-bar")),
      menuItem("History", tabName = "history", icon = icon("history")),
      menuItem("Simulation", tabName = "simulate", icon = icon("cogs")),
      hr(),
      textInput("ask", "Ask Taktica", "What is our current project load?"),
      verbatimTextOutput("ollama_response"),
      selectInput("filter_owner", "Filter by Owner", choices = c("All", unique(initial_projects$Owner)), selected = "All"),
      selectInput("filter_category", "Filter by Category", choices = c("All", unique(initial_projects$Category)), selected = "All")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBoxOutput("util_box"),
                valueBoxOutput("proj_box"),
                valueBoxOutput("genai_box")
              )
      ),
      tabItem(tabName = "projects",
              fluidRow(
                box(width = 12, title = "Current Projects", status = "primary", solidHeader = TRUE,
                    reactableOutput("projects_table", height = "400px"))
              )
      ),
      tabItem(tabName = "add",
              fluidRow(
                box(width = 6, title = "New Project", status = "info", solidHeader = TRUE,
                    textInput("proj_name","Project Name"),
                    textInput("proj_owner","Owner"),
                    dateRangeInput("proj_dates","Timeline"),
                    selectInput("proj_cat","Category",choices=c("Evaluation","ML","GenAI","Shiny App")),
                    actionButton("add_project","Add Project", icon = icon("plus"))
                )
              )
      ),
      tabItem(tabName = "capacity",
              fluidRow(
                box(width = 12, title = "Weekly Capacity", status = "success", solidHeader = TRUE,
                    plotlyOutput("capacity_plot", height = "300px"))
              )
      ),
      tabItem(tabName = "history",
              fluidRow(
                box(width = 12, title = "Historical Allocations", status = "warning", solidHeader = TRUE,
                    reactableOutput("history_table", height = "400px"))
              )
      ),
      tabItem(tabName = "simulate",
              fluidRow(
                box(width = 6, title = "Capacity Simulation", status = "danger", solidHeader = TRUE,
                    sliderInput("extra_hours","Add Hours for Steve",min=0,max=40,value=10),
                    verbatimTextOutput("sim_output")
                )
              )
      )
    )
  )
)

server <- function(input, output, session) {
  # Reactive projects
  projects_r <- reactiveVal(initial_projects)
  
  # Ollama call
  output$ollama_response <- renderText({
    req(input$ask)
    res <- tryCatch({
      POST("http://localhost:11434/api/generate",
           body = toJSON(list(prompt = input$ask, model = "phi3")), encode = "json", timeout(5))
    }, error = function(e) NULL)
    if (is.null(res)) return("[Ollama offline]")
    content(res)$response
  })
  
  # KPIs
  output$util_box <- renderValueBox({
    alloc <- allocations
    util <- round(100 * sum(alloc$Hours_Allocated) / sum(team_members$Weekly_Capacity_Hours),1)
    valueBox(util, "Team Utilization (%)", icon = icon("chart-pie"))
  })
  output$proj_box <- renderValueBox({
    valueBox(nrow(projects_r()), "Active Projects", icon = icon("tasks"))
  })
  output$genai_box <- renderValueBox({
    pr <- projects_r()
    pct <- round(100 * sum(pr$Category=="GenAI")/nrow(pr),1)
    valueBox(pct, "% GenAI Projects", icon = icon("robot"))
  })
  
  # Filtered reactive
  filtered_projects <- reactive({
    df <- projects_r()
    if(input$filter_owner!="All") df <- df %>% filter(Owner==input$filter_owner)
    if(input$filter_category!="All") df <- df %>% filter(Category==input$filter_category)
    df
  })
  
  # Projects table with modal editing
  output$projects_table <- renderReactable({
    reactable(
      filtered_projects(),
      selection = "single",
      onClick = JS("function(rowInfo) { Shiny.setInputValue('selected_row', rowInfo.index + 1); }"),
      columns = list(
        Start_Date = colDef(cell = function(value) format(value, "%Y-%m-%d")),
        End_Date   = colDef(cell = function(value) format(value, "%Y-%m-%d"))
      )
    )
  })
  
  observeEvent(input$selected_row, {
    sel <- input$selected_row
    df <- filtered_projects()
    proj <- df[sel,]
    showModal(modalDialog(
      title = paste("Edit Project -", proj$Project),
      textInput("edit_name", "Project Name", value = proj$Project),
      textInput("edit_owner", "Owner", value = proj$Owner),
      dateRangeInput("edit_dates", "Timeline", start = proj$Start_Date, end = proj$End_Date),
      selectInput("edit_cat", "Category", choices = c("Evaluation","ML","GenAI","Shiny App"), selected = proj$Category),
      selectInput("edit_status", "Status", choices = c("Active","Completed","On Hold"), selected = proj$Status),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("save_edit", "Save Changes", icon = icon("save"))
      ),
      easyClose = TRUE
    ))
    
    # Store sel in session for saving
    session$userData$sel_index <- sel
  })
  
  observeEvent(input$save_edit, {
    sel <- isolate(session$userData$sel_index)
    pr <- projects_r()
    # Find project in full list by matching row
    full <- pr
    # Update full list at the correct position
    # Assuming unfiltered index maps directly
    row_idx <- which(pr$Project == filtered_projects()[sel,]$Project)
    full[row_idx,] <- tibble::tibble(
      Project = input$edit_name,
      Owner = input$edit_owner,
      Start_Date = input$edit_dates[1],
      End_Date = input$edit_dates[2],
      Category = input$edit_cat,
      Status = input$edit_status
    )
    projects_r(full)
    removeModal()
    showNotification("Project updated", type = "message")
  })
  
  # Add project
  observeEvent(input$add_project, {
    new <- tibble::tibble(
      Project = input$proj_name,
      Owner = input$proj_owner,
      Start_Date = input$proj_dates[1],
      End_Date = input$proj_dates[2],
      Category = input$proj_cat,
      Status = "Active"
    )
    projects_r(bind_rows(projects_r(), new))
    showNotification("Project added", type = "message")
  })
  
  # Capacity plot
  output$capacity_plot <- renderPlotly({
    weekly <- allocations %>% group_by(Week,Name) %>% summarise(Hours=sum(Hours_Allocated),.groups="drop")
    plot_ly(weekly, x=~Week, y=~Hours, color=~Name, type="bar")
  })
  
  # History table
  output$history_table <- renderReactable({
    hist <- allocations %>% group_by(Name,Week) %>% summarise(Hours=sum(Hours_Allocated),.groups="drop")
    reactable(hist)
  })
  
  # Simulation
  output$sim_output <- renderText({ paste("Steve's new capacity:", 40 + input$extra_hours) })
}

shinyApp(ui, server)
