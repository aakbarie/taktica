#' UI Components for Taktica
#'
#' Reusable UI components with improved UX
#' @importFrom shiny tags textInput dateRangeInput selectInput actionButton modalDialog
#' @importFrom shinydashboard box valueBox
#' @importFrom shinyWidgets pickerInput actionBttn

#' Create enhanced value box with trend indicator
#' @export
create_kpi_box <- function(value, subtitle, icon_name, color = "blue", trend = NULL) {
  box_content <- if (!is.null(trend)) {
    trend_icon <- if (trend > 0) "arrow-up" else if (trend < 0) "arrow-down" else "minus"
    trend_color <- if (trend > 0) "green" else if (trend < 0) "red" else "gray"

    shinydashboard::valueBox(
      value = tags$span(
        value,
        tags$small(
          style = sprintf("color: %s; margin-left: 10px;", trend_color),
          icon(trend_icon),
          sprintf(" %+.1f%%", trend)
        )
      ),
      subtitle = subtitle,
      icon = icon(icon_name),
      color = color
    )
  } else {
    shinydashboard::valueBox(
      value = value,
      subtitle = subtitle,
      icon = icon(icon_name),
      color = color
    )
  }

  box_content
}

#' Create project form with validation
#' @export
create_project_form <- function(id_prefix = "", project = NULL, team_members = NULL) {
  is_edit <- !is.null(project)

  tagList(
    textInput(
      paste0(id_prefix, "proj_name"),
      "Project Name*",
      value = if (is_edit) project$Project else "",
      placeholder = "Enter project name"
    ),
    if (!is.null(team_members)) {
      shinyWidgets::pickerInput(
        paste0(id_prefix, "proj_owner"),
        "Owner*",
        choices = team_members$Name,
        selected = if (is_edit) project$Owner else NULL,
        options = list(
          `live-search` = TRUE,
          title = "Select owner"
        )
      )
    } else {
      textInput(
        paste0(id_prefix, "proj_owner"),
        "Owner*",
        value = if (is_edit) project$Owner else "",
        placeholder = "Enter owner name"
      )
    },
    dateRangeInput(
      paste0(id_prefix, "proj_dates"),
      "Timeline*",
      start = if (is_edit) project$Start_Date else Sys.Date(),
      end = if (is_edit) project$End_Date else Sys.Date() + 30
    ),
    selectInput(
      paste0(id_prefix, "proj_cat"),
      "Category*",
      choices = c("Evaluation", "ML", "GenAI", "Shiny App", "Other"),
      selected = if (is_edit) project$Category else "ML"
    ),
    selectInput(
      paste0(id_prefix, "proj_status"),
      "Status",
      choices = c("Active", "On Hold", "Completed", "Cancelled"),
      selected = if (is_edit) project$Status else "Active"
    ),
    tags$small("* Required fields")
  )
}

#' Create enhanced sidebar with AI assistant
#' @export
create_enhanced_sidebar <- function(projects_df) {
  sidebarMenu(
    id = "sidebar_menu",
    menuItem("Dashboard", tabName = "dashboard", icon = icon("tachometer-alt")),
    menuItem("Projects", tabName = "projects", icon = icon("tasks")),
    menuItem("Timeline", tabName = "timeline", icon = icon("chart-gantt")),
    menuItem("Team", tabName = "team", icon = icon("users")),
    menuItem("Capacity", tabName = "capacity", icon = icon("chart-bar")),
    menuItem("Analytics", tabName = "analytics", icon = icon("chart-line")),
    menuItem("Forecast", tabName = "forecast", icon = icon("crystal-ball")),
    menuItem("Reports", tabName = "reports", icon = icon("file-export")),
    hr(),
    tags$div(
      style = "padding: 10px;",
      tags$h4("Ask Taktica", style = "color: white;"),
      textInput(
        "ai_query",
        NULL,
        placeholder = "What is our project load?",
        width = "100%"
      ),
      actionButton(
        "ask_ai",
        "Ask",
        icon = icon("paper-plane"),
        width = "100%",
        class = "btn-primary"
      ),
      tags$br(),
      tags$br(),
      verbatimTextOutput("ai_response", placeholder = TRUE)
    ),
    hr(),
    tags$div(
      style = "padding: 10px;",
      tags$h5("Filters", style = "color: white;"),
      shinyWidgets::pickerInput(
        "filter_owner",
        "Owner",
        choices = c("All", unique(projects_df$Owner)),
        selected = "All",
        multiple = FALSE,
        options = list(`live-search` = TRUE)
      ),
      shinyWidgets::pickerInput(
        "filter_category",
        "Category",
        choices = c("All", unique(projects_df$Category)),
        selected = "All",
        multiple = FALSE
      ),
      shinyWidgets::pickerInput(
        "filter_status",
        "Status",
        choices = c("All", "Active", "On Hold", "Completed", "Cancelled"),
        selected = "All",
        multiple = FALSE
      )
    )
  )
}

#' Create confirmation modal dialog
#' @export
create_confirmation_modal <- function(title, message, confirm_id, cancel_text = "Cancel", confirm_text = "Confirm") {
  modalDialog(
    title = title,
    message,
    footer = tagList(
      modalButton(cancel_text),
      actionButton(confirm_id, confirm_text, class = "btn-danger")
    ),
    easyClose = FALSE
  )
}

#' Create success notification
#' @export
show_success <- function(message, duration = 3) {
  showNotification(
    message,
    type = "message",
    duration = duration
  )
}

#' Create error notification
#' @export
show_error <- function(message, duration = 5) {
  showNotification(
    message,
    type = "error",
    duration = duration
  )
}

#' Create warning notification
#' @export
show_warning <- function(message, duration = 4) {
  showNotification(
    message,
    type = "warning",
    duration = duration
  )
}

#' Create insights panel
#' @export
create_insights_panel <- function(insights) {
  if (length(insights) == 0) {
    return(tags$p("No insights available", style = "color: gray; font-style: italic;"))
  }

  insight_boxes <- lapply(insights, function(insight) {
    alert_class <- switch(
      insight$type,
      "alert" = "alert-danger",
      "warning" = "alert-warning",
      "info" = "alert-info",
      "alert-secondary"
    )

    alert_icon <- switch(
      insight$type,
      "alert" = "exclamation-triangle",
      "warning" = "exclamation-circle",
      "info" = "info-circle",
      "lightbulb"
    )

    tags$div(
      class = paste("alert", alert_class),
      role = "alert",
      icon(alert_icon),
      " ",
      tags$strong(paste0(insight$category, ": ")),
      insight$message
    )
  })

  tagList(insight_boxes)
}

#' Create action buttons panel
#' @export
create_action_buttons <- function(edit_id = NULL, delete_id = NULL, export_id = NULL) {
  buttons <- list()

  if (!is.null(edit_id)) {
    buttons[[length(buttons) + 1]] <- actionButton(
      edit_id,
      "Edit",
      icon = icon("edit"),
      class = "btn-primary btn-sm"
    )
  }

  if (!is.null(delete_id)) {
    buttons[[length(buttons) + 1]] <- actionButton(
      delete_id,
      "Delete",
      icon = icon("trash"),
      class = "btn-danger btn-sm"
    )
  }

  if (!is.null(export_id)) {
    buttons[[length(buttons) + 1]] <- downloadButton(
      export_id,
      "Export",
      class = "btn-success btn-sm"
    )
  }

  tagList(buttons)
}

#' Create loading spinner
#' @export
create_loading_spinner <- function(message = "Loading...") {
  tags$div(
    class = "text-center",
    style = "padding: 50px;",
    icon("spinner", class = "fa-spin fa-3x"),
    tags$br(),
    tags$br(),
    tags$h4(message)
  )
}

#' Create empty state message
#' @export
create_empty_state <- function(title, message, icon_name = "inbox", action_button = NULL) {
  tags$div(
    class = "text-center",
    style = "padding: 50px; color: #999;",
    icon(icon_name, class = "fa-4x"),
    tags$br(),
    tags$br(),
    tags$h3(title),
    tags$p(message),
    if (!is.null(action_button)) {
      tags$br()
    },
    action_button
  )
}

#' Create help tooltip
#' @export
create_tooltip <- function(element, tooltip_text) {
  tags$span(
    `data-toggle` = "tooltip",
    `data-placement` = "top",
    title = tooltip_text,
    element
  )
}

#' Create breadcrumb navigation
#' @export
create_breadcrumb <- function(items) {
  tags$nav(
    `aria-label` = "breadcrumb",
    tags$ol(
      class = "breadcrumb",
      lapply(seq_along(items), function(i) {
        if (i == length(items)) {
          tags$li(class = "breadcrumb-item active", `aria-current` = "page", items[[i]])
        } else {
          tags$li(class = "breadcrumb-item", items[[i]])
        }
      })
    )
  )
}

#' Create status badge
#' @export
create_status_badge <- function(status) {
  badge_class <- switch(
    status,
    "Active" = "badge-primary",
    "Completed" = "badge-success",
    "On Hold" = "badge-warning",
    "Cancelled" = "badge-danger",
    "badge-secondary"
  )

  tags$span(class = paste("badge", badge_class), status)
}

#' Create category badge
#' @export
create_category_badge <- function(category) {
  badge_class <- switch(
    category,
    "GenAI" = "badge-info",
    "ML" = "badge-primary",
    "Evaluation" = "badge-success",
    "Shiny App" = "badge-warning",
    "badge-secondary"
  )

  tags$span(class = paste("badge", badge_class), category)
}
