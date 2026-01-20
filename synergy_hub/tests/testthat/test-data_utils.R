# Unit tests for data_utils.R

library(testthat)
library(dplyr)

# Source the data_utils functions
source("../../R/data_utils.R")

test_that("initialize_entries creates correct structure", {
  entries <- initialize_entries()

  expect_s3_class(entries, "data.frame")
  expect_equal(nrow(entries), 0)
  expect_equal(ncol(entries), 12)
  expect_true("Date" %in% names(entries))
  expect_true("ITS_Partner" %in% names(entries))
  expect_true("Business_Partner" %in% names(entries))
  expect_true("Service_Experience_Score" %in% names(entries))
  expect_true("Work_Product_Score" %in% names(entries))
  expect_true("Completed" %in% names(entries))
})

test_that("add_entry adds entry correctly", {
  entries <- initialize_entries()

  updated_entries <- add_entry(
    entries,
    date = "2026-01-20",
    its_partner = "John Doe",
    business_partner = "Jane Smith",
    department = "Marketing",
    division = "Digital",
    service_score = 8,
    work_score = 9,
    comments = "Great work",
    leadership_review = "Approved",
    action_requested = "None",
    resolution = ""
  )

  expect_equal(nrow(updated_entries), 1)
  expect_equal(updated_entries$ITS_Partner[1], "John Doe")
  expect_equal(updated_entries$Business_Partner[1], "Jane Smith")
  expect_equal(updated_entries$Service_Experience_Score[1], 8)
  expect_equal(updated_entries$Work_Product_Score[1], 9)
  expect_equal(updated_entries$Completed[1], "No")
})

test_that("add_entry handles missing optional fields", {
  entries <- initialize_entries()

  updated_entries <- add_entry(
    entries,
    date = "2026-01-20",
    its_partner = "John Doe",
    business_partner = "Jane Smith",
    department = "Marketing",
    division = "Digital",
    service_score = 8,
    work_score = 9
  )

  expect_equal(updated_entries$Comments[1], "")
  expect_equal(updated_entries$Leadership_Review[1], "")
  expect_equal(updated_entries$Action_Requested[1], "")
  expect_equal(updated_entries$Resolution[1], "")
})

test_that("validate_entry returns valid for correct data", {
  result <- validate_entry(
    date = as.Date("2026-01-20"),
    its_partner = "John Doe",
    business_partner = "Jane Smith",
    department = "Marketing",
    division = "Digital",
    service_score = 8,
    work_score = 9
  )

  expect_true(result$valid)
  expect_equal(result$message, "Valid")
})

test_that("validate_entry returns invalid for missing date", {
  result <- validate_entry(
    date = NULL,
    its_partner = "John Doe",
    business_partner = "Jane Smith",
    department = "Marketing",
    division = "Digital",
    service_score = 8,
    work_score = 9
  )

  expect_false(result$valid)
  expect_equal(result$message, "Date is required")
})

test_that("validate_entry returns invalid for missing ITS partner", {
  result <- validate_entry(
    date = as.Date("2026-01-20"),
    its_partner = "",
    business_partner = "Jane Smith",
    department = "Marketing",
    division = "Digital",
    service_score = 8,
    work_score = 9
  )

  expect_false(result$valid)
  expect_equal(result$message, "ITS Partner is required")
})

test_that("validate_entry returns invalid for out of range scores", {
  result <- validate_entry(
    date = as.Date("2026-01-20"),
    its_partner = "John Doe",
    business_partner = "Jane Smith",
    department = "Marketing",
    division = "Digital",
    service_score = 11,
    work_score = 9
  )

  expect_false(result$valid)
  expect_equal(result$message, "Service score must be between 1 and 10")
})

test_that("create_tooltip_text truncates long text", {
  long_text <- paste(rep("A", 50), collapse = "")
  result <- create_tooltip_text(long_text, max_length = 30)

  expect_true(grepl("...</span>", result))
  expect_true(grepl(paste0('title="', long_text, '"'), result))
})

test_that("create_tooltip_text handles short text", {
  short_text <- "Short text"
  result <- create_tooltip_text(short_text, max_length = 30)

  expect_false(grepl("...</span>", result))
  expect_true(grepl(short_text, result))
})

test_that("create_tooltip_text handles empty text", {
  result <- create_tooltip_text("", max_length = 30)

  expect_equal(result, '<span title=""></span>')
})

test_that("create_tooltip_text handles NA text", {
  result <- create_tooltip_text(NA, max_length = 30)

  expect_equal(result, '<span title=""></span>')
})

test_that("save_entries creates directory if needed", {
  temp_dir <- tempdir()
  test_file <- file.path(temp_dir, "test_synergy", "entries.parquet")

  # Clean up if exists
  if (file.exists(test_file)) {
    unlink(test_file)
  }

  entries <- initialize_entries()
  entries <- add_entry(
    entries,
    date = "2026-01-20",
    its_partner = "John Doe",
    business_partner = "Jane Smith",
    department = "Marketing",
    division = "Digital",
    service_score = 8,
    work_score = 9
  )

  result <- save_entries(entries, test_file)

  expect_true(result)
  expect_true(file.exists(test_file))

  # Clean up
  unlink(test_file)
  unlink(dirname(test_file), recursive = TRUE)
})

test_that("load_entries returns empty dataframe for non-existent file", {
  non_existent_file <- file.path(tempdir(), "non_existent.parquet")

  entries <- load_entries(non_existent_file)

  expect_s3_class(entries, "data.frame")
  expect_equal(nrow(entries), 0)
})

test_that("save and load entries round trip works", {
  temp_file <- file.path(tempdir(), "test_entries.parquet")

  # Clean up if exists
  if (file.exists(temp_file)) {
    unlink(temp_file)
  }

  original_entries <- initialize_entries()
  original_entries <- add_entry(
    original_entries,
    date = "2026-01-20",
    its_partner = "John Doe",
    business_partner = "Jane Smith",
    department = "Marketing",
    division = "Digital",
    service_score = 8,
    work_score = 9
  )

  # Save
  save_entries(original_entries, temp_file)

  # Load
  loaded_entries <- load_entries(temp_file)

  expect_equal(nrow(loaded_entries), nrow(original_entries))
  expect_equal(loaded_entries$ITS_Partner[1], original_entries$ITS_Partner[1])
  expect_equal(loaded_entries$Service_Experience_Score[1],
               original_entries$Service_Experience_Score[1])

  # Clean up
  unlink(temp_file)
})

test_that("initialize_its_personnel_from_relationships works correctly", {
  relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe", "Jane Smith", "John Doe"),
    `DIRECTORS/MANAGERS` = c("Manager1", "Manager2", "Manager3"),
    `DEPARTMENT (Bus.)` = c("Dept1", "Dept2", "Dept3"),
    DIVISION = c("Div1", "Div2", "Div3"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- initialize_its_personnel_from_relationships(relationships)

  expect_equal(nrow(result), 2)  # Should have 2 unique ITS partners
  expect_true("John Doe" %in% result$ITS_Partner)
  expect_true("Jane Smith" %in% result$ITS_Partner)
})

test_that("initialize_business_partners_from_relationships works correctly", {
  relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe", "Jane Smith", "John Doe"),
    `DIRECTORS/MANAGERS` = c("Manager1", "Manager2", "Manager1"),
    `DEPARTMENT (Bus.)` = c("Dept1", "Dept2", "Dept1"),
    DIVISION = c("Div1", "Div2", "Div1"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  result <- initialize_business_partners_from_relationships(relationships)

  expect_equal(nrow(result), 2)  # Should have 2 unique business partners
  expect_true("Manager1" %in% result$Business_Partner)
  expect_true("Manager2" %in% result$Business_Partner)
})

test_that("save_csv_data creates directory if needed", {
  temp_dir <- tempdir()
  test_file <- file.path(temp_dir, "test_synergy", "test.csv")

  # Clean up if exists
  if (file.exists(test_file)) {
    unlink(test_file)
  }

  test_data <- data.frame(
    Name = c("John", "Jane"),
    Score = c(8, 9)
  )

  result <- save_csv_data(test_data, test_file)

  expect_true(result)
  expect_true(file.exists(test_file))

  # Clean up
  unlink(test_file)
  unlink(dirname(test_file), recursive = TRUE)
})

message("All data_utils tests completed!")
