#' Ollama AI Integration for Taktica
#'
#' Provides intelligent query capabilities using Ollama with real data context
#' @importFrom httr POST content timeout add_headers
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom logger log_info log_error log_warn
#' @importFrom glue glue

#' Get Ollama configuration from config
get_ollama_config <- function() {
  config <- config::get()
  list(
    url = config$ollama$url,
    model = config$ollama$model,
    timeout = config$ollama$timeout,
    enabled = config$features$enable_ai
  )
}

#' Build context string from current data
#' @param projects Current projects data
#' @param allocations Current allocations data
#' @param team_members Current team members data
#' @param kpis Current KPIs
#' @export
build_data_context <- function(projects, allocations, team_members, kpis = NULL) {
  # Calculate KPIs if not provided
  if (is.null(kpis)) {
    kpis <- calculate_kpi_summary(projects, allocations, team_members)
  }

  # Build context string
  context <- glue::glue("
Current Team Status:
- Team Size: {kpis$team_size} members
- Total Weekly Capacity: {kpis$total_capacity} hours
- Current Utilization: {round(kpis$team_utilization, 1)}%
- Active Projects: {kpis$active_projects}
- Total Projects: {kpis$total_projects}

Project Breakdown:
- GenAI Projects: {round(kpis$genai_percentage, 1)}%
- ML Projects: {round(kpis$ml_percentage, 1)}%
- Evaluation Projects: {round(kpis$evaluation_percentage, 1)}%

Team Members:
{paste(team_members$Name, '-', team_members$Role, '(', team_members$Weekly_Capacity_Hours, 'hrs/week)', collapse = '\n')}

Active Projects:
{paste(projects$Project[projects$Status == 'Active'], '-', 'Owner:', projects$Owner[projects$Status == 'Active'], '|', projects$Category[projects$Status == 'Active'], collapse = '\n')}
  ")

  as.character(context)
}

#' Query Ollama with data context
#' @param query User's natural language query
#' @param projects Projects data
#' @param allocations Allocations data
#' @param team_members Team members data
#' @param kpis Optional pre-calculated KPIs
#' @export
query_ollama <- function(query, projects, allocations, team_members, kpis = NULL) {
  cfg <- get_ollama_config()

  if (!cfg$enabled) {
    logger::log_info("AI features disabled in configuration")
    return(list(
      success = FALSE,
      response = "AI features are currently disabled.",
      offline = FALSE
    ))
  }

  # Build context
  context <- build_data_context(projects, allocations, team_members, kpis)

  # Create enhanced prompt
  full_prompt <- glue::glue("
You are Taktica, an AI assistant for project and resource management. You have access to real-time team data.

CONTEXT:
{context}

USER QUESTION: {query}

Provide a concise, data-driven answer based on the context above. Include specific numbers and names when relevant.
  ")

  # Call Ollama API
  result <- call_ollama_api(
    prompt = as.character(full_prompt),
    model = cfg$model,
    url = cfg$url,
    timeout = cfg$timeout
  )

  result
}

#' Call Ollama API directly
#' @param prompt The prompt to send
#' @param model Model name to use
#' @param url Ollama API URL
#' @param timeout Request timeout in seconds
#' @export
call_ollama_api <- function(prompt, model = "phi3", url = "http://localhost:11434",
                            timeout = 10) {
  endpoint <- paste0(url, "/api/generate")

  body <- list(
    model = model,
    prompt = prompt,
    stream = FALSE
  )

  tryCatch({
    logger::log_info("Calling Ollama API")

    response <- httr::POST(
      endpoint,
      body = jsonlite::toJSON(body, auto_unbox = TRUE),
      encode = "json",
      httr::timeout(timeout),
      httr::add_headers("Content-Type" = "application/json")
    )

    if (response$status_code == 200) {
      content <- httr::content(response, as = "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(content)

      logger::log_info("Ollama API call successful")

      return(list(
        success = TRUE,
        response = parsed$response,
        model = parsed$model,
        offline = FALSE
      ))
    } else {
      logger::log_warn(sprintf("Ollama API returned status %d", response$status_code))
      return(list(
        success = FALSE,
        response = sprintf("Ollama API error: Status %d", response$status_code),
        offline = FALSE
      ))
    }

  }, error = function(e) {
    logger::log_error(sprintf("Ollama API call failed: %s", e$message))

    # Check if it's a connection error (Ollama offline)
    if (grepl("connect|timeout|resolve", e$message, ignore.case = TRUE)) {
      return(list(
        success = FALSE,
        response = "[Ollama offline - Please ensure Ollama is running]",
        offline = TRUE
      ))
    }

    return(list(
      success = FALSE,
      response = sprintf("Error: %s", e$message),
      offline = FALSE
    ))
  })
}

#' Get smart query suggestions based on current data
#' @param projects Projects data
#' @param allocations Allocations data
#' @param team_members Team members data
#' @export
get_query_suggestions <- function(projects, allocations, team_members) {
  suggestions <- c(
    "What is our current project load?",
    "Who is overallocated this week?",
    "Which projects are at risk?",
    "What's our team utilization?",
    "How many GenAI projects do we have?"
  )

  # Add dynamic suggestions based on data
  if (nrow(projects) > 0) {
    active_projects <- projects$Project[projects$Status == "Active"]
    if (length(active_projects) > 0) {
      suggestions <- c(suggestions,
                      sprintf("Tell me about project %s", active_projects[1]))
    }
  }

  # Check for overallocations
  overalloc <- identify_overallocated(allocations, team_members, threshold = 1.0)
  if (nrow(overalloc) > 0) {
    suggestions <- c(suggestions,
                    "How can we rebalance the workload?")
  }

  suggestions
}

#' Analyze query intent and route to appropriate function
#' @param query User query
#' @param projects Projects data
#' @param allocations Allocations data
#' @param team_members Team members data
#' @export
analyze_query_intent <- function(query, projects, allocations, team_members) {
  query_lower <- tolower(query)

  # Detect query type
  intent <- list(
    type = "general",
    requires_calculation = FALSE,
    specific_metric = NULL
  )

  # Utilization queries
  if (grepl("utilization|capacity|workload", query_lower)) {
    intent$type <- "utilization"
    intent$requires_calculation <- TRUE
    intent$specific_metric <- "utilization"
  }

  # Project count queries
  if (grepl("how many|count|number of.*project", query_lower)) {
    intent$type <- "project_count"
    intent$requires_calculation <- TRUE
    intent$specific_metric <- "project_count"
  }

  # Risk queries
  if (grepl("risk|overdue|deadline|delay", query_lower)) {
    intent$type <- "risk"
    intent$requires_calculation <- TRUE
    intent$specific_metric <- "risk"
  }

  # Overallocation queries
  if (grepl("overallocate|over-allocate|too much work|overwork", query_lower)) {
    intent$type <- "overallocation"
    intent$requires_calculation <- TRUE
    intent$specific_metric <- "allocation"
  }

  # Specific team member queries
  team_names <- team_members$Name
  for (name in team_names) {
    if (grepl(tolower(name), query_lower)) {
      intent$type <- "team_member"
      intent$specific_member <- name
      break
    }
  }

  intent
}

#' Answer query with pre-calculated data (fast path)
#' @param query User query
#' @param projects Projects data
#' @param allocations Allocations data
#' @param team_members Team members data
#' @export
answer_query_direct <- function(query, projects, allocations, team_members) {
  intent <- analyze_query_intent(query, projects, allocations, team_members)

  # Fast path for common queries
  if (intent$specific_metric == "utilization") {
    util <- calculate_utilization(allocations, team_members)
    return(list(
      success = TRUE,
      response = sprintf("Current team utilization is %.1f%%. ", util) %>%
        paste0(if (util > 95) "The team is operating near full capacity." else
               if (util < 60) "The team has significant spare capacity." else
               "The team has a balanced workload."),
      used_ai = FALSE
    ))
  }

  if (intent$specific_metric == "project_count") {
    active <- count_active_projects(projects)
    total <- nrow(projects)
    return(list(
      success = TRUE,
      response = sprintf("There are %d active projects out of %d total projects.", active, total),
      used_ai = FALSE
    ))
  }

  if (intent$specific_metric == "risk") {
    risks <- calculate_project_risk(projects, allocations, team_members)
    high_risk <- risks[risks$Risk_Level == "High", ]

    if (nrow(high_risk) > 0) {
      msg <- sprintf("Found %d high-risk project(s): %s",
                    nrow(high_risk),
                    paste(high_risk$Project, collapse = ", "))
    } else {
      msg <- "No high-risk projects identified. All projects are on track."
    }

    return(list(
      success = TRUE,
      response = msg,
      used_ai = FALSE
    ))
  }

  if (intent$specific_metric == "allocation") {
    overalloc <- identify_overallocated(allocations, team_members, threshold = 1.0)

    if (nrow(overalloc) > 0) {
      members <- unique(overalloc$Name)
      msg <- sprintf("The following team member(s) are overallocated: %s",
                    paste(members, collapse = ", "))
    } else {
      msg <- "No team members are currently overallocated."
    }

    return(list(
      success = TRUE,
      response = msg,
      used_ai = FALSE
    ))
  }

  # Default: return NULL to use AI
  NULL
}

#' Main query handler with fallback logic
#' @param query User query
#' @param projects Projects data
#' @param allocations Allocations data
#' @param team_members Team members data
#' @param use_ai Whether to use AI (default TRUE)
#' @export
handle_query <- function(query, projects, allocations, team_members, use_ai = TRUE) {
  # Try direct answer first (fast path)
  direct_answer <- answer_query_direct(query, projects, allocations, team_members)

  if (!is.null(direct_answer)) {
    logger::log_info("Answered query directly without AI")
    return(direct_answer)
  }

  # Use AI if enabled
  if (use_ai) {
    logger::log_info("Using AI to answer query")
    ai_result <- query_ollama(query, projects, allocations, team_members)
    ai_result$used_ai <- TRUE
    return(ai_result)
  }

  # Fallback
  list(
    success = TRUE,
    response = "I don't have enough information to answer that question directly. Please try rephrasing or ask about utilization, projects, or team capacity.",
    used_ai = FALSE
  )
}
