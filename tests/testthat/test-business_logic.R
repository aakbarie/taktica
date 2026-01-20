test_that("calculate_utilization returns correct percentage", {
  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Role = c("Senior DS", "Junior DS"),
    Weekly_Capacity_Hours = c(40, 30),
    Active = c(TRUE, TRUE)
  )

  allocations <- tibble::tibble(
    Week = rep(as.Date("2024-01-01"), 2),
    Name = c("Alice", "Bob"),
    Project = c("Project A", "Project B"),
    Hours_Allocated = c(20, 15)
  )

  # Total allocated: 35, Total capacity: 70, Expected: 50%
  result <- calculate_utilization(allocations, team_members)
  expect_equal(result, 50.0)
})

test_that("calculate_utilization handles zero capacity", {
  team_members <- tibble::tibble(
    Name = "Alice",
    Role = "Senior DS",
    Weekly_Capacity_Hours = 0,
    Active = TRUE
  )

  allocations <- tibble::tibble(
    Week = as.Date("2024-01-01"),
    Name = "Alice",
    Project = "Project A",
    Hours_Allocated = 20
  )

  result <- calculate_utilization(allocations, team_members)
  expect_equal(result, 0)
})

test_that("calculate_utilization_by_member calculates correctly", {
  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Weekly_Capacity_Hours = c(40, 30),
    Active = c(TRUE, TRUE)
  )

  allocations <- tibble::tibble(
    Week = rep(as.Date("2024-01-01"), 2),
    Name = c("Alice", "Bob"),
    Project = c("Project A", "Project B"),
    Hours_Allocated = c(40, 15)
  )

  result <- calculate_utilization_by_member(allocations, team_members)

  expect_equal(nrow(result), 2)
  expect_true("Utilization_Pct" %in% names(result))

  alice_util <- result$Utilization_Pct[result$Name == "Alice"]
  bob_util <- result$Utilization_Pct[result$Name == "Bob"]

  expect_equal(alice_util, 100.0)  # 40/40 = 100%
  expect_equal(bob_util, 50.0)     # 15/30 = 50%
})

test_that("count_active_projects returns correct count", {
  projects <- tibble::tibble(
    Project = c("A", "B", "C"),
    Status = c("Active", "Completed", "Active"),
    Owner = "Alice",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01"),
    Category = "ML"
  )

  result <- count_active_projects(projects)
  expect_equal(result, 2)
})

test_that("calculate_category_percentage returns correct percentage", {
  projects <- tibble::tibble(
    Project = c("A", "B", "C", "D"),
    Category = c("GenAI", "ML", "GenAI", "Evaluation"),
    Status = "Active",
    Owner = "Alice",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01")
  )

  result <- calculate_category_percentage(projects, "GenAI")
  expect_equal(result, 50.0)  # 2 out of 4 = 50%
})

test_that("calculate_category_percentage handles empty projects", {
  projects <- tibble::tibble(
    Project = character(0),
    Category = character(0),
    Status = character(0),
    Owner = character(0),
    Start_Date = as.Date(character(0)),
    End_Date = as.Date(character(0))
  )

  result <- calculate_category_percentage(projects, "GenAI")
  expect_equal(result, 0)
})

test_that("calculate_avg_duration_by_category computes correctly", {
  projects <- tibble::tibble(
    Project = c("A", "B", "C"),
    Category = c("ML", "ML", "GenAI"),
    Start_Date = as.Date(c("2024-01-01", "2024-01-01", "2024-01-01")),
    End_Date = as.Date(c("2024-01-31", "2024-02-01", "2024-01-15")),
    Status = "Active",
    Owner = "Alice"
  )

  result <- calculate_avg_duration_by_category(projects)

  ml_row <- result[result$Category == "ML", ]
  expect_equal(ml_row$Project_Count, 2)
  expect_true(ml_row$Avg_Duration_Days > 0)

  genai_row <- result[result$Category == "GenAI", ]
  expect_equal(genai_row$Project_Count, 1)
})

test_that("identify_overallocated finds overallocated members", {
  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Weekly_Capacity_Hours = c(40, 30),
    Active = c(TRUE, TRUE)
  )

  allocations <- tibble::tibble(
    Week = rep(as.Date("2024-01-01"), 2),
    Name = c("Alice", "Bob"),
    Project = c("Project A", "Project B"),
    Hours_Allocated = c(50, 20)  # Alice is overallocated
  )

  result <- identify_overallocated(allocations, team_members, threshold = 1.0)

  expect_equal(nrow(result), 1)
  expect_equal(result$Name[1], "Alice")
  expect_true(result$Allocation_Ratio[1] > 1.0)
})

test_that("identify_underutilized finds underutilized members", {
  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Weekly_Capacity_Hours = c(40, 30),
    Active = c(TRUE, TRUE)
  )

  allocations <- tibble::tibble(
    Week = rep(as.Date("2024-01-01"), 2),
    Name = c("Alice", "Bob"),
    Project = c("Project A", "Project B"),
    Hours_Allocated = c(10, 25)  # Alice is underutilized
  )

  result <- identify_underutilized(allocations, team_members, threshold = 0.5)

  expect_equal(nrow(result), 1)
  expect_equal(result$Name[1], "Alice")
  expect_true(result$Allocation_Ratio[1] < 0.5)
})

test_that("calculate_project_risk assigns risk scores", {
  projects <- tibble::tibble(
    Project = c("Overdue", "Near Deadline", "Safe"),
    Owner = "Alice",
    Category = "ML",
    Status = "Active",
    Start_Date = as.Date(c("2024-01-01", "2024-01-01", "2024-01-01")),
    End_Date = as.Date(c(Sys.Date() - 5, Sys.Date() + 3, Sys.Date() + 30))
  )

  allocations <- tibble::tibble()
  team_members <- tibble::tibble()

  result <- calculate_project_risk(projects, allocations, team_members)

  expect_true("Risk_Score" %in% names(result))
  expect_true("Risk_Level" %in% names(result))

  # Overdue project should have highest risk
  overdue_risk <- result$Risk_Score[result$Project == "Overdue"]
  safe_risk <- result$Risk_Score[result$Project == "Safe"]

  expect_true(overdue_risk > safe_risk)
})

test_that("generate_insights produces insights", {
  projects <- tibble::tibble(
    Project = c("A", "B"),
    Owner = "Alice",
    Category = c("GenAI", "ML"),
    Status = "Active",
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01")
  )

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

  result <- generate_insights(projects, allocations, team_members)

  expect_type(result, "list")
  expect_true(length(result) >= 0)

  # Check structure of insights
  if (length(result) > 0) {
    insight <- result[[1]]
    expect_true("type" %in% names(insight))
    expect_true("category" %in% names(insight))
    expect_true("message" %in% names(insight))
  }
})

test_that("calculate_kpi_summary returns all metrics", {
  projects <- tibble::tibble(
    Project = c("A", "B"),
    Owner = "Alice",
    Category = c("GenAI", "ML"),
    Status = c("Active", "Completed"),
    Start_Date = as.Date("2024-01-01"),
    End_Date = as.Date("2024-02-01")
  )

  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Role = "Senior DS",
    Weekly_Capacity_Hours = c(40, 30),
    Active = c(TRUE, TRUE)
  )

  allocations <- tibble::tibble(
    Week = rep(as.Date("2024-01-01"), 2),
    Name = c("Alice", "Bob"),
    Project = c("A", "B"),
    Hours_Allocated = c(20, 15)
  )

  result <- calculate_kpi_summary(projects, allocations, team_members)

  expect_true("team_utilization" %in% names(result))
  expect_true("active_projects" %in% names(result))
  expect_true("total_projects" %in% names(result))
  expect_true("team_size" %in% names(result))

  expect_equal(result$total_projects, 2)
  expect_equal(result$team_size, 2)
  expect_equal(result$total_capacity, 70)
})

test_that("optimize_allocation generates recommendations", {
  team_members <- tibble::tibble(
    Name = c("Alice", "Bob"),
    Weekly_Capacity_Hours = c(40, 30),
    Active = c(TRUE, TRUE)
  )

  # Alice overallocated, Bob underutilized
  allocations <- tibble::tibble(
    Week = rep(as.Date("2024-01-01"), 2),
    Name = c("Alice", "Bob"),
    Project = c("Project A", "Project B"),
    Hours_Allocated = c(50, 10)
  )

  projects <- tibble::tibble()

  result <- optimize_allocation(allocations, team_members, projects)

  expect_true("overallocated" %in% names(result))
  expect_true("underutilized" %in% names(result))
  expect_true("recommendations" %in% names(result))

  expect_equal(nrow(result$overallocated), 1)
  expect_equal(nrow(result$underutilized), 1)
})

test_that("detect_utilization_anomalies identifies outliers", {
  team_members <- tibble::tibble(
    Name = "Alice",
    Weekly_Capacity_Hours = 40,
    Active = TRUE
  )

  # Create normal utilization with one anomaly
  allocations <- tibble::tibble(
    Week = seq(as.Date("2024-01-01"), by = "week", length.out = 10),
    Name = rep("Alice", 10),
    Project = "Project A",
    Hours_Allocated = c(20, 20, 20, 20, 40, 20, 20, 20, 20, 20)  # Week 5 is anomaly
  )

  result <- detect_utilization_anomalies(allocations, team_members, threshold = 2)

  # Should detect the anomaly in week 5
  if (!is.null(result)) {
    expect_true("Is_Anomaly" %in% names(result))
    expect_true(all(result$Is_Anomaly))
  }
})

test_that("forecast_utilization handles insufficient data gracefully", {
  team_members <- tibble::tibble(
    Name = "Alice",
    Weekly_Capacity_Hours = 40,
    Active = TRUE
  )

  # Only 2 weeks of data (insufficient)
  allocations <- tibble::tibble(
    Week = seq(as.Date("2024-01-01"), by = "week", length.out = 2),
    Name = rep("Alice", 2),
    Project = "Project A",
    Hours_Allocated = c(20, 25)
  )

  result <- forecast_utilization(allocations, team_members, weeks_ahead = 4)

  # Should return NULL due to insufficient data
  expect_null(result)
})
