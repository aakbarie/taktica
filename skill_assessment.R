# apps/skill_assessment/app.R

library(shiny)
library(shinydashboard)
library(arrow)
library(purrr)
library(plotly)
library(jsonlite)
library(mall)

# mall_config.R
llm_use(backend = "ollama", model = "llama3.2", temperature = 0.2)

load_user_history <- function(user_id) {
  files <- list.files("data/assessments", full.names = TRUE, pattern = "\\.parquet$")
  df_all <- purrr::map_dfr(files, function(f) {
    tryCatch(read_parquet(f), error = function(e) NULL)
  })
  df_user <- dplyr::filter(df_all, user_id == !!user_id)
  return(df_user)
}


source("modules/question_module.R")
source("logic/save_assessment.R")
# source("logic/mall_agent.R")
source("logic/generate_gap_plan.R")

# Load question metadata
questions_df <- read_parquet("/ai/aesfahani/projects/InsightHub/data/reference/skill_assessment_questions.parquet")
questions <- transpose(questions_df)



ui <- dashboardPage(
  dashboardHeader(title = "Skill Assessment"),
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Assessment", tabName = "assessment", icon = icon("clipboard")),
      menuItem("Progress", tabName = "progress", icon = icon("chart-line"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName = "assessment",
        fluidRow(valueBoxOutput("progress_box", width = 12)),
        uiOutput("welcome_ui"),
        uiOutput("question_ui"),
        uiOutput("submit_ui")
      ),
      tabItem(
        tabName = "progress",
        fluidRow(
          h3("Your Skill Assessment Summary")
        ),
        
        fluidRow(
          box(
            width = 7,
            title = "Assessment Results",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            uiOutput("cycle_selector"),
            div(
              style = "overflow-x: auto;",
              DT::dataTableOutput("progress_table", height = "600px") %>% 
                shinycssloaders::withSpinner(color = "#337ab7")
            )
          ),
          box(
            width = 5,
            ttitle = "Skill Trends Over Time",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            div(
              style = "overflow-x: auto;",
              plotlyOutput("progress_plot", height = "600px") %>% 
                shinycssloaders::withSpinner(color = "#337ab7")
            )
          )
        ),

        fluidRow(
          box(
            width = 12,
            title = "Download Your Learning Plan",
            status = "success",
            solidHeader = TRUE,
            downloadButton("download_plan", "Download Learning Plan")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "🧠 Recursive Summary & Learning Plan",
            status = "warning",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,   # <--- this makes it start collapsed
            verbatimTextOutput("llm_output")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  gap_text <- reactiveVal(NULL)
 
  
  response_store <- reactiveValues(
    answers = list(),
    current = 1
  )
  
  # User info collection
  user_info <- reactiveValues(name = NULL, position = NULL, submitted = FALSE)
  
  user_registry <- read_parquet("/ai/aesfahani/projects/InsightHub/data/reference/users.parquet")
  
  output$welcome_ui <- renderUI({
    if (!user_info$submitted) {
      box(
        title = "Welcome to the Skill Assessment",
        width = 12, status = "info", solidHeader = TRUE,
        selectInput("selected_user", "Select your name", choices = setNames(user_registry$user_id, user_registry$name)),
        actionButton("start_assessment", "Start Assessment", class = "btn-primary")
      )
    }
  })
  
  output$question_ui <- renderUI({
    if (response_store$current <= nrow(questions_df)) {
      question_module_ui(paste0("q", response_store$current))
    }
  })
  
  observe({
    if (user_info$submitted && response_store$current <= nrow(questions_df)) {
      question_module_server(
        paste0("q", response_store$current),
        question = questions[[response_store$current]],
        response_store = response_store
      )
      
    }
  })
  
  output$submit_ui <- renderUI({
    if (response_store$current > nrow(questions_df)) {
      actionButton("submit_btn", "Submit Assessment")
    }
  })
  
  observeEvent(input$submit_btn, {
    message("📥 Submit clicked by: ", user_info$name)
    
    save_assessment_parquet(
      responses = response_store$answers,
      user_id = user_info$user_id,
      user_name = user_info$name,
      user_position = user_info$position
    )
    
    gap_output <- generate_gap_plan(
      user_id = user_info$user_id,
      user_name = user_info$name,
      user_position = user_info$position
    )
    
    gap_text(gap_output)  # ✅ Store the result once it's available
    
    # Don't use gap_output directly anymore — always use gap_text()
    
    output$llm_output <- renderText({
      gap_output
    })
    
    plan_path <- file.path(
      "data/learning_plans",
      paste0(user_info$user_id, "_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
    )
    dir.create("data/learning_plans", showWarnings = FALSE, recursive = TRUE)
    writeLines(gap_output, con = plan_path)
    
    showModal(modalDialog("✅ Assessment submitted and saved successfully!", easyClose = TRUE))
    message("📦 GAP Output Preview: ", substr(gap_output, 1, 200))
    
  })
  
  output$progress_box <- renderValueBox({
    n_total <- nrow(questions_df)
    n_current <- min(response_store$current, n_total)
    
    valueBox(
      value = paste0("Question ", n_current, " of ", n_total),
      subtitle = "Progress",
      icon = icon("list-ol"),
      color = "purple",
      width = 12
    )
  })
  
  observeEvent(input$start_assessment, {
    selected <- input$selected_user
    
    if (!is.null(selected) && selected != "") {
      user_info$user_id <- selected
      user_info$name <- user_registry$name[user_registry$user_id == selected]
      user_info$position <- user_registry$position[user_registry$user_id == selected]
      user_info$submitted <- TRUE
    } else {
      showModal(modalDialog(
        title = "Missing Info",
        "Please select your name from the list.",
        easyClose = TRUE
      ))
    }
  })
  
  
  output$progress_table <- DT::renderDataTable({
    if (length(response_store$answers) > 0) {
      df <- dplyr::bind_rows(response_store$answers) %>%
        dplyr::select(area, text, score, comment)
      DT::datatable(df, options = list(pageLength = 10), rownames = FALSE)
    }
  })
  
  output$cycle_selector <- renderUI({
    req(user_info$user_id)
    df <- load_user_history(user_info$user_id)
    
    if (nrow(df) > 0) {
      choices <- unique(df$cycle_id)
      names(choices) <- format(as.POSIXct(df$timestamp[match(choices, df$cycle_id)]), "%Y-%m-%d %H:%M:%S")
      selectInput("selected_cycle", "Choose an assessment to view:", choices = choices)
    }
  })
  
  output$progress_table <- DT::renderDataTable({
    req(user_info$user_id, input$selected_cycle)
    df <- load_user_history(user_info$user_id)
    df <- dplyr::filter(df, cycle_id == input$selected_cycle)
    df <- dplyr::select(df, area, text, score, comment, timestamp)
    DT::datatable(df, options = list(pageLength = 10), rownames = FALSE)
  })
  
  output$progress_plot <- renderPlotly({
    req(user_info$user_id, input$selected_cycle)
    
    df <- load_user_history(user_info$user_id)
    df <- dplyr::filter(df, cycle_id == input$selected_cycle)
    
    if (nrow(df) == 0) return(NULL)
    
    baseline_scores <- c(
      "Programming" = 4,
      "Data Management" = 4,
      "SQL & Querying" = 4,
      "Version Control" = 4,
      "Modeling - Predictive" = 4,
      "Modeling - Advanced" = 3,
      "Model Ops" = 3,
      "Model Monitoring" = 3,
      "Visualization" = 3,
      "Dashboards" = 3,
      "Storytelling" = 4,
      "Strategic Framing" = 4,
      "Ethics & Fairness" = 4,
      "Governance" = 4,
      "Team Collaboration" = 4,
      "Documentation" = 3,
      "Tools & Infra" = 3,
      "Learning & Growth" = 5
    )
    
    avg_scores <- df %>%
      dplyr::group_by(area) %>%
      dplyr::summarise(avg = mean(score), .groups = "drop") %>%
      dplyr::filter(area %in% names(baseline_scores))
    
    categories <- names(baseline_scores)
    current_vec <- avg_scores$avg[match(categories, avg_scores$area)]
    target_vec <- baseline_scores[categories]
    
    plot_ly(type = 'scatterpolar', mode = 'lines+markers', fill = 'toself') %>%
      add_trace(r = current_vec, theta = categories, name = "Current Scores",
                mode = "lines+markers", marker = list(color = 'steelblue'),
                line = list(color = 'steelblue')) %>%
      add_trace(r = target_vec, theta = categories, name = "Expected Scores",
                mode = "lines+markers", marker = list(color = 'darkgreen'),
                line = list(color = 'darkgreen', dash = 'dash')) %>%
      layout(
        polar = list(radialaxis = list(visible = TRUE, range = c(0, 5))),
        showlegend = TRUE,
        margin = list(l = 40, r = 40, b = 20, t = 40),
        dragmode = "zoom",   # ⭐️ Added this!
        hovermode = "closest"
      )
  })
  
  output$download_plan <- downloadHandler(
    filename = function() {
      paste0("learning_plan_", user_info$user_id, "_", format(Sys.time(), "%Y%m%d"), ".txt")
    },
    content = function(file) {
      text <- isolate(gap_text())  # Wait for final value
      if (is.null(text) || text == "") {
        text <- "⚠️ Learning plan not yet generated. Please submit your assessment."
      }
      writeLines(text, con = file)
    }
  )
  
}

shinyApp(ui, server)
