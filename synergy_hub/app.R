# Synergy Hub - IT Business Relationship Management System
# Main Application File

# Load required packages
library(shiny)
library(shinydashboard)
library(readr)
library(dplyr)
library(DT)
library(lubridate)
library(ggplot2)
library(arrow)
library(plotly)

# Load configuration (contains file paths and settings)
# IMPORTANT: Edit config.R to change file paths, not this file!
source("config.R")

# Source modular components
source("R/data_utils.R")
source("R/ui_components.R")
source("R/server_logic.R")

# Note: File paths are now defined in config.R
# This protects your configuration from accidental loss

# Load existing data
saved_entries <- load_entries(entries_file)
relationships <- load_relationships(relationships_file)
its_personnel <- load_its_personnel(its_personnel_file, relationships)
business_partners <- load_business_partners(business_partners_file, relationships)

# Reactive values placeholder
entries <- reactiveVal(saved_entries)
relationships_data <- reactiveVal(relationships)
its_personnel_data <- reactiveVal(its_personnel)
business_partners_data <- reactiveVal(business_partners)

# UI Definition
ui <- dashboardPage(
  create_header(),
  create_sidebar(),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ),
    tabItems(
      create_home_tab(),
      create_dashboard_tab(),
      create_entries_tab(),
      create_analysis_tab(),
      create_update_tab(),
      create_unresolved_tab(),
      create_visualization_tab(),
      create_manage_its_tab(),
      create_howto_tab()
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  # Load and render the How-To guide
  output$how_to_page <- renderUI({
    tryCatch({
      includeMarkdown("www/How_To.md")
    }, error = function(e) {
      HTML("<p>How-To guide is not available. Please create the How_To.md file in the www folder.</p>")
    })
  })

  # Update ITS Partner choices
  observe({
    updateSelectInput(session, "its_partner",
                      choices = its_personnel_data()$ITS_Partner)
  })

  # Reactive filtering of Business Partners based on selected ITS Partner
  filtered_business_partners <- reactive({
    req(input$its_partner)
    filter_business_partners(relationships_data(), input$its_partner)
  })

  # Render dynamic UI for Business Partner selection
  output$business_partner_ui <- renderUI({
    selectInput(
      "business_partner",
      "Business Partner:",
      choices = filtered_business_partners(),
      selected = NULL
    )
  })

  # Reactive filtering of Departments
  filtered_departments <- reactive({
    req(input$business_partner)
    filter_departments(business_partners_data(), input$business_partner)
  })

  # Render dynamic UI for Department selection
  output$department_ui <- renderUI({
    selectInput(
      "department",
      "Department:",
      choices = filtered_departments(),
      selected = NULL
    )
  })

  # Reactive filtering of Divisions
  filtered_divisions <- reactive({
    req(input$business_partner)
    filter_divisions(business_partners_data(), input$business_partner)
  })

  # Render dynamic UI for Division selection
  output$division_ui <- renderUI({
    selectInput(
      "division",
      "Division:",
      choices = filtered_divisions(),
      selected = NULL
    )
  })

  # Generate follow-up questions based on scores
  observe({
    output$follow_up_question <- renderUI({
      generate_follow_up_question(input$service_score, input$work_score)
    })
  })

  # Handle form submission
  observeEvent(input$submit, {
    # Validate inputs
    validation <- validate_entry(
      input$date, input$its_partner, input$business_partner,
      input$department, input$division, input$service_score, input$work_score
    )

    if (!validation$valid) {
      showModal(modalDialog(
        title = "Validation Error",
        validation$message,
        easyClose = TRUE,
        footer = NULL
      ))
      return()
    }

    # Add new entry
    updated_entries <- add_entry(
      entries(),
      date = input$date,
      its_partner = input$its_partner,
      business_partner = input$business_partner,
      department = input$department,
      division = input$division,
      service_score = input$service_score,
      work_score = input$work_score,
      comments = input$comments,
      leadership_review = input$leadership_review,
      action_requested = input$action_requested,
      resolution = input$resolution
    )

    entries(updated_entries)
    save_entries(updated_entries, entries_file)

    showModal(modalDialog(
      title = "Submission Successful",
      "Your entry has been recorded and saved.",
      easyClose = TRUE,
      footer = NULL
    ))
  })

  # Render entries table
  output$entries_table <- renderDT({
    entries_display <- prepare_entries_for_display(entries())
    datatable(
      entries_display,
      escape = FALSE,
      options = list(
        pageLength = 5,
        autoWidth = TRUE,
        order = list(list(0, 'desc'))  # Sort by Date column (index 0) descending
      )
    )
  })

  # Render score analysis plot
  output$score_plot <- renderPlotly({
    plot_data <- prepare_score_analysis_data(entries())
    if (is.null(plot_data)) {
      return(NULL)
    }
    create_score_analysis_plot(plot_data)
  })

  # Render update table
  output$update_table <- renderDT({
    entries_display <- prepare_entries_for_display(entries())
    datatable(
      entries_display,
      escape = FALSE,
      options = list(
        pageLength = 5,
        autoWidth = TRUE,
        order = list(list(0, 'desc')),  # Sort by Date column (index 0) descending
        selection = 'single'
      )
    )
  })

  # Handle row selection for editing
  observeEvent(input$update_table_rows_selected, {
    selected_row <- input$update_table_rows_selected
    if (length(selected_row) > 0) {
      selected_data <- entries()[selected_row, ]

      showModal(modalDialog(
        title = "Edit Entry",
        fluidRow(
          column(6,
                 textAreaInput("edit_leadership_review",
                               "ITS Leadership Review:",
                               value = selected_data$Leadership_Review),
                 textAreaInput("edit_action_requested",
                               "Action Requested:",
                               value = selected_data$Action_Requested),
                 textAreaInput("edit_resolution",
                               "Resolution:",
                               value = selected_data$Resolution),
                 selectInput("edit_completed", "Completed:",
                             choices = c("No", "Yes"),
                             selected = selected_data$Completed)
          ),
          column(6,
                 tags$h4("Full Comments:"),
                 tags$p(style = "white-space: pre-wrap; max-height: 300px; overflow-y: auto;",
                        selected_data$Comments)
          )
        ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton("save_changes", "Save Changes")
        ),
        easyClose = TRUE
      ))
    }
  })

  # Save changes from edit modal
  observeEvent(input$save_changes, {
    selected_row <- input$update_table_rows_selected
    updated_entries <- entries()

    updated_entries[selected_row, "Leadership_Review"] <- input$edit_leadership_review
    updated_entries[selected_row, "Action_Requested"] <- input$edit_action_requested
    updated_entries[selected_row, "Resolution"] <- input$edit_resolution
    updated_entries[selected_row, "Completed"] <- input$edit_completed

    entries(updated_entries)
    save_entries(updated_entries, entries_file)

    removeModal()
  })

  # Reactive value to store selected entry row number for unresolved
  selected_entry_row_unresolved <- reactiveVal()

  # Render unresolved tickets table
  output$unresolved_table <- renderDT({
    unresolved_entries <- get_unresolved_entries(entries())
    unresolved_display <- prepare_entries_for_display(unresolved_entries)

    datatable(
      unresolved_display,
      escape = FALSE,
      options = list(
        pageLength = 5,
        autoWidth = TRUE,
        order = list(list(0, 'desc')),  # Sort by Date column (index 0) descending
        columnDefs = list(list(visible = FALSE,
                               targets = which(names(unresolved_display) == "Row_Number") - 1)),
        selection = 'single'
      )
    )
  })

  # Handle unresolved ticket selection
  observeEvent(input$unresolved_table_rows_selected, {
    selected_row <- input$unresolved_table_rows_selected
    if (length(selected_row) > 0) {
      unresolved_entries <- get_unresolved_entries(entries())
      selected_data <- unresolved_entries[selected_row, ]
      row_in_entries <- selected_data$Row_Number

      selected_entry_row_unresolved(row_in_entries)

      showModal(modalDialog(
        title = "Resolve Ticket",
        fluidRow(
          column(6,
                 textAreaInput("resolve_resolution", "Resolution:",
                               value = selected_data$Resolution),
                 selectInput("resolve_completed", "Completed:",
                             choices = c("No", "Yes"),
                             selected = selected_data$Completed)
          ),
          column(6,
                 tags$h4("Full Comments:"),
                 tags$p(style = "white-space: pre-wrap; max-height: 300px; overflow-y: auto;",
                        selected_data$Comments)
          )
        ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton("save_resolve_changes", "Save Changes")
        ),
        easyClose = TRUE
      ))
    }
  })

  # Save changes from resolve modal
  observeEvent(input$save_resolve_changes, {
    row_in_entries <- selected_entry_row_unresolved()
    updated_entries <- entries()

    updated_entries[row_in_entries, "Resolution"] <- input$resolve_resolution
    updated_entries[row_in_entries, "Completed"] <- input$resolve_completed

    entries(updated_entries)
    save_entries(updated_entries, entries_file)

    removeModal()
  })

  # Render Sankey diagram
  output$sankey_plot <- renderPlotly({
    sankey_data <- prepare_sankey_data(relationships_data())
    if (is.null(sankey_data)) {
      return(NULL)
    }
    create_sankey_plot(sankey_data)
  })

  # Render ITS Personnel table
  output$its_personnel_table <- renderDT({
    datatable(
      its_personnel_data(),
      selection = 'single',
      editable = TRUE,
      options = list(pageLength = 5, autoWidth = TRUE)
    )
  })

  # Render Business Partners table
  output$business_partners_table <- renderDT({
    datatable(
      business_partners_data(),
      selection = 'single',
      editable = TRUE,
      options = list(pageLength = 5, autoWidth = TRUE)
    )
  })

  # Add ITS Personnel
  observeEvent(input$add_its_personnel, {
    showModal(modalDialog(
      title = "Add ITS Personnel",
      textInput("new_its_personnel_name", "Name:"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_add_its_personnel", "Add")
      ),
      easyClose = TRUE
    ))
  })

  observeEvent(input$confirm_add_its_personnel, {
    new_name <- input$new_its_personnel_name
    if (new_name != "") {
      updated_data <- its_personnel_data()
      if (!(new_name %in% updated_data$ITS_Partner)) {
        updated_data <- rbind(updated_data,
                              data.frame(ITS_Partner = new_name,
                                         stringsAsFactors = FALSE))
        its_personnel_data(updated_data)
      }
      removeModal()
    }
  })

  # Add Business Partner
  observeEvent(input$add_business_partner, {
    showModal(modalDialog(
      title = "Add Business Partner",
      textInput("new_business_partner_name", "Name:"),
      textInput("new_department", "Department:"),
      textInput("new_division", "Division:"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_add_business_partner", "Add")
      ),
      easyClose = TRUE
    ))
  })

  observeEvent(input$confirm_add_business_partner, {
    new_name <- input$new_business_partner_name
    new_department <- input$new_department
    new_division <- input$new_division
    if (new_name != "") {
      updated_data <- business_partners_data()
      if (!(new_name %in% updated_data$Business_Partner)) {
        new_row <- data.frame(
          Business_Partner = new_name,
          Department = new_department,
          Division = new_division,
          stringsAsFactors = FALSE
        )
        updated_data <- rbind(updated_data, new_row)
        business_partners_data(updated_data)
      }
      removeModal()
    }
  })

  # Handle edits in ITS Personnel table
  observeEvent(input$its_personnel_table_cell_edit, {
    info <- input$its_personnel_table_cell_edit
    updated_data <- its_personnel_data()
    updated_data[info$row, info$col + 1] <- info$value
    its_personnel_data(updated_data)
  })

  # Handle edits in Business Partners table
  observeEvent(input$business_partners_table_cell_edit, {
    info <- input$business_partners_table_cell_edit
    updated_data <- business_partners_data()
    updated_data[info$row, info$col + 1] <- info$value
    business_partners_data(updated_data)
  })

  # Delete ITS Personnel
  observeEvent(input$delete_its_personnel, {
    selected <- input$its_personnel_table_rows_selected
    if (length(selected) > 0) {
      updated_data <- its_personnel_data()
      selected_personnel <- updated_data$ITS_Partner[selected]
      updated_data <- updated_data[-selected, ]
      its_personnel_data(updated_data)

      # Remove associated relationships
      rel_data <- relationships_data()
      rel_data <- rel_data[!(rel_data$`PARTNER (IT)` %in% selected_personnel), ]
      relationships_data(rel_data)
    }
  })

  # Delete Business Partner
  observeEvent(input$delete_business_partner, {
    selected <- input$business_partners_table_rows_selected
    if (length(selected) > 0) {
      updated_data <- business_partners_data()
      selected_partners <- updated_data$Business_Partner[selected]
      updated_data <- updated_data[-selected, ]
      business_partners_data(updated_data)

      # Remove associated relationships
      rel_data <- relationships_data()
      rel_data <- rel_data[!(rel_data$`DIRECTORS/MANAGERS` %in% selected_partners), ]
      relationships_data(rel_data)
    }
  })

  # Relationship Management UI
  output$relationship_ui <- renderUI({
    fluidRow(
      column(
        width = 6,
        selectInput("selected_its_personnel", "Select ITS Personnel:",
                    choices = its_personnel_data()$ITS_Partner)
      ),
      column(
        width = 6,
        uiOutput("business_partners_checkbox_ui")
      )
    )
  })

  output$business_partners_checkbox_ui <- renderUI({
    req(input$selected_its_personnel)

    assigned_partners <- get_assigned_business_partners(
      relationships_data(),
      input$selected_its_personnel
    )

    checkboxGroupInput(
      "assigned_business_partners",
      "Assign Business Partners:",
      choices = business_partners_data()$Business_Partner,
      selected = assigned_partners
    )
  })

  # Save Relationships
  observeEvent(input$save_relationships, {
    req(input$selected_its_personnel)

    updated_relationships <- update_relationships(
      relationships_data(),
      input$selected_its_personnel,
      input$assigned_business_partners,
      business_partners_data()
    )

    relationships_data(updated_relationships)
    save_csv_data(updated_relationships, relationships_file)

    showModal(modalDialog(
      title = "Relationships Updated",
      "The relationships have been saved.",
      easyClose = TRUE,
      footer = NULL
    ))
  })

  # Save ITS Personnel
  observeEvent(input$save_its_personnel, {
    updated_data <- its_personnel_data()
    save_csv_data(updated_data, its_personnel_file)

    showModal(modalDialog(
      title = "Save Successful",
      "ITS Personnel data has been saved.",
      easyClose = TRUE,
      footer = NULL
    ))
  })

  # Save Business Partners
  observeEvent(input$save_business_partners, {
    updated_data <- business_partners_data()
    save_csv_data(updated_data, business_partners_file)

    showModal(modalDialog(
      title = "Save Successful",
      "Business Partners data has been saved.",
      easyClose = TRUE,
      footer = NULL
    ))
  })
}

# Run the application
shinyApp(ui = ui, server = server)
