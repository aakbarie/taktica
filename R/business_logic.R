#' Business Logic Layer for Taktica
#'
#' Provides KPI calculations, analytics, forecasting, and recommendations
#' @importFrom dplyr filter group_by summarise mutate arrange left_join
#' @importFrom lubridate weeks days
#' @importFrom forecast auto.arima forecast
#' @importFrom logger log_info log_warn
#' @importFrom stats lm predict

#' Calculate team utilization percentage
#' @param allocations Data frame of allocations
#' @param team_members Data frame of team members
#' @param week Optional specific week to calculate (defaults to all)
#' @export
calculate_utilization <- function(allocations, team_members, week = NULL) {
  if (!is.null(week)) {
    allocations <- allocations %>% dplyr::filter(Week == week)
  }

  total_allocated <- sum(allocations$Hours_Allocated, na.rm = TRUE)
  total_capacity <- sum(team_members$Weekly_Capacity_Hours[team_members$Active], na.rm = TRUE)

  if (total_capacity == 0) {
    logger::log_warn("Total capacity is zero")
    return(0)
  }

  weeks_in_data <- length(unique(allocations$Week))
  if (weeks_in_data > 1 && is.null(week)) {
    total_capacity <- total_capacity * weeks_in_data
  }

  utilization <- (total_allocated / total_capacity) * 100
  round(utilization, 1)
}

#' Calculate utilization by team member
#' @export
calculate_utilization_by_member <- function(allocations, team_members) {
  allocations %>%
    dplyr::group_by(Name) %>%
    dplyr::summarise(
      Total_Allocated = sum(Hours_Allocated, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::left_join(
      team_members %>% dplyr::select(Name, Weekly_Capacity_Hours),
      by = "Name"
    ) %>%
    dplyr::mutate(
      Weeks = length(unique(allocations$Week)),
      Total_Capacity = Weekly_Capacity_Hours * Weeks,
      Utilization_Pct = round((Total_Allocated / Total_Capacity) * 100, 1)
    ) %>%
    dplyr::arrange(desc(Utilization_Pct))
}

#' Calculate utilization trend over time
#' @export
calculate_utilization_trend <- function(allocations, team_members) {
  allocations %>%
    dplyr::group_by(Week) %>%
    dplyr::summarise(
      Total_Allocated = sum(Hours_Allocated, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      Total_Capacity = sum(team_members$Weekly_Capacity_Hours[team_members$Active]),
      Utilization_Pct = round((Total_Allocated / Total_Capacity) * 100, 1)
    ) %>%
    dplyr::arrange(Week)
}

#' Count active projects
#' @export
count_active_projects <- function(projects) {
  active <- projects %>%
    dplyr::filter(Status == "Active")
  nrow(active)
}

#' Calculate percentage of projects by category
#' @export
calculate_category_percentage <- function(projects, category) {
  if (nrow(projects) == 0) return(0)

  count <- sum(projects$Category == category, na.rm = TRUE)
  percentage <- (count / nrow(projects)) * 100
  round(percentage, 1)
}

#' Get project completion statistics
#' @export
get_project_completion_stats <- function(projects) {
  projects %>%
    dplyr::group_by(Status) %>%
    dplyr::summarise(
      Count = n(),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      Percentage = round((Count / sum(Count)) * 100, 1)
    )
}

#' Calculate average project duration by category
#' @export
calculate_avg_duration_by_category <- function(projects) {
  projects %>%
    dplyr::mutate(
      Duration_Days = as.numeric(End_Date - Start_Date)
    ) %>%
    dplyr::group_by(Category) %>%
    dplyr::summarise(
      Avg_Duration_Days = round(mean(Duration_Days, na.rm = TRUE), 1),
      Min_Duration_Days = min(Duration_Days, na.rm = TRUE),
      Max_Duration_Days = max(Duration_Days, na.rm = TRUE),
      Project_Count = n(),
      .groups = "drop"
    ) %>%
    dplyr::arrange(desc(Avg_Duration_Days))
}

#' Identify overallocated team members
#' @export
identify_overallocated <- function(allocations, team_members, threshold = 1.0) {
  allocations %>%
    dplyr::group_by(Week, Name) %>%
    dplyr::summarise(
      Weekly_Allocated = sum(Hours_Allocated, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::left_join(
      team_members %>% dplyr::select(Name, Weekly_Capacity_Hours),
      by = "Name"
    ) %>%
    dplyr::mutate(
      Allocation_Ratio = Weekly_Allocated / Weekly_Capacity_Hours
    ) %>%
    dplyr::filter(Allocation_Ratio > threshold) %>%
    dplyr::arrange(desc(Allocation_Ratio))
}

#' Identify underutilized team members
#' @export
identify_underutilized <- function(allocations, team_members, threshold = 0.5) {
  allocations %>%
    dplyr::group_by(Week, Name) %>%
    dplyr::summarise(
      Weekly_Allocated = sum(Hours_Allocated, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::left_join(
      team_members %>% dplyr::select(Name, Weekly_Capacity_Hours),
      by = "Name"
    ) %>%
    dplyr::mutate(
      Allocation_Ratio = Weekly_Allocated / Weekly_Capacity_Hours
    ) %>%
    dplyr::filter(Allocation_Ratio < threshold) %>%
    dplyr::arrange(Allocation_Ratio)
}

#' Calculate project risk score based on various factors
#' @export
calculate_project_risk <- function(projects, allocations, team_members) {
  today <- Sys.Date()

  projects %>%
    dplyr::mutate(
      # Time-based risk
      Days_Remaining = as.numeric(End_Date - today),
      Days_Total = as.numeric(End_Date - Start_Date),
      Percent_Complete_Time = ifelse(Days_Total > 0,
                                     (Days_Total - Days_Remaining) / Days_Total * 100,
                                     0),

      # Risk factors
      Risk_Overdue = ifelse(Days_Remaining < 0, 1, 0),
      Risk_Near_Deadline = ifelse(Days_Remaining >= 0 & Days_Remaining <= 7, 0.7, 0),
      Risk_Long_Duration = ifelse(Days_Total > 90, 0.3, 0),

      # Calculate total risk score (0-10 scale)
      Risk_Score = (Risk_Overdue * 10) +
                   (Risk_Near_Deadline * 10) +
                   (Risk_Long_Duration * 10)
    ) %>%
    dplyr::mutate(
      Risk_Score = pmin(Risk_Score, 10),  # Cap at 10
      Risk_Level = dplyr::case_when(
        Risk_Score >= 7 ~ "High",
        Risk_Score >= 4 ~ "Medium",
        TRUE ~ "Low"
      )
    ) %>%
    dplyr::select(Project, Owner, Category, Status,
                 Days_Remaining, Percent_Complete_Time,
                 Risk_Score, Risk_Level) %>%
    dplyr::arrange(desc(Risk_Score))
}

#' Forecast future capacity utilization using time series
#' @param allocations Historical allocation data
#' @param team_members Team member data
#' @param weeks_ahead Number of weeks to forecast
#' @export
forecast_utilization <- function(allocations, team_members, weeks_ahead = 4) {
  tryCatch({
    # Calculate historical utilization
    historical <- calculate_utilization_trend(allocations, team_members)

    if (nrow(historical) < 4) {
      logger::log_warn("Insufficient data for forecasting (need at least 4 weeks)")
      return(NULL)
    }

    # Create time series
    ts_data <- ts(historical$Utilization_Pct, frequency = 52)  # Weekly data

    # Fit ARIMA model
    fit <- forecast::auto.arima(ts_data, seasonal = FALSE)

    # Forecast
    forecasted <- forecast::forecast(fit, h = weeks_ahead)

    # Create result data frame
    last_week <- max(historical$Week)
    future_weeks <- seq(last_week + lubridate::weeks(1),
                       by = "week",
                       length.out = weeks_ahead)

    forecast_df <- tibble::tibble(
      Week = future_weeks,
      Forecast_Utilization = round(as.numeric(forecasted$mean), 1),
      Lower_80 = round(as.numeric(forecasted$lower[, 1]), 1),
      Upper_80 = round(as.numeric(forecasted$upper[, 1]), 1),
      Lower_95 = round(as.numeric(forecasted$lower[, 2]), 1),
      Upper_95 = round(as.numeric(forecasted$upper[, 2]), 1)
    )

    logger::log_info(sprintf("Forecasted utilization for %d weeks", weeks_ahead))
    forecast_df

  }, error = function(e) {
    logger::log_error(sprintf("Forecasting failed: %s", e$message))
    NULL
  })
}

#' Predict project completion date based on historical data
#' @export
predict_completion_date <- function(project, similar_projects) {
  if (nrow(similar_projects) < 3) {
    logger::log_warn("Insufficient similar projects for prediction")
    return(NULL)
  }

  # Calculate average duration for similar projects
  similar_projects <- similar_projects %>%
    dplyr::filter(Category == project$Category, Status == "Completed") %>%
    dplyr::mutate(Duration_Days = as.numeric(End_Date - Start_Date))

  if (nrow(similar_projects) == 0) {
    return(NULL)
  }

  avg_duration <- mean(similar_projects$Duration_Days, na.rm = TRUE)
  sd_duration <- sd(similar_projects$Duration_Days, na.rm = TRUE)

  predicted_end <- project$Start_Date + lubridate::days(round(avg_duration))

  list(
    predicted_end_date = predicted_end,
    confidence_days = round(sd_duration, 1),
    sample_size = nrow(similar_projects)
  )
}

#' Optimize resource allocation to balance workload
#' @export
optimize_allocation <- function(allocations, team_members, projects) {
  # Calculate current utilization per member
  current_util <- calculate_utilization_by_member(allocations, team_members)

  # Find overallocated and underutilized members
  overallocated <- current_util %>%
    dplyr::filter(Utilization_Pct > 100) %>%
    dplyr::arrange(desc(Utilization_Pct))

  underutilized <- current_util %>%
    dplyr::filter(Utilization_Pct < 80) %>%
    dplyr::arrange(Utilization_Pct)

  recommendations <- list()

  # Generate recommendations
  if (nrow(overallocated) > 0 && nrow(underutilized) > 0) {
    for (i in 1:min(nrow(overallocated), nrow(underutilized))) {
      over_person <- overallocated$Name[i]
      under_person <- underutilized$Name[i]
      hours_to_move <- round((overallocated$Utilization_Pct[i] - 100) *
                            overallocated$Weekly_Capacity_Hours[i] / 100, 0)

      recommendations[[length(recommendations) + 1]] <- list(
        action = "rebalance",
        from = over_person,
        to = under_person,
        hours = hours_to_move,
        reason = sprintf("%s is overallocated (%.1f%%), %s has capacity (%.1f%%)",
                        over_person, overallocated$Utilization_Pct[i],
                        under_person, underutilized$Utilization_Pct[i])
      )
    }
  }

  list(
    overallocated = overallocated,
    underutilized = underutilized,
    recommendations = recommendations
  )
}

#' Generate automated insights from data
#' @export
generate_insights <- function(projects, allocations, team_members) {
  insights <- list()

  # Utilization insights
  util <- calculate_utilization(allocations, team_members)
  if (util > 95) {
    insights[[length(insights) + 1]] <- list(
      type = "warning",
      category = "utilization",
      message = sprintf("Team is operating at %.1f%% capacity. Consider hiring or reducing commitments.", util)
    )
  } else if (util < 60) {
    insights[[length(insights) + 1]] <- list(
      type = "info",
      category = "utilization",
      message = sprintf("Team has %.1f%% spare capacity. Consider taking on new projects.", 100 - util)
    )
  }

  # Project distribution insights
  active_count <- count_active_projects(projects)
  if (active_count > 10) {
    insights[[length(insights) + 1]] <- list(
      type = "warning",
      category = "projects",
      message = sprintf("%d active projects may be too many to manage effectively.", active_count)
    )
  }

  # Risk insights
  risks <- calculate_project_risk(projects, allocations, team_members)
  high_risk <- risks %>% dplyr::filter(Risk_Level == "High")

  if (nrow(high_risk) > 0) {
    insights[[length(insights) + 1]] <- list(
      type = "alert",
      category = "risk",
      message = sprintf("%d project(s) at high risk: %s",
                       nrow(high_risk),
                       paste(high_risk$Project, collapse = ", "))
    )
  }

  # Overallocation insights
  overalloc <- identify_overallocated(allocations, team_members, threshold = 1.0)
  if (nrow(overalloc) > 0) {
    unique_members <- unique(overalloc$Name)
    insights[[length(insights) + 1]] <- list(
      type = "warning",
      category = "allocation",
      message = sprintf("Team member(s) overallocated: %s",
                       paste(unique_members, collapse = ", "))
    )
  }

  # Category insights
  genai_pct <- calculate_category_percentage(projects, "GenAI")
  if (genai_pct > 50) {
    insights[[length(insights) + 1]] <- list(
      type = "info",
      category = "trends",
      message = sprintf("GenAI projects represent %.1f%% of portfolio - strong focus on emerging tech.", genai_pct)
    )
  }

  insights
}

#' Calculate KPI summary
#' @export
calculate_kpi_summary <- function(projects, allocations, team_members) {
  list(
    team_utilization = calculate_utilization(allocations, team_members),
    active_projects = count_active_projects(projects),
    total_projects = nrow(projects),
    genai_percentage = calculate_category_percentage(projects, "GenAI"),
    ml_percentage = calculate_category_percentage(projects, "ML"),
    evaluation_percentage = calculate_category_percentage(projects, "Evaluation"),
    team_size = sum(team_members$Active),
    total_capacity = sum(team_members$Weekly_Capacity_Hours[team_members$Active]),
    avg_utilization_per_member = mean(
      calculate_utilization_by_member(allocations, team_members)$Utilization_Pct,
      na.rm = TRUE
    )
  )
}

#' Detect anomalies in utilization patterns
#' @export
detect_utilization_anomalies <- function(allocations, team_members, threshold = 2) {
  trend <- calculate_utilization_trend(allocations, team_members)

  if (nrow(trend) < 5) {
    return(NULL)
  }

  # Calculate rolling statistics
  mean_util <- mean(trend$Utilization_Pct, na.rm = TRUE)
  sd_util <- sd(trend$Utilization_Pct, na.rm = TRUE)

  # Identify anomalies (beyond threshold standard deviations)
  trend %>%
    dplyr::mutate(
      Z_Score = (Utilization_Pct - mean_util) / sd_util,
      Is_Anomaly = abs(Z_Score) > threshold,
      Anomaly_Type = dplyr::case_when(
        Z_Score > threshold ~ "Unusually High",
        Z_Score < -threshold ~ "Unusually Low",
        TRUE ~ "Normal"
      )
    ) %>%
    dplyr::filter(Is_Anomaly) %>%
    dplyr::arrange(Week)
}
