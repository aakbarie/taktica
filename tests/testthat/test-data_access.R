test_that("validate_project catches missing required fields", {
  # Missing project name
  project <- list(
    Project = "",
    Owner = "John",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01"),
    Category = "ML",
    Status = "Active"
  )

  result <- validate_project(project)
  expect_false(result$valid)
  expect_match(result$message, "Project name is required")
})

test_that("validate_project catches invalid date ranges", {
  project <- list(
    Project = "Test Project",
    Owner = "John",
    Start_Date = as.Date("2024-02-01"),
    End_Date = as.Date("2024-01-01"),  # End before start
    Category = "ML",
    Status = "Active"
  )

  result <- validate_project(project)
  expect_false(result$valid)
  expect_match(result$message, "End date must be after start date")
})

test_that("validate_project accepts valid project", {
  project <- list(
    Project = "Valid Project",
    Owner = "John",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01"),
    Category = "ML",
    Status = "Active"
  )

  result <- validate_project(project)
  expect_true(result$valid)
  expect_equal(result$message, "Valid")
})

test_that("validate_project checks owner exists in team", {
  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Role = c("Senior DS", "Junior DS"),
    Weekly_Capacity_Hours = c(40, 30)
  )

  project <- list(
    Project = "Test Project",
    Owner = "Charlie",  # Not in team
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01"),
    Category = "ML",
    Status = "Active"
  )

  result <- validate_project(project, team_members)
  expect_false(result$valid)
  expect_match(result$message, "not found in team members")
})

test_that("validate_project rejects invalid category", {
  project <- list(
    Project = "Test Project",
    Owner = "John",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01"),
    Category = "InvalidCategory",
    Status = "Active"
  )

  result <- validate_project(project)
  expect_false(result$valid)
  expect_match(result$message, "Category must be one of")
})

test_that("validate_team_member catches invalid capacity", {
  member <- list(
    Name = "John",
    Role = "Senior DS",
    Weekly_Capacity_Hours = 200  # More than 168 hours in a week
  )

  result <- validate_team_member(member)
  expect_false(result$valid)
  expect_match(result$message, "between 0 and 168")
})

test_that("validate_team_member catches negative capacity", {
  member <- list(
    Name = "John",
    Role = "Senior DS",
    Weekly_Capacity_Hours = -10
  )

  result <- validate_team_member(member)
  expect_false(result$valid)
  expect_match(result$message, "between 0 and 168")
})

test_that("validate_team_member catches invalid email", {
  member <- list(
    Name = "John",
    Role = "Senior DS",
    Weekly_Capacity_Hours = 40,
    Email = "not-an-email"
  )

  result <- validate_team_member(member)
  expect_false(result$valid)
  expect_match(result$message, "Invalid email format")
})

test_that("validate_team_member accepts valid member", {
  member <- list(
    Name = "John",
    Role = "Senior DS",
    Weekly_Capacity_Hours = 40,
    Email = "john@company.com"
  )

  result <- validate_team_member(member)
  expect_true(result$valid)
})

test_that("validate_allocation catches negative hours", {
  allocation <- list(
    Week = as.Date("2024-01-01"),
    Name = "John",
    Project = "Test",
    Hours_Allocated = -5
  )

  result <- validate_allocation(allocation)
  expect_false(result$valid)
  expect_match(result$message, "non-negative")
})

test_that("validate_allocation checks hours against capacity", {
  team_members <- tibble::tibble(
    Name = "John",
    Role = "Senior DS",
    Weekly_Capacity_Hours = 40
  )

  allocation <- list(
    Week = as.Date("2024-01-01"),
    Name = "John",
    Project = "Test",
    Hours_Allocated = 50  # Exceeds capacity
  )

  result <- validate_allocation(allocation, team_members)
  expect_false(result$valid)
  expect_match(result$message, "exceed capacity")
})

test_that("validate_allocation accepts valid allocation", {
  team_members <- tibble::tibble(
    Name = "John",
    Role = "Senior DS",
    Weekly_Capacity_Hours = 40
  )

  allocation <- list(
    Week = as.Date("2024-01-01"),
    Name = "John",
    Project = "Test",
    Hours_Allocated = 30
  )

  result <- validate_allocation(allocation, team_members)
  expect_true(result$valid)
})

test_that("initialize_data creates valid data structures", {
  data <- initialize_data()

  expect_true("projects" %in% names(data))
  expect_true("team_members" %in% names(data))
  expect_true("allocations" %in% names(data))

  expect_s3_class(data$projects, "data.frame")
  expect_s3_class(data$team_members, "data.frame")
  expect_s3_class(data$allocations, "data.frame")

  expect_gt(nrow(data$projects), 0)
  expect_gt(nrow(data$team_members), 0)
  expect_gt(nrow(data$allocations), 0)
})

test_that("initialize_data creates projects with required columns", {
  data <- initialize_data()

  required_cols <- c("Project", "Owner", "Start_Date", "End_Date",
                     "Category", "Status", "Created_At", "Updated_At")

  expect_true(all(required_cols %in% names(data$projects)))
})

test_that("initialize_data creates team_members with required columns", {
  data <- initialize_data()

  required_cols <- c("Name", "Role", "Weekly_Capacity_Hours",
                     "Email", "Active", "Created_At")

  expect_true(all(required_cols %in% names(data$team_members)))
})

test_that("add_project rejects duplicate project names", {
  # Setup temporary data directory
  temp_dir <- tempdir()
  config::get <- function() list(data_dir = temp_dir)

  # Initialize data
  data <- initialize_data()
  save_projects(data$projects)

  # Try to add duplicate
  duplicate <- list(
    Project = data$projects$Project[1],  # Use existing name
    Owner = "Someone",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01"),
    Category = "ML",
    Status = "Active"
  )

  result <- add_project(duplicate)
  expect_false(result$success)
  expect_match(result$message, "already exists")
})

test_that("add_project adds valid project successfully", {
  temp_dir <- tempdir()
  config::get <- function() list(data_dir = temp_dir)

  data <- initialize_data()
  save_projects(data$projects)

  new_project <- list(
    Project = "Brand New Project",
    Owner = "Alice",
    Start_Date = as.Date("2024-03-01"),
    End_Date = as.Date("2024-04-01"),
    Category = "GenAI",
    Status = "Active"
  )

  result <- add_project(new_project)
  expect_true(result$success)

  # Verify it was added
  projects <- load_projects()
  expect_true("Brand New Project" %in% projects$Project)
})

test_that("update_project modifies existing project", {
  temp_dir <- tempdir()
  config::get <- function() list(data_dir = temp_dir)

  data <- initialize_data()
  save_projects(data$projects)

  old_name <- data$projects$Project[1]
  updated_project <- list(
    Project = paste(old_name, "Updated"),
    Owner = "NewOwner",
    Start_Date = as.Date("2024-05-01"),
    End_Date = as.Date("2024-06-01"),
    Category = "ML",
    Status = "On Hold"
  )

  result <- update_project(old_name, updated_project)
  expect_true(result$success)

  # Verify update
  projects <- load_projects()
  expect_false(old_name %in% projects$Project)
  expect_true(paste(old_name, "Updated") %in% projects$Project)
})

test_that("delete_project removes project", {
  temp_dir <- tempdir()
  config::get <- function() list(data_dir = temp_dir)

  data <- initialize_data()
  save_projects(data$projects)

  project_to_delete <- data$projects$Project[1]
  result <- delete_project(project_to_delete)

  expect_true(result$success)

  # Verify deletion
  projects <- load_projects()
  expect_false(project_to_delete %in% projects$Project)
})

test_that("delete_project returns error for non-existent project", {
  temp_dir <- tempdir()
  config::get <- function() list(data_dir = temp_dir)

  data <- initialize_data()
  save_projects(data$projects)

  result <- delete_project("NonExistentProject")
  expect_false(result$success)
  expect_match(result$message, "not found")
})
