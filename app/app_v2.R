#' Taktica v2.0 - Production-Ready Application
#'
#' Main Shiny application with modular architecture

# Load required packages
library(shiny)
library(shinydashboard)
library(plotly)
library(reactable)
library(dplyr)
library(arrow)
library(lubridate)
library(shinyWidgets)
library(logger)
library(config)
library(DT)

# Source modular components
source("../R/data_access.R")
source("../R/business_logic.R")
source("../R/ollama_integration.R")
source("../R/visualizations.R")
source("../R/ui_components.R")

# Initialize configuration and logging
Sys.setenv(R_CONFIG_ACTIVE = ifelse(Sys.getenv("R_CONFIG_ACTIVE") == "", "development", Sys.getenv("R_CONFIG_ACTIVE")))
cfg <- config::get()

# Setup logger
logger::log_threshold(cfg$logging$level)
logger::log_info("Starting Taktica application")

# Load data
projects_df <- load_projects()
team_members_df <- load_team_members()
allocations_df <- load_allocations()

logger::log_info(sprintf("Loaded %d projects, %d team members, %d allocations",
                        nrow(projects_df), nrow(team_members_df), nrow(allocations_df)))

# UI Definition
ui <- dashboardPage(
  skin = "blue",

  # Header
  dashboardHeader(
    title = "Taktica v2.0",
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        icon("question-circle"),
        "Help"
      )
    )
  ),

  # Sidebar
  dashboardSidebar(
    create_enhanced_sidebar(projects_df)
  ),

  # Body
  dashboardBody(
    # Custom CSS
    tags$head(
      tags$style(HTML("
        .small-box { cursor: pointer; }
        .badge { font-size: 12px; margin: 2px; }
        .alert { margin-top: 10px; }
        .reactable { font-size: 14px; }
        .sidebar-menu { font-size: 14px; }
      "))
    ),

    tabItems(
      # Dashboard Tab
      tabItem(
        tabName = "dashboard",
        h2("Dashboard Overview"),
        fluidRow(
          valueBoxOutput("util_box", width = 3),
          valueBoxOutput("proj_box", width = 3),
          valueBoxOutput("genai_box", width = 3),
          valueBoxOutput("team_box", width = 3)
        ),
        fluidRow(
          box(
            width = 12,
            title = "Key Insights",
            status = "info",
            solidHeader = TRUE,
            uiOutput("insights_panel")
          )
        ),
        fluidRow(
          box(
            width = 6,
            title = "Utilization Trend",
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("dashboard_util_trend", height = "300px")
          ),
          box(
            width = 6,
            title = "Project Distribution",
            status = "success",
            solidHeader = TRUE,
            plotlyOutput("dashboard_project_dist", height = "300px")
          )
        )
      ),

      # Projects Tab
      tabItem(
        tabName = "projects",
        h2("Project Management"),
        fluidRow(
          box(
            width = 12,
            title = "Current Projects",
            status = "primary",
            solidHeader = TRUE,
            actionButton("add_project_btn", "Add New Project", icon = icon("plus"), class = "btn-success"),
            actionButton("refresh_projects", "Refresh", icon = icon("sync")),
            downloadButton("export_projects", "Export to CSV", class = "btn-info"),
            tags$br(), tags$br(),
            reactableOutput("projects_table")
          )
        )
      ),

      # Timeline Tab (Gantt)
      tabItem(
        tabName = "timeline",
        h2("Project Timeline"),
        fluidRow(
          box(
            width = 12,
            title = "Gantt Chart",
            status = "info",
            solidHeader = TRUE,
            plotlyOutput("gantt_chart", height = "500px")
          )
        )
      ),

      # Team Tab
      tabItem(
        tabName = "team",
        h2("Team Management"),
        fluidRow(
          box(
            width = 6,
            title = "Team Members",
            status = "primary",
            solidHeader = TRUE,
            reactableOutput("team_table")
          ),
          box(
            width = 6,
            title = "Utilization by Member",
            status = "warning",
            solidHeader = TRUE,
            plotlyOutput("member_util_chart", height = "400px")
          )
        ),
        fluidRow(
          box(
            width = 12,
            title = "Utilization Heatmap",
            status = "info",
            solidHeader = TRUE,
            plotlyOutput("util_heatmap", height = "400px")
          )
        )
      ),

      # Capacity Tab
      tabItem(
        tabName = "capacity",
        h2("Capacity Management"),
        fluidRow(
          box(
            width = 12,
            title = "Weekly Capacity Allocation",
            status = "success",
            solidHeader = TRUE,
            plotlyOutput("capacity_plot", height = "400px")
          )
        ),
        fluidRow(
          box(
            width = 6,
            title = "Overallocated Members",
            status = "danger",
            solidHeader = TRUE,
            reactableOutput("overalloc_table")
          ),
          box(
            width = 6,
            title = "Underutilized Members",
            status = "warning",
            solidHeader = TRUE,
            reactableOutput("underutil_table")
          )
        )
      ),

      # Analytics Tab
      tabItem(
        tabName = "analytics",
        h2("Advanced Analytics"),
        fluidRow(
          box(
            width = 6,
            title = "Project Risk Analysis",
            status = "danger",
            solidHeader = TRUE,
            plotlyOutput("risk_chart", height = "400px")
          ),
          box(
            width = 6,
            title = "Average Duration by Category",
            status = "info",
            solidHeader = TRUE,
            plotlyOutput("duration_chart", height = "400px")
          )
        ),
        fluidRow(
          box(
            width = 12,
            title = "Workload Optimization Recommendations",
            status = "warning",
            solidHeader = TRUE,
            uiOutput("optimization_recommendations")
          )
        )
      ),

      # Forecast Tab
      tabItem(
        tabName = "forecast",
        h2("Capacity Forecasting"),
        fluidRow(
          box(
            width = 12,
            title = "Utilization Forecast (Next 4 Weeks)",
            status = "primary",
            solidHeader = TRUE,
            sliderInput("forecast_weeks", "Weeks to Forecast:", min = 1, max = 12, value = 4),
            actionButton("run_forecast", "Run Forecast", icon = icon("chart-line"), class = "btn-primary"),
            tags$br(), tags$br(),
            plotlyOutput("forecast_chart", height = "400px")
          )
        )
      ),

      # Reports Tab
      tabItem(
        tabName = "reports",
        h2("Reports & Export"),
        fluidRow(
          box(
            width = 6,
            title = "Generate Reports",
            status = "primary",
            solidHeader = TRUE,
            selectInput("report_type", "Report Type:", choices = c("Summary", "Detailed", "By Team Member", "By Project")),
            dateRangeInput("report_dates", "Date Range:", start = Sys.Date() - 30, end = Sys.Date()),
            downloadButton("download_report", "Download Report", class = "btn-success btn-lg")
          ),
          box(
            width = 6,
            title = "Quick Stats",
            status = "info",
            solidHeader = TRUE,
            verbatimTextOutput("quick_stats")
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  logger::log_info("Server session started")

  # Reactive data stores
  projects_r <- reactiveVal(projects_df)
  team_members_r <- reactiveVal(team_members_df)
  allocations_r <- reactiveVal(allocations_df)
  forecast_data_r <- reactiveVal(NULL)

  # Calculate KPIs reactively
  kpis <- reactive({
    calculate_kpi_summary(projects_r(), allocations_r(), team_members_r())
  })

  # Filtered projects
  filtered_projects <- reactive({
    df <- projects_r()

    if (input$filter_owner != "All") {
      df <- df %>% filter(Owner == input$filter_owner)
    }

    if (input$filter_category != "All") {
      df <- df %>% filter(Category == input$filter_category)
    }

    if (input$filter_status != "All") {
      df <- df %>% filter(Status == input$filter_status)
    }

    df
  })

  # === KPI VALUE BOXES ===
  output$util_box <- renderValueBox({
    valueBox(
      paste0(round(kpis()$team_utilization, 1), "%"),
      "Team Utilization",
      icon = icon("chart-pie"),
      color = if (kpis()$team_utilization > 95) "red" else if (kpis()$team_utilization > 80) "yellow" else "green"
    )
  })

  output$proj_box <- renderValueBox({
    valueBox(
      kpis()$active_projects,
      "Active Projects",
      icon = icon("tasks"),
      color = "blue"
    )
  })

  output$genai_box <- renderValueBox({
    valueBox(
      paste0(round(kpis()$genai_percentage, 1), "%"),
      "GenAI Projects",
      icon = icon("robot"),
      color = "purple"
    )
  })

  output$team_box <- renderValueBox({
    valueBox(
      kpis()$team_size,
      "Team Members",
      icon = icon("users"),
      color = "teal"
    )
  })

  # === INSIGHTS ===
  output$insights_panel <- renderUI({
    insights <- generate_insights(projects_r(), allocations_r(), team_members_r())
    create_insights_panel(insights)
  })

  # === VISUALIZATIONS ===
  output$dashboard_util_trend <- renderPlotly({
    create_utilization_trend(allocations_r(), team_members_r())
  })

  output$dashboard_project_dist <- renderPlotly({
    create_project_distribution(projects_r(), "Category")
  })

  output$projects_table <- renderReactable({
    reactable(
      filtered_projects() %>% select(Project, Owner, Category, Status, Start_Date, End_Date),
      filterable = TRUE,
      searchable = TRUE,
      highlight = TRUE,
      striped = TRUE,
      onClick = JS("function(rowInfo) { Shiny.setInputValue('selected_project_row', rowInfo.index + 1, {priority: 'event'}); }"),
      columns = list(
        Start_Date = colDef(format = colFormat(date = TRUE)),
        End_Date = colDef(format = colFormat(date = TRUE)),
        Status = colDef(cell = function(value) {
          as.character(create_status_badge(value))
        }, html = TRUE),
        Category = colDef(cell = function(value) {
          as.character(create_category_badge(value))
        }, html = TRUE)
      )
    )
  })

  output$gantt_chart <- renderPlotly({
    create_gantt_chart(filtered_projects())
  })

  output$team_table <- renderReactable({
    reactable(
      team_members_r() %>% select(Name, Role, Weekly_Capacity_Hours, Email, Active),
      striped = TRUE
    )
  })

  output$member_util_chart <- renderPlotly({
    util_by_member <- calculate_utilization_by_member(allocations_r(), team_members_r())

    plot_ly(
      data = util_by_member,
      x = ~reorder(Name, Utilization_Pct),
      y = ~Utilization_Pct,
      type = "bar",
      marker = list(
        color = ~ifelse(Utilization_Pct > 100, "red",
                       ifelse(Utilization_Pct > 80, "orange", "green"))
      ),
      text = ~paste0(Utilization_Pct, "%"),
      textposition = "outside"
    ) %>%
      layout(
        xaxis = list(title = "Team Member"),
        yaxis = list(title = "Utilization %"),
        title = ""
      )
  })

  output$util_heatmap <- renderPlotly({
    create_utilization_heatmap(allocations_r(), team_members_r())
  })

  output$capacity_plot <- renderPlotly({
    create_capacity_chart(allocations_r())
  })

  output$overalloc_table <- renderReactable({
    overalloc <- identify_overallocated(allocations_r(), team_members_r(), threshold = 1.0)
    reactable(overalloc, striped = TRUE)
  })

  output$underutil_table <- renderReactable({
    underutil <- identify_underutilized(allocations_r(), team_members_r(), threshold = 0.5)
    reactable(underutil, striped = TRUE)
  })

  output$risk_chart <- renderPlotly({
    create_risk_dashboard(projects_r(), allocations_r(), team_members_r())
  })

  output$duration_chart <- renderPlotly({
    duration_data <- calculate_avg_duration_by_category(projects_r())

    plot_ly(
      data = duration_data,
      x = ~Category,
      y = ~Avg_Duration_Days,
      type = "bar",
      text = ~paste0(Avg_Duration_Days, " days"),
      textposition = "outside"
    ) %>%
      layout(
        xaxis = list(title = "Category"),
        yaxis = list(title = "Average Duration (Days)")
      )
  })

  output$optimization_recommendations <- renderUI({
    opt <- optimize_allocation(allocations_r(), team_members_r(), projects_r())

    if (length(opt$recommendations) == 0) {
      return(tags$p("No optimization recommendations at this time.", style = "color: gray;"))
    }

    rec_items <- lapply(opt$recommendations, function(rec) {
      tags$div(
        class = "alert alert-info",
        icon("lightbulb"),
        " ",
        tags$strong("Recommendation: "),
        rec$reason,
        tags$br(),
        sprintf("Suggested: Move %d hours from %s to %s", rec$hours, rec$from, rec$to)
      )
    })

    tagList(rec_items)
  })

  output$forecast_chart <- renderPlotly({
    if (is.null(forecast_data_r())) {
      return(plotly::plot_ly() %>% layout(title = "Click 'Run Forecast' to generate predictions"))
    }

    historical <- calculate_utilization_trend(allocations_r(), team_members_r())
    create_forecast_chart(historical, forecast_data_r())
  })

  output$quick_stats <- renderText({
    k <- kpis()
    paste0(
      "Team Utilization: ", round(k$team_utilization, 1), "%\n",
      "Active Projects: ", k$active_projects, "\n",
      "Total Projects: ", k$total_projects, "\n",
      "Team Size: ", k$team_size, "\n",
      "Total Capacity: ", k$total_capacity, " hours/week\n",
      "GenAI Projects: ", round(k$genai_percentage, 1), "%\n",
      "ML Projects: ", round(k$ml_percentage, 1), "%\n",
      "Evaluation Projects: ", round(k$evaluation_percentage, 1), "%"
    )
  })

  # === AI ASSISTANT ===
  observeEvent(input$ask_ai, {
    req(input$ai_query)

    logger::log_info(sprintf("AI query: %s", input$ai_query))

    result <- handle_query(
      input$ai_query,
      projects_r(),
      allocations_r(),
      team_members_r(),
      use_ai = cfg$features$enable_ai
    )

    output$ai_response <- renderText({
      if (result$success) {
        result$response
      } else {
        paste0("[Error] ", result$response)
      }
    })
  })

  # === PROJECT CRUD OPERATIONS ===
  observeEvent(input$add_project_btn, {
    showModal(modalDialog(
      title = "Add New Project",
      create_project_form("new_", team_members = team_members_r()),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_add_project", "Add Project", icon = icon("plus"), class = "btn-success")
      )
    ))
  })

  observeEvent(input$confirm_add_project, {
    new_project <- list(
      Project = input$new_proj_name,
      Owner = input$new_proj_owner,
      Start_Date = input$new_proj_dates[1],
      End_Date = input$new_proj_dates[2],
      Category = input$new_proj_cat,
      Status = input$new_proj_status
    )

    result <- add_project(new_project, team_members_r(), user = session$user)

    if (result$success) {
      projects_r(load_projects())
      removeModal()
      showNotification("Project added successfully!", type = "message")
      logger::log_info(sprintf("Project added: %s", new_project$Project))
    } else {
      showNotification(result$message, type = "error")
    }
  })

  observeEvent(input$selected_project_row, {
    sel <- input$selected_project_row
    df <- filtered_projects()
    proj <- df[sel, ]

    showModal(modalDialog(
      title = paste("Edit Project:", proj$Project),
      create_project_form("edit_", project = proj, team_members = team_members_r()),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete_project", "Delete", icon = icon("trash"), class = "btn-danger"),
        actionButton("confirm_edit_project", "Save Changes", icon = icon("save"), class = "btn-primary")
      )
    ))

    session$userData$selected_project_name <- proj$Project
  })

  observeEvent(input$confirm_edit_project, {
    updated_project <- list(
      Project = input$edit_proj_name,
      Owner = input$edit_proj_owner,
      Start_Date = input$edit_proj_dates[1],
      End_Date = input$edit_proj_dates[2],
      Category = input$edit_proj_cat,
      Status = input$edit_proj_status
    )

    result <- update_project(
      session$userData$selected_project_name,
      updated_project,
      team_members_r(),
      user = session$user
    )

    if (result$success) {
      projects_r(load_projects())
      removeModal()
      showNotification("Project updated successfully!", type = "message")
    } else {
      showNotification(result$message, type = "error")
    }
  })

  observeEvent(input$confirm_delete_project, {
    showModal(create_confirmation_modal(
      "Confirm Deletion",
      paste("Are you sure you want to delete project:", session$userData$selected_project_name, "?"),
      "final_delete_confirm"
    ))
  })

  observeEvent(input$final_delete_confirm, {
    result <- delete_project(session$userData$selected_project_name, user = session$user)

    if (result$success) {
      projects_r(load_projects())
      removeModal()
      showNotification("Project deleted successfully!", type = "message")
    } else {
      showNotification(result$message, type = "error")
    }
  })

  # === FORECAST ===
  observeEvent(input$run_forecast, {
    withProgress(message = "Generating forecast...", value = 0.5, {
      forecast <- forecast_utilization(allocations_r(), team_members_r(), weeks_ahead = input$forecast_weeks)
      forecast_data_r(forecast)

      if (!is.null(forecast)) {
        showNotification("Forecast generated successfully!", type = "message")
      } else {
        showNotification("Insufficient data for forecasting (need at least 4 weeks)", type = "warning")
      }
    })
  })

  # === EXPORTS ===
  output$export_projects <- downloadHandler(
    filename = function() {
      paste0("taktica_projects_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      write.csv(projects_r(), file, row.names = FALSE)
    }
  )

  output$download_report <- downloadHandler(
    filename = function() {
      paste0("taktica_report_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      write.csv(kpis(), file, row.names = FALSE)
    }
  )

  observeEvent(input$refresh_projects, {
    projects_r(load_projects())
    showNotification("Data refreshed", type = "message")
  })

  # Cleanup
  session$onSessionEnded(function() {
    logger::log_info("Server session ended")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
