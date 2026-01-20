# Unit tests for ui_components.R

library(testthat)
library(shiny)
library(shinydashboard)

# Source the UI components functions
source("../../R/ui_components.R")

test_that("create_header returns dashboardHeader", {
  header <- create_header()

  expect_s3_class(header, "shiny.tag")
  expect_true(grepl("Synergy Hub", as.character(header), fixed = TRUE))
})

test_that("create_sidebar returns dashboardSidebar with menu items", {
  sidebar <- create_sidebar()

  expect_s3_class(sidebar, "shiny.tag")
  sidebar_html <- as.character(sidebar)

  # Check for key menu items
  expect_true(grepl("Home", sidebar_html, fixed = TRUE))
  expect_true(grepl("Dashboard", sidebar_html, fixed = TRUE))
  expect_true(grepl("Entries", sidebar_html, fixed = TRUE))
  expect_true(grepl("Analysis", sidebar_html, fixed = TRUE))
  expect_true(grepl("Visualization", sidebar_html, fixed = TRUE))
})

test_that("create_home_tab returns valid tab item", {
  tab <- create_home_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  expect_true(grepl("Welcome to Synergy Hub", tab_html, fixed = TRUE))
  expect_true(grepl("centralized tool", tab_html, fixed = TRUE))
})

test_that("create_dashboard_tab returns valid tab item with inputs", {
  tab <- create_dashboard_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  # Check for key input fields
  expect_true(grepl("date", tab_html, fixed = TRUE))
  expect_true(grepl("its_partner", tab_html, fixed = TRUE))
  expect_true(grepl("service_score", tab_html, fixed = TRUE))
  expect_true(grepl("work_score", tab_html, fixed = TRUE))
  expect_true(grepl("submit", tab_html, fixed = TRUE))
})

test_that("create_entries_tab returns valid tab item", {
  tab <- create_entries_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  expect_true(grepl("Recorded Entries", tab_html, fixed = TRUE))
  expect_true(grepl("entries_table", tab_html, fixed = TRUE))
})

test_that("create_analysis_tab returns valid tab item", {
  tab <- create_analysis_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  expect_true(grepl("Score Analysis", tab_html, fixed = TRUE))
  expect_true(grepl("score_plot", tab_html, fixed = TRUE))
})

test_that("create_update_tab returns valid tab item", {
  tab <- create_update_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  expect_true(grepl("Update Entries", tab_html, fixed = TRUE))
  expect_true(grepl("update_table", tab_html, fixed = TRUE))
})

test_that("create_unresolved_tab returns valid tab item", {
  tab <- create_unresolved_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  expect_true(grepl("Unresolved Tickets", tab_html, fixed = TRUE))
  expect_true(grepl("unresolved_table", tab_html, fixed = TRUE))
})

test_that("create_visualization_tab returns valid tab item", {
  tab <- create_visualization_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  expect_true(grepl("ITS Partners Network", tab_html, fixed = TRUE))
  expect_true(grepl("sankey_plot", tab_html, fixed = TRUE))
})

test_that("create_manage_its_tab returns valid tab item", {
  tab <- create_manage_its_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  expect_true(grepl("ITS Personnel Management", tab_html, fixed = TRUE))
  expect_true(grepl("Business Partners Management", tab_html, fixed = TRUE))
  expect_true(grepl("Relationship Management", tab_html, fixed = TRUE))
})

test_that("create_howto_tab returns valid tab item", {
  tab <- create_howto_tab()

  expect_s3_class(tab, "shiny.tag")
  tab_html <- as.character(tab)

  expect_true(grepl("How-To Guide", tab_html, fixed = TRUE))
  expect_true(grepl("how_to_page", tab_html, fixed = TRUE))
})

test_that("generate_follow_up_question shows improvement message for low scores", {
  result <- generate_follow_up_question(service_score = 4, work_score = 8)

  expect_s3_class(result, "html")
  result_html <- as.character(result)

  expect_true(grepl("Sorry to hear that", result_html, fixed = TRUE))
  expect_true(grepl("#E7717D", result_html, fixed = TRUE))
})

test_that("generate_follow_up_question shows love message for high scores", {
  result <- generate_follow_up_question(service_score = 9, work_score = 10)

  expect_s3_class(result, "html")
  result_html <- as.character(result)

  expect_true(grepl("What do you love", result_html, fixed = TRUE))
  expect_true(grepl("#66C0DC", result_html, fixed = TRUE))
})

test_that("generate_follow_up_question shows empty for neutral scores", {
  result <- generate_follow_up_question(service_score = 7, work_score = 8)

  expect_s3_class(result, "html")
  result_html <- as.character(result)

  expect_false(grepl("Sorry to hear that", result_html, fixed = TRUE))
  expect_false(grepl("What do you love", result_html, fixed = TRUE))
})

test_that("generate_follow_up_question handles edge cases", {
  # Exactly 5
  result <- generate_follow_up_question(service_score = 5, work_score = 6)
  expect_true(grepl("Sorry to hear that", as.character(result), fixed = TRUE))

  # Exactly 9
  result <- generate_follow_up_question(service_score = 9, work_score = 7)
  expect_true(grepl("What do you love", as.character(result), fixed = TRUE))

  # Both neutral
  result <- generate_follow_up_question(service_score = 7, work_score = 7)
  expect_false(grepl("Sorry", as.character(result), fixed = TRUE))
})

message("All ui_components tests completed!")
