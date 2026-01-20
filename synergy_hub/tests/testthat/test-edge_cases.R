# Test for Business Partner Assignment Edge Cases

library(testthat)
library(dplyr)

# Source the functions
source("../../R/data_utils.R")
source("../../R/server_logic.R")

test_that("update_relationships handles NULL assigned_business_partners", {
  existing_relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe"),
    `DIRECTORS/MANAGERS` = c("Manager1"),
    `DEPARTMENT (Bus.)` = c("Marketing"),
    DIVISION = c("Div1"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  business_partners <- data.frame(
    Business_Partner = c("Manager1"),
    Department = c("Marketing"),
    Division = c("Div1"),
    stringsAsFactors = FALSE
  )

  # Test with NULL (should remove all relationships for this ITS personnel)
  result <- update_relationships(
    existing_relationships,
    "John Doe",
    NULL,
    business_partners
  )

  # Should return empty dataframe or dataframe without John Doe
  expect_true(is.data.frame(result))
  # John Doe should have no relationships
  john_relationships <- result %>% filter(`PARTNER (IT)` == "John Doe")
  expect_equal(nrow(john_relationships), 0)
})

test_that("update_relationships handles empty character vector", {
  existing_relationships <- data.frame(
    `PARTNER (IT)` = c("John Doe"),
    `DIRECTORS/MANAGERS` = c("Manager1"),
    `DEPARTMENT (Bus.)` = c("Marketing"),
    DIVISION = c("Div1"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  business_partners <- data.frame(
    Business_Partner = c("Manager1"),
    Department = c("Marketing"),
    Division = c("Div1"),
    stringsAsFactors = FALSE
  )

  # Test with character(0) (should remove all relationships)
  result <- update_relationships(
    existing_relationships,
    "John Doe",
    character(0),
    business_partners
  )

  expect_true(is.data.frame(result))
  john_relationships <- result %>% filter(`PARTNER (IT)` == "John Doe")
  expect_equal(nrow(john_relationships), 0)
})

test_that("update_relationships handles unchecking all then checking some", {
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

  # First, uncheck all (empty)
  result1 <- update_relationships(
    existing_relationships,
    "John Doe",
    character(0),
    business_partners
  )

  expect_equal(nrow(result1), 0)

  # Then, check a new one
  result2 <- update_relationships(
    result1,
    "John Doe",
    c("Manager3"),
    business_partners
  )

  expect_equal(nrow(result2), 1)
  expect_equal(result2$`DIRECTORS/MANAGERS`[1], "Manager3")
})

message("Edge case tests completed!")
