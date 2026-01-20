test_that("build_data_context creates valid context string", {
  projects <- tibble::tibble(
    Project = c("Project A", "Project B"),
    Owner = c("Alice", "Bob"),
    Category = c("GenAI", "ML"),
    Status = c("Active", "Completed"),
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01")
  )

  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Role = c("Senior DS", "Junior DS"),
    Weekly_Capacity_Hours = c(40, 30),
    Active = c(TRUE, TRUE)
  )

  allocations <- tibble::tibble(
    Week = as.Date("2024-01-01"),
    Name = c("Alice", "Bob"),
    Project = c("Project A", "Project B"),
    Hours_Allocated = c(20, 15)
  )

  context <- build_data_context(projects, allocations, team_members)

  expect_type(context, "character")
  expect_true(nchar(context) > 0)

  # Check that key information is included
  expect_match(context, "Team Size")
  expect_match(context, "Active Projects")
  expect_match(context, "Alice")
  expect_match(context, "Project A")
})

test_that("analyze_query_intent detects utilization queries", {
  projects <- tibble::tibble()
  allocations <- tibble::tibble()
  team_members <- tibble::tibble(Name = "Alice", Role = "DS", Weekly_Capacity_Hours = 40)

  query <- "What is our current utilization?"
  intent <- analyze_query_intent(query, projects, allocations, team_members)

  expect_equal(intent$type, "utilization")
  expect_true(intent$requires_calculation)
  expect_equal(intent$specific_metric, "utilization")
})

test_that("analyze_query_intent detects project count queries", {
  projects <- tibble::tibble()
  allocations <- tibble::tibble()
  team_members <- tibble::tibble(Name = "Alice", Role = "DS", Weekly_Capacity_Hours = 40)

  query <- "How many projects do we have?"
  intent <- analyze_query_intent(query, projects, allocations, team_members)

  expect_equal(intent$type, "project_count")
  expect_true(intent$requires_calculation)
})

test_that("analyze_query_intent detects risk queries", {
  projects <- tibble::tibble()
  allocations <- tibble::tibble()
  team_members <- tibble::tibble(Name = "Alice", Role = "DS", Weekly_Capacity_Hours = 40)

  query <- "Which projects are at risk?"
  intent <- analyze_query_intent(query, projects, allocations, team_members)

  expect_equal(intent$type, "risk")
  expect_equal(intent$specific_metric, "risk")
})

test_that("analyze_query_intent detects team member queries", {
  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Role = "DS",
    Weekly_Capacity_Hours = 40
  )

  query <- "What is Alice working on?"
  intent <- analyze_query_intent(query, tibble::tibble(), tibble::tibble(), team_members)

  expect_equal(intent$type, "team_member")
  expect_equal(intent$specific_member, "Alice")
})

test_that("answer_query_direct handles utilization queries", {
  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Role = "Senior DS",
    Weekly_Capacity_Hours = c(40, 30),
    Active = c(TRUE, TRUE)
  )

  allocations <- tibble::tibble(
    Week = as.Date("2024-01-01"),
    Name = c("Alice", "Bob"),
    Project = c("A", "B"),
    Hours_Allocated = c(20, 15)
  )

  projects <- tibble::tibble()

  result <- answer_query_direct("What is our utilization?", projects, allocations, team_members)

  expect_true(result$success)
  expect_false(result$used_ai)
  expect_match(result$response, "50.0%")
})

test_that("answer_query_direct handles project count queries", {
  projects <- tibble::tibble(
    Project = c("A", "B", "C"),
    Status = c("Active", "Completed", "Active"),
    Owner = "Alice",
    Category = "ML",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01")
  )

  result <- answer_query_direct("How many projects?", projects, tibble::tibble(), tibble::tibble())

  expect_true(result$success)
  expect_match(result$response, "2 active projects")
  expect_match(result$response, "3 total projects")
})

test_that("answer_query_direct handles risk queries", {
  projects <- tibble::tibble(
    Project = c("Safe Project"),
    Owner = "Alice",
    Category = "ML",
    Status = "Active",
    Start_Date = as.Date("2024-01-01"),
    End_Date = Sys.Date() + 30
  )

  result <- answer_query_direct("What projects are at risk?",
                                projects, tibble::tibble(), tibble::tibble())

  expect_true(result$success)
  expect_match(result$response, "No high-risk projects|on track")
})

test_that("answer_query_direct handles overallocation queries", {
  team_members <- tibble::tibble(
    Name = "Alice",
    Role = "Senior DS",
    Weekly_Capacity_Hours = 40,
    Active = TRUE
  )

  allocations <- tibble::tibble(
    Week = as.Date("2024-01-01"),
    Name = "Alice",
    Project = "A",
    Hours_Allocated = 20
  )

  result <- answer_query_direct("Who is overallocated?",
                                tibble::tibble(), allocations, team_members)

  expect_true(result$success)
  expect_match(result$response, "No team members are currently overallocated")
})

test_that("answer_query_direct returns NULL for complex queries", {
  result <- answer_query_direct("Tell me a complex analysis of everything",
                                tibble::tibble(), tibble::tibble(), tibble::tibble())

  expect_null(result)
})

test_that("get_query_suggestions returns valid suggestions", {
  projects <- tibble::tibble(
    Project = "Test Project",
    Owner = "Alice",
    Category = "ML",
    Status = "Active",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01")
  )

  suggestions <- get_query_suggestions(projects, tibble::tibble(), tibble::tibble())

  expect_type(suggestions, "character")
  expect_true(length(suggestions) > 0)
  expect_true(any(grepl("project load", suggestions)))
  expect_true(any(grepl("Test Project", suggestions)))
})

test_that("handle_query uses direct answer when possible", {
  team_members <- tibble::tibble(
    Name = "Alice",
    Weekly_Capacity_Hours = 40,
    Role = "DS",
    Active = TRUE
  )

  allocations <- tibble::tibble(
    Week = as.Date("2024-01-01"),
    Name = "Alice",
    Project = "A",
    Hours_Allocated = 20
  )

  projects <- tibble::tibble()

  result <- handle_query("What is our utilization?", projects, allocations, team_members, use_ai = FALSE)

  expect_true(result$success)
  expect_false(result$used_ai)
})

test_that("handle_query provides fallback for unknown queries", {
  result <- handle_query("Random nonsense query",
                        tibble::tibble(), tibble::tibble(), tibble::tibble(),
                        use_ai = FALSE)

  expect_true(result$success)
  expect_false(result$used_ai)
  expect_match(result$response, "don't have enough information|try rephrasing")
})

test_that("call_ollama_api handles connection errors gracefully", {
  # This will fail because Ollama isn't running
  result <- call_ollama_api("test prompt", url = "http://localhost:99999", timeout = 1)

  expect_false(result$success)
  expect_true(result$offline || !is.null(result$response))
})
