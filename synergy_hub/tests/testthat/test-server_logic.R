# Unit tests for server_logic.R

library(testthat)
library(dplyr)
library(lubridate)

# Source the required functions
source("../../R/data_utils.R")
source("../../R/server_logic.R")

test_that("prepare_entries_for_display formats text correctly", {
  entries <- data.frame(
    Date = as.Date("2026-01-20"),
    ITS_Partner = "John Doe",
    Business_Partner = "Jane Smith",
    Department = "Marketing",
    Division = "Digital",
    Service_Experience_Score = 8,
    Work_Product_Score = 9,
    Completed = "No",
    Comments = paste(rep("A", 50), collapse = ""),
    Leadership_Review = "Short review",
    Action_Requested = paste(rep("B", 50), collapse = ""),
    Resolution = "",
    stringsAsFactors = FALSE
  )

  result <- prepare_entries_for_display(entries, max_length = 30)

  expect_true(grepl("...</span>", result$Comments[1]))
  expect_false(grepl("...</span>", result$Leadership_Review[1]))
  expect_true(grepl("...</span>", result$Action_Requested[1]))
})

test_that("get_unresolved_entries filters correctly", {
  entries <- data.frame(
    Date = as.Date(c("2026-01-20", "2026-01-21", "2026-01-22")),
    ITS_Partner = c("John", "Jane", "Bob"),
    Business_Partner = c("A", "B", "C"),
    Department = c("D1", "D2", "D3"),
    Division = c("Div1", "Div2", "Div3"),
    Service_Experience_Score = c(8, 7, 9),
    Work_Product_Score = c(9, 8, 10),
    Completed = c("No", "Yes", "No"),
    Comments = c("", "", ""),
    Leadership_Review = c("", "", ""),
    Action_Requested = c("", "", ""),
    Resolution = c("", "", ""),
    stringsAsFactors = FALSE
  )

  result <- get_unresolved_entries(entries)

  expect_equal(nrow(result), 2)
  expect_true("Row_Number" %in% names(result))
  expect_equal(result$ITS_Partner, c("John", "Bob"))
})

test_that("filter_business_partners returns correct partners", {
  relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe", "John Doe", "Jane Smith"),
    `DIRECTORS/MANAGERS` = c("Manager1", "Manager2", "Manager3"),
    `DEPARTMENT (Bus.)` = c("Dept1", "Dept2", "Dept3"),
    DIVISION = c("Div1", "Div2", "Div3"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- filter_business_partners(relationships, "John Doe")

  expect_equal(length(result), 2)
  expect_true("Manager1" %in% result)
  expect_true("Manager2" %in% result)
  expect_false("Manager3" %in% result)
})

test_that("filter_business_partners handles invalid input", {
  relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe"),
    `DIRECTORS/MANAGERS` = c("Manager1"),
    `DEPARTMENT (Bus.)` = c("Dept1"),
    DIVISION = c("Div1"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- filter_business_partners(relationships, NULL)
  expect_equal(length(result), 0)

  result <- filter_business_partners(relationships, "")
  expect_equal(length(result), 0)
})

test_that("filter_departments returns correct departments", {
  business_partners <- data.frame(
    Business_Partner = c("Manager1", "Manager2"),
    Department = c("Marketing", "Sales"),
    Division = c("Div1", "Div2"),
    stringsAsFactors = FALSE
  )

  result <- filter_departments(business_partners, "Manager1")

  expect_equal(length(result), 1)
  expect_equal(result[1], "Marketing")
})

test_that("filter_divisions returns correct divisions", {
  business_partners <- data.frame(
    Business_Partner = c("Manager1", "Manager2"),
    Department = c("Marketing", "Sales"),
    Division = c("Div1", "Div2"),
    stringsAsFactors = FALSE
  )

  result <- filter_divisions(business_partners, "Manager1")

  expect_equal(length(result), 1)
  expect_equal(result[1], "Div1")
})

test_that("prepare_score_analysis_data returns correct structure", {
  entries <- data.frame(
    Date = as.Date(c("2025-12-15", "2025-12-20", "2026-01-10")),
    ITS_Partner = c("John", "Jane", "Bob"),
    Business_Partner = c("A", "B", "C"),
    Department = c("D1", "D2", "D3"),
    Division = c("Div1", "Div2", "Div3"),
    Service_Experience_Score = c(8, 5, 9),
    Work_Product_Score = c(9, 6, 10),
    Completed = c("No", "No", "No"),
    Comments = c("", "", ""),
    Leadership_Review = c("", "", ""),
    Action_Requested = c("", "", ""),
    Resolution = c("", "", ""),
    stringsAsFactors = FALSE
  )

  result <- prepare_score_analysis_data(entries, months_back = 2)

  expect_s3_class(result, "data.frame")
  expect_true("Month" %in% names(result))
  expect_true("Avg_Service_Score" %in% names(result))
  expect_true("Avg_Work_Score" %in% names(result))
  expect_true(nrow(result) >= 1)
})

test_that("prepare_score_analysis_data handles empty entries", {
  entries <- initialize_entries()

  result <- prepare_score_analysis_data(entries)

  expect_null(result)
})

test_that("prepare_sankey_data returns correct structure", {
  relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe", "Jane Smith"),
    `DIRECTORS/MANAGERS` = c("Manager1", "Manager2"),
    `DEPARTMENT (Bus.)` = c("Marketing", "Sales"),
    DIVISION = c("Div1", "Div2"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- prepare_sankey_data(relationships)

  expect_type(result, "list")
  expect_true("nodes" %in% names(result))
  expect_true("links" %in% names(result))
  expect_s3_class(result$nodes, "data.frame")
  expect_s3_class(result$links, "data.frame")
  expect_true("name" %in% names(result$nodes))
  expect_true(all(c("source", "target", "value") %in% names(result$links)))
})

test_that("prepare_sankey_data handles empty relationships", {
  relationships <- data.frame(
    `PARTNER (IT)` = character(),
    `DIRECTORS/MANAGERS` = character(),
    `DEPARTMENT (Bus.)` = character(),
    DIVISION = character(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- prepare_sankey_data(relationships)

  expect_null(result)
})

test_that("update_relationships adds new relationships", {
  existing_relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe"),
    `DIRECTORS/MANAGERS` = c("Manager1"),
    `DEPARTMENT (Bus.)` = c("Marketing"),
    DIVISION = c("Div1"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  business_partners <- data.frame(
    Business_Partner = c("Manager1", "Manager2", "Manager3"),
    Department = c("Marketing", "Sales", "IT"),
    Division = c("Div1", "Div2", "Div3"),
    stringsAsFactors = FALSE
  )

  result <- update_relationships(
    existing_relationships,
    "Jane Smith",
    c("Manager2", "Manager3"),
    business_partners
  )

  expect_equal(nrow(result), 3)
  expect_true(any(result$`PARTNER (IT)` == "Jane Smith"))
})

test_that("update_relationships replaces existing relationships", {
  existing_relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe", "John Doe"),
    `DIRECTORS/MANAGERS` = c("Manager1", "Manager2"),
    `DEPARTMENT (Bus.)` = c("Marketing", "Sales"),
    DIVISION = c("Div1", "Div2"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  business_partners <- data.frame(
    Business_Partner = c("Manager1", "Manager2", "Manager3"),
    Department = c("Marketing", "Sales", "IT"),
    Division = c("Div1", "Div2", "Div3"),
    stringsAsFactors = FALSE
  )

  result <- update_relationships(
    existing_relationships,
    "John Doe",
    c("Manager3"),
    business_partners
  )

  john_relationships <- result %>% filter(`PARTNER (IT)` == "John Doe")

  expect_equal(nrow(john_relationships), 1)
  expect_equal(john_relationships$`DIRECTORS/MANAGERS`[1], "Manager3")
})

test_that("get_assigned_business_partners returns correct partners", {
  relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe", "John Doe", "Jane Smith"),
    `DIRECTORS/MANAGERS` = c("Manager1", "Manager2", "Manager3"),
    `DEPARTMENT (Bus.)` = c("Marketing", "Sales", "IT"),
    DIVISION = c("Div1", "Div2", "Div3"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- get_assigned_business_partners(relationships, "John Doe")

  expect_equal(length(result), 2)
  expect_true("Manager1" %in% result)
  expect_true("Manager2" %in% result)
  expect_false("Manager3" %in% result)
})

test_that("get_assigned_business_partners handles invalid input", {
  relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe"),
    `DIRECTORS/MANAGERS` = c("Manager1"),
    `DEPARTMENT (Bus.)` = c("Marketing"),
    DIVISION = c("Div1"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- get_assigned_business_partners(relationships, NULL)
  expect_equal(length(result), 0)

  result <- get_assigned_business_partners(relationships, "")
  expect_equal(length(result), 0)
})

message("All server_logic tests completed!")
