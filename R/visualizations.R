#' Advanced Visualizations for Taktica
#'
#' Provides Gantt charts, heatmaps, trend analysis, and interactive visualizations
#' @importFrom plotly plot_ly layout add_trace
#' @importFrom dplyr filter group_by summarise arrange mutate
#' @importFrom tidyr pivot_wider
#' @importFrom scales percent
#' @importFrom ggplot2 ggplot aes geom_tile geom_text scale_fill_gradient theme_minimal labs

#' Create Gantt chart for project timelines
#' @param projects Projects data frame
#' @export
create_gantt_chart <- function(projects) {
  if (nrow(projects) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "No projects to display"))
  }

  # Prepare data for Gantt chart
  gantt_data <- projects %>%
    dplyr::arrange(Start_Date) %>%
    dplyr::mutate(
      Duration_Days = as.numeric(End_Date - Start_Date),
      Project_Label = paste0(Project, " (", Owner, ")")
    )

  # Color mapping for status
  color_map <- list(
    "Active" = "#1f77b4",
    "Completed" = "#2ca02c",
    "On Hold" = "#ff7f0e",
    "Cancelled" = "#d62728"
  )

  # Create Gantt chart
  fig <- plotly::plot_ly()

  for (status in unique(gantt_data$Status)) {
    status_data <- gantt_data[gantt_data$Status == status, ]

    fig <- fig %>%
      plotly::add_trace(
        data = status_data,
        x = ~Start_Date,
        y = ~Project_Label,
        xend = ~End_Date,
        type = "scatter",
        mode = "lines",
        line = list(color = color_map[[status]], width = 20),
        name = status,
        text = ~paste0(
          "<b>", Project, "</b><br>",
          "Owner: ", Owner, "<br>",
          "Category: ", Category, "<br>",
          "Start: ", Start_Date, "<br>",
          "End: ", End_Date, "<br>",
          "Duration: ", Duration_Days, " days"
        ),
        hoverinfo = "text"
      )
  }

  # Add today's date line
  fig <- fig %>%
    plotly::layout(
      title = "Project Timeline (Gantt Chart)",
      xaxis = list(
        title = "Date",
        type = "date",
        showgrid = TRUE
      ),
      yaxis = list(
        title = "",
        categoryorder = "trace"
      ),
      hovermode = "closest",
      showlegend = TRUE,
      shapes = list(
        list(
          type = "line",
          x0 = Sys.Date(),
          x1 = Sys.Date(),
          y0 = 0,
          y1 = 1,
          yref = "paper",
          line = list(color = "red", width = 2, dash = "dash"),
          name = "Today"
        )
      )
    )

  fig
}

#' Create utilization heatmap by team member and week
#' @param allocations Allocations data
#' @param team_members Team members data
#' @export
create_utilization_heatmap <- function(allocations, team_members) {
  if (nrow(allocations) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "No allocation data"))
  }

  # Calculate utilization per member per week
  heatmap_data <- allocations %>%
    dplyr::group_by(Week, Name) %>%
    dplyr::summarise(Total_Hours = sum(Hours_Allocated, na.rm = TRUE),
                    .groups = "drop") %>%
    dplyr::left_join(
      team_members %>% dplyr::select(Name, Weekly_Capacity_Hours),
      by = "Name"
    ) %>%
    dplyr::mutate(
      Utilization_Pct = round((Total_Hours / Weekly_Capacity_Hours) * 100, 1)
    )

  # Create heatmap
  fig <- plotly::plot_ly(
    data = heatmap_data,
    x = ~Week,
    y = ~Name,
    z = ~Utilization_Pct,
    type = "heatmap",
    colorscale = list(
      c(0, "lightblue"),
      c(0.5, "yellow"),
      c(0.8, "orange"),
      c(1, "red")
    ),
    text = ~paste0(
      Name, "<br>",
      "Week: ", Week, "<br>",
      "Utilization: ", Utilization_Pct, "%<br>",
      "Hours: ", Total_Hours, " / ", Weekly_Capacity_Hours
    ),
    hoverinfo = "text",
    colorbar = list(title = "Utilization %")
  ) %>%
    plotly::layout(
      title = "Team Utilization Heatmap",
      xaxis = list(title = "Week"),
      yaxis = list(title = "Team Member")
    )

  fig
}

#' Create capacity bar chart with stacking by project
#' @param allocations Allocations data
#' @export
create_capacity_chart <- function(allocations) {
  if (nrow(allocations) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "No allocation data"))
  }

  # Prepare data
  capacity_data <- allocations %>%
    dplyr::filter(!is.na(Project)) %>%
    dplyr::group_by(Week, Name, Project) %>%
    dplyr::summarise(Hours = sum(Hours_Allocated, na.rm = TRUE),
                    .groups = "drop")

  # Create stacked bar chart
  fig <- plotly::plot_ly(
    data = capacity_data,
    x = ~Week,
    y = ~Hours,
    color = ~Name,
    type = "bar",
    text = ~paste0(Name, ": ", Hours, " hrs"),
    hoverinfo = "text"
  ) %>%
    plotly::layout(
      title = "Weekly Capacity Allocation",
      xaxis = list(title = "Week"),
      yaxis = list(title = "Hours Allocated"),
      barmode = "stack"
    )

  fig
}

#' Create utilization trend line chart
#' @param allocations Allocations data
#' @param team_members Team members data
#' @export
create_utilization_trend <- function(allocations, team_members) {
  trend_data <- calculate_utilization_trend(allocations, team_members)

  if (nrow(trend_data) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "No trend data"))
  }

  fig <- plotly::plot_ly(
    data = trend_data,
    x = ~Week,
    y = ~Utilization_Pct,
    type = "scatter",
    mode = "lines+markers",
    line = list(color = "#1f77b4", width = 3),
    marker = list(size = 8),
    text = ~paste0(
      "Week: ", Week, "<br>",
      "Utilization: ", Utilization_Pct, "%"
    ),
    hoverinfo = "text"
  ) %>%
    plotly::layout(
      title = "Utilization Trend Over Time",
      xaxis = list(title = "Week"),
      yaxis = list(
        title = "Utilization %",
        range = c(0, max(110, max(trend_data$Utilization_Pct, na.rm = TRUE) + 10))
      ),
      shapes = list(
        # Add target utilization line at 80%
        list(
          type = "line",
          x0 = min(trend_data$Week),
          x1 = max(trend_data$Week),
          y0 = 80,
          y1 = 80,
          line = list(color = "green", width = 2, dash = "dash")
        ),
        # Add warning line at 100%
        list(
          type = "line",
          x0 = min(trend_data$Week),
          x1 = max(trend_data$Week),
          y0 = 100,
          y1 = 100,
          line = list(color = "red", width = 2, dash = "dash")
        )
      ),
      annotations = list(
        list(
          x = max(trend_data$Week),
          y = 80,
          text = "Target (80%)",
          showarrow = FALSE,
          xanchor = "left"
        ),
        list(
          x = max(trend_data$Week),
          y = 100,
          text = "Capacity (100%)",
          showarrow = FALSE,
          xanchor = "left"
        )
      )
    )

  fig
}

#' Create project distribution pie chart
#' @param projects Projects data
#' @param by_field Field to group by (Category, Status, Owner)
#' @export
create_project_distribution <- function(projects, by_field = "Category") {
  if (nrow(projects) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "No projects"))
  }

  dist_data <- projects %>%
    dplyr::group_by(!!rlang::sym(by_field)) %>%
    dplyr::summarise(Count = n(), .groups = "drop") %>%
    dplyr::mutate(Percentage = round((Count / sum(Count)) * 100, 1))

  fig <- plotly::plot_ly(
    data = dist_data,
    labels = ~get(by_field),
    values = ~Count,
    type = "pie",
    textinfo = "label+percent",
    hoverinfo = "text",
    text = ~paste0(
      get(by_field), "<br>",
      "Projects: ", Count, "<br>",
      "Percentage: ", Percentage, "%"
    )
  ) %>%
    plotly::layout(
      title = paste("Project Distribution by", by_field)
    )

  fig
}

#' Create risk dashboard visualization
#' @param projects Projects data
#' @param allocations Allocations data
#' @param team_members Team members data
#' @export
create_risk_dashboard <- function(projects, allocations, team_members) {
  risk_data <- calculate_project_risk(projects, allocations, team_members)

  if (nrow(risk_data) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "No risk data"))
  }

  # Color by risk level
  risk_colors <- c("High" = "#d62728", "Medium" = "#ff7f0e", "Low" = "#2ca02c")

  fig <- plotly::plot_ly(
    data = risk_data,
    x = ~Days_Remaining,
    y = ~Risk_Score,
    type = "scatter",
    mode = "markers",
    marker = list(
      size = 15,
      color = ~Risk_Level,
      colors = risk_colors,
      line = list(color = "white", width = 1)
    ),
    text = ~paste0(
      "<b>", Project, "</b><br>",
      "Owner: ", Owner, "<br>",
      "Risk Level: ", Risk_Level, "<br>",
      "Risk Score: ", Risk_Score, "<br>",
      "Days Remaining: ", Days_Remaining
    ),
    hoverinfo = "text"
  ) %>%
    plotly::layout(
      title = "Project Risk Analysis",
      xaxis = list(title = "Days Until Deadline"),
      yaxis = list(title = "Risk Score (0-10)"),
      showlegend = TRUE
    )

  fig
}

#' Create forecast visualization with confidence intervals
#' @param historical Historical utilization data
#' @param forecast Forecasted utilization data
#' @export
create_forecast_chart <- function(historical, forecast) {
  if (is.null(forecast) || nrow(forecast) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "Insufficient data for forecasting"))
  }

  # Historical data
  fig <- plotly::plot_ly() %>%
    plotly::add_trace(
      data = historical,
      x = ~Week,
      y = ~Utilization_Pct,
      type = "scatter",
      mode = "lines+markers",
      name = "Historical",
      line = list(color = "#1f77b4", width = 2),
      marker = list(size = 6)
    )

  # Forecast
  fig <- fig %>%
    plotly::add_trace(
      data = forecast,
      x = ~Week,
      y = ~Forecast_Utilization,
      type = "scatter",
      mode = "lines+markers",
      name = "Forecast",
      line = list(color = "#ff7f0e", width = 2, dash = "dash"),
      marker = list(size = 6)
    )

  # 95% confidence interval
  fig <- fig %>%
    plotly::add_ribbons(
      data = forecast,
      x = ~Week,
      ymin = ~Lower_95,
      ymax = ~Upper_95,
      name = "95% CI",
      fillcolor = "rgba(255,127,14,0.2)",
      line = list(color = "transparent")
    )

  fig <- fig %>%
    plotly::layout(
      title = "Utilization Forecast",
      xaxis = list(title = "Week"),
      yaxis = list(title = "Utilization %"),
      hovermode = "x unified"
    )

  fig
}

#' Create KPI sparklines for value boxes
#' @param data Vector of historical values
#' @export
create_sparkline <- function(data) {
  if (length(data) < 2) {
    return(NULL)
  }

  fig <- plotly::plot_ly(
    x = seq_along(data),
    y = data,
    type = "scatter",
    mode = "lines",
    line = list(color = "white", width = 2),
    showlegend = FALSE
  ) %>%
    plotly::layout(
      xaxis = list(visible = FALSE),
      yaxis = list(visible = FALSE),
      margin = list(l = 0, r = 0, t = 0, b = 0),
      height = 50,
      width = 100
    ) %>%
    plotly::config(displayModeBar = FALSE)

  fig
}

#' Create allocation matrix view
#' @param allocations Allocations data
#' @export
create_allocation_matrix <- function(allocations) {
  if (nrow(allocations) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "No allocation data"))
  }

  # Pivot data to matrix format
  matrix_data <- allocations %>%
    dplyr::filter(!is.na(Project)) %>%
    dplyr::group_by(Week, Name, Project) %>%
    dplyr::summarise(Hours = sum(Hours_Allocated, na.rm = TRUE),
                    .groups = "drop") %>%
    tidyr::pivot_wider(
      names_from = Name,
      values_from = Hours,
      values_fill = 0
    )

  # Extract names for heatmap
  team_names <- setdiff(names(matrix_data), c("Week", "Project"))

  # Create matrix for heatmap
  if (length(team_names) == 0) {
    return(plotly::plot_ly() %>%
            plotly::layout(title = "No team members found"))
  }

  z_matrix <- as.matrix(matrix_data[, team_names])

  fig <- plotly::plot_ly(
    x = team_names,
    y = ~paste(matrix_data$Week, "-", matrix_data$Project),
    z = z_matrix,
    type = "heatmap",
    colorscale = "Blues",
    text = z_matrix,
    texttemplate = "%{z}",
    hovertemplate = "Team: %{x}<br>Project: %{y}<br>Hours: %{z}<extra></extra>"
  ) %>%
    plotly::layout(
      title = "Allocation Matrix (Hours per Week-Project)",
      xaxis = list(title = "Team Member"),
      yaxis = list(title = "Week - Project")
    )

  fig
}
