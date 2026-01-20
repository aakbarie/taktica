# UI Component Functions for Synergy Hub
# This module contains reusable UI components

library(shiny)
library(shinydashboard)

#' Create the dashboard header
#'
#' @return Dashboard header object
create_header <- function() {
  dashboardHeader(title = "Synergy Hub")
}

#' Create the dashboard sidebar
#'
#' @return Dashboard sidebar object
create_sidebar <- function() {
  dashboardSidebar(
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Entries", tabName = "entries", icon = icon("table")),
      menuItem("Analysis", tabName = "analysis", icon = icon("chart-line")),
      menuItem("Update", tabName = "update", icon = icon("edit")),
      menuItem("Unresolved Tickets", tabName = "unresolved",
               icon = icon("exclamation-circle")),
      menuItem("Visualization", tabName = "visualization",
               icon = icon("project-diagram")),
      menuItem("Manage ITS Personnel", tabName = "manage_its",
               icon = icon("users")),
      menuItem("How-To Guide", tabName = "howto",
               icon = icon("info-circle"))
    )
  )
}

#' Create the home tab content
#'
#' @return Tab item for home
create_home_tab <- function() {
  tabItem(
    tabName = "home",
    fluidRow(
      column(
        width = 12,
        box(
          title = "Welcome to Synergy Hub",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          "Synergy Hub is your centralized tool for managing IT Business Relationships, tracking performance scores, and analyzing monthly trends. Navigate through the tabs to enter data, view recorded entries, and explore score analyses."
        )
      )
    )
  )
}

#' Create the dashboard tab content for data entry
#'
#' @return Tab item for dashboard
create_dashboard_tab <- function() {
  tabItem(
    tabName = "dashboard",
    fluidRow(
      column(
        width = 4,
        box(
          title = "Enter Details",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          dateInput("date", "Date:"),
          selectInput("its_partner", "ITS Partner:", choices = NULL),
          uiOutput("business_partner_ui"),
          uiOutput("department_ui"),
          uiOutput("division_ui"),
          numericInput("service_score", "Service Experience Score:",
                       value = 5, min = 1, max = 10),
          numericInput("work_score", "Work Product Score:", value = 5,
                       min = 1, max = 10),
          textAreaInput("comments", "Comments:", ""),
          textAreaInput("leadership_review", "ITS Leadership Review:", ""),
          textAreaInput("action_requested", "Action Requested:", ""),
          textAreaInput("resolution", "Resolution:", ""),
          actionButton("submit", "Submit")
        )
      ),
      column(
        width = 8,
        box(
          title = "Guiding Questions",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          tags$ul(
            tags$li("How satisfied were you with the service experience when you worked with ITS staff on a scale from 1-10?"),
            tags$li("How satisfied were you with the work product that ITS delivered to you on a scale from 1-10?"),
            tags$li("Any comments you would like to add?"),
            tags$li("What business problems are you trying to solve and how do you think technology/ITS can help?")
          ),
          uiOutput("follow_up_question")
        )
      )
    )
  )
}

#' Create the entries tab content
#'
#' @return Tab item for entries
create_entries_tab <- function() {
  tabItem(
    tabName = "entries",
    fluidRow(
      column(
        width = 12,
        box(
          title = "Recorded Entries",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          DT::DTOutput("entries_table")
        )
      )
    )
  )
}

#' Create the analysis tab content
#'
#' @return Tab item for analysis
create_analysis_tab <- function() {
  tabItem(
    tabName = "analysis",
    fluidRow(
      column(
        width = 12,
        box(
          title = "Score Analysis",
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          plotly::plotlyOutput("score_plot")
        )
      )
    )
  )
}

#' Create the update tab content
#'
#' @return Tab item for update
create_update_tab <- function() {
  tabItem(
    tabName = "update",
    fluidRow(
      column(
        width = 12,
        box(
          title = "Update Entries",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          DT::DTOutput("update_table")
        )
      )
    )
  )
}

#' Create the unresolved tickets tab content
#'
#' @return Tab item for unresolved tickets
create_unresolved_tab <- function() {
  tabItem(
    tabName = "unresolved",
    fluidRow(
      column(
        width = 12,
        box(
          title = "Unresolved Tickets",
          status = "danger",
          solidHeader = TRUE,
          width = 12,
          DT::DTOutput("unresolved_table")
        )
      )
    )
  )
}

#' Create the visualization tab content
#'
#' @return Tab item for visualization
create_visualization_tab <- function() {
  tabItem(
    tabName = "visualization",
    fluidRow(
      column(
        width = 12,
        box(
          title = "ITS Partners Network",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          height = "800px",
          plotly::plotlyOutput("sankey_plot", height = "750px")
        )
      )
    )
  )
}

#' Create the manage ITS personnel tab content
#'
#' @return Tab item for managing ITS personnel
create_manage_its_tab <- function() {
  tabItem(
    tabName = "manage_its",
    fluidRow(
      column(
        width = 6,
        box(
          title = "ITS Personnel Management",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          DT::DTOutput("its_personnel_table"),
          actionButton("add_its_personnel", "Add ITS Personnel"),
          actionButton("delete_its_personnel",
                       "Delete Selected ITS Personnel"),
          actionButton("save_its_personnel", "Save ITS Personnel")
        )
      ),
      column(
        width = 6,
        box(
          title = "Business Partners Management",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          DT::DTOutput("business_partners_table"),
          actionButton("add_business_partner", "Add Business Partner"),
          actionButton("delete_business_partner",
                       "Delete Selected Business Partner"),
          actionButton("save_business_partners", "Save Business Partners")
        )
      )
    ),
    fluidRow(
      column(
        width = 12,
        box(
          title = "Relationship Management",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          uiOutput("relationship_ui"),
          actionButton("save_relationships", "Save Relationships")
        )
      )
    )
  )
}

#' Create the how-to guide tab content
#'
#' @return Tab item for how-to guide
create_howto_tab <- function() {
  tabItem(
    tabName = "howto",
    fluidRow(
      column(
        width = 12,
        box(
          title = "How-To Guide",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          htmlOutput("how_to_page")
        )
      )
    )
  )
}

#' Generate follow-up question HTML based on scores
#'
#' @param service_score Service experience score
#' @param work_score Work product score
#' @return HTML for follow-up question
generate_follow_up_question <- function(service_score, work_score) {
  if (service_score <= 5 || work_score <= 5) {
    HTML(
      sprintf(
        '<div style="color: #E7717D; font-weight: bold; font-size: 18px;">%s</div>',
        "Sorry to hear that! How could we improve?"
      )
    )
  } else if (service_score >= 9 || work_score >= 9) {
    HTML(
      sprintf(
        '<div style="color: #66C0DC; font-weight: bold; font-size: 18px;">%s</div>',
        "What do you love about the service/work product?"
      )
    )
  } else {
    HTML('<div style="font-size: 18px;"></div>')
  }
}
