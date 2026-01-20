# Server Logic Functions for Synergy Hub
# This module contains business logic and data processing for the server

library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)

#' Prepare entries data for display with shortened tooltips
#'
#' @param entries Entries dataframe
#' @param max_length Maximum length for text before truncating
#' @return Dataframe with HTML-formatted short text and tooltips
prepare_entries_for_display <- function(entries, max_length = 30) {
  entries %>%
    mutate(
      Comments = sapply(Comments, function(x) create_tooltip_text(x, max_length)),
      Leadership_Review = sapply(Leadership_Review, function(x) create_tooltip_text(x, max_length)),
      Action_Requested = sapply(Action_Requested, function(x) create_tooltip_text(x, max_length))
    )
}

#' Get unresolved entries with row numbers
#'
#' @param entries Entries dataframe
#' @return Dataframe with only unresolved entries and row numbers
get_unresolved_entries <- function(entries) {
  entries %>%
    mutate(Row_Number = row_number()) %>%
    filter(Completed == "No")
}

#' Filter business partners by ITS partner
#'
#' @param relationships_data Relationships dataframe
#' @param its_partner Selected ITS partner name
#' @return Vector of business partner names
filter_business_partners <- function(relationships_data, its_partner) {
  if (is.null(its_partner) || is.na(its_partner) || its_partner == "") {
    return(character(0))
  }

  relationships_data %>%
    filter(`PARTNER (IT)` == its_partner) %>%
    pull(`DIRECTORS/MANAGERS`) %>%
    unique() %>%
    na.omit()
}

#' Filter departments by business partner
#'
#' @param business_partners_data Business partners dataframe
#' @param business_partner Selected business partner name
#' @return Vector of department names
filter_departments <- function(business_partners_data, business_partner) {
  if (is.null(business_partner) || is.na(business_partner) || business_partner == "") {
    return(character(0))
  }

  business_partners_data %>%
    filter(Business_Partner == business_partner) %>%
    pull(Department) %>%
    unique() %>%
    na.omit()
}

#' Filter divisions by business partner
#'
#' @param business_partners_data Business partners dataframe
#' @param business_partner Selected business partner name
#' @return Vector of division names
filter_divisions <- function(business_partners_data, business_partner) {
  if (is.null(business_partner) || is.na(business_partner) || business_partner == "") {
    return(character(0))
  }

  business_partners_data %>%
    filter(Business_Partner == business_partner) %>%
    pull(Division) %>%
    unique() %>%
    na.omit()
}

#' Prepare data for score analysis plot
#'
#' @param entries Entries dataframe
#' @param months_back Number of months to include (default 12)
#' @return List with plot_data and lowest_scores data
prepare_score_analysis_data <- function(entries, months_back = 12) {
  if (nrow(entries) == 0) {
    return(NULL)
  }

  cutoff_date <- floor_date(Sys.Date() %m-% months(months_back), "month")

  # Calculate average scores by month
  plot_data <- entries %>%
    mutate(Month = floor_date(Date, "month")) %>%
    filter(Month >= cutoff_date) %>%
    group_by(Month) %>%
    summarise(
      Avg_Service_Score = mean(Service_Experience_Score, na.rm = TRUE),
      Avg_Work_Score = mean(Work_Product_Score, na.rm = TRUE),
      .groups = "drop"
    )

  # Find lowest service scorers
  lowest_service_scores <- entries %>%
    mutate(Month = floor_date(Date, "month")) %>%
    filter(Month >= cutoff_date) %>%
    group_by(Month) %>%
    filter(!is.na(Service_Experience_Score)) %>%
    filter(Service_Experience_Score == min(Service_Experience_Score, na.rm = TRUE)) %>%
    summarise(
      Lowest_Service_Scorer = paste(Business_Partner, collapse = ", "),
      Lowest_Service_Score = min(Service_Experience_Score, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.infinite(Lowest_Service_Score))

  # Find lowest work scorers
  lowest_work_scores <- entries %>%
    mutate(Month = floor_date(Date, "month")) %>%
    filter(Month >= cutoff_date) %>%
    group_by(Month) %>%
    filter(!is.na(Work_Product_Score)) %>%
    filter(Work_Product_Score == min(Work_Product_Score, na.rm = TRUE)) %>%
    summarise(
      Lowest_Work_Scorer = paste(Business_Partner, collapse = ", "),
      Lowest_Work_Score = min(Work_Product_Score, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.infinite(Lowest_Work_Score))

  # Merge all data
  plot_data <- plot_data %>%
    left_join(lowest_service_scores, by = "Month") %>%
    left_join(lowest_work_scores, by = "Month")

  return(plot_data)
}

#' Create score analysis plotly chart
#'
#' @param plot_data Prepared plot data from prepare_score_analysis_data
#' @return Plotly object
create_score_analysis_plot <- function(plot_data) {
  if (is.null(plot_data) || nrow(plot_data) == 0) {
    return(NULL)
  }

  plot <- plot_ly(data = plot_data, x = ~Month) %>%
    add_lines(y = ~Avg_Service_Score, name = "Avg Service Score",
              line = list(color = '#024950')) %>%
    add_lines(y = ~Avg_Work_Score, name = "Avg Work Score",
              line = list(color = '#F3E0DC')) %>%
    add_markers(
      y = ~Lowest_Service_Score,
      text = ~paste("Lowest Service Scorer:", Lowest_Service_Scorer,
                    "<br>Score:", Lowest_Service_Score),
      hoverinfo = "text",
      marker = list(color = '#E7717D', size = 8),
      name = "Lowest Service Score"
    ) %>%
    add_markers(
      y = ~Lowest_Work_Score,
      text = ~paste("Lowest Work Scorer:", Lowest_Work_Scorer,
                    "<br>Score:", Lowest_Work_Score),
      hoverinfo = "text",
      marker = list(color = '#F79E02', size = 8),
      name = "Lowest Work Score"
    ) %>%
    layout(
      title = "Monthly Average Scores Analysis",
      xaxis = list(
        title = "",
        tickformat = "%b %Y",
        dtick = "M1"
      ),
      yaxis = list(
        title = "Average Score",
        range = c(0, 10)
      ),
      legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.2)
    )

  return(plot)
}

#' Prepare data for Sankey diagram
#'
#' @param relationships_data Relationships dataframe
#' @return List with nodes and links for Sankey diagram
prepare_sankey_data <- function(relationships_data) {
  if (nrow(relationships_data) == 0) {
    return(NULL)
  }

  # Create nodes
  unique_its <- relationships_data$`PARTNER (IT)` %>% unique() %>% na.omit()
  unique_business <- relationships_data$`DIRECTORS/MANAGERS` %>% unique() %>% na.omit()
  unique_departments <- relationships_data$`DEPARTMENT (Bus.)` %>% unique() %>% na.omit()

  nodes <- data.frame(
    name = c(unique_its, unique_business, unique_departments),
    stringsAsFactors = FALSE
  )

  # Create links between ITS Partners and Business Partners
  links_its_to_business <- relationships_data %>%
    filter(!is.na(`PARTNER (IT)`), !is.na(`DIRECTORS/MANAGERS`)) %>%
    mutate(
      source = match(`PARTNER (IT)`, nodes$name) - 1,
      target = match(`DIRECTORS/MANAGERS`, nodes$name) - 1,
      value = 1
    ) %>%
    select(source, target, value)

  # Create links between Business Partners and Departments
  links_business_to_department <- relationships_data %>%
    filter(!is.na(`DIRECTORS/MANAGERS`), !is.na(`DEPARTMENT (Bus.)`)) %>%
    mutate(
      source = match(`DIRECTORS/MANAGERS`, nodes$name) - 1,
      target = match(`DEPARTMENT (Bus.)`, nodes$name) - 1,
      value = 1
    ) %>%
    select(source, target, value)

  # Combine links
  all_links <- rbind(links_its_to_business, links_business_to_department)

  return(list(nodes = nodes, links = all_links))
}

#' Create Sankey diagram
#'
#' @param sankey_data Data from prepare_sankey_data
#' @return Plotly Sankey diagram
create_sankey_plot <- function(sankey_data) {
  if (is.null(sankey_data)) {
    return(NULL)
  }

  plot_ly(
    type = "sankey",
    node = list(
      label = sankey_data$nodes$name,
      pad = 15,
      thickness = 20,
      color = "black",
      font = list(
        size = 12,
        color = "black",
        family = "Arial, sans-serif",
        weight = "bold"
      )
    ),
    link = list(
      source = sankey_data$links$source,
      target = sankey_data$links$target,
      value = sankey_data$links$value
    )
  ) %>%
    layout(
      title = "ITS Partners to Business Partners to Departments",
      font = list(size = 12)
    )
}

#' Update relationships for an ITS personnel
#'
#' @param relationships_data Current relationships dataframe
#' @param its_personnel Selected ITS personnel
#' @param assigned_business_partners Vector of assigned business partner names
#' @param business_partners_data Business partners dataframe with details
#' @return Updated relationships dataframe
update_relationships <- function(relationships_data, its_personnel,
                                assigned_business_partners,
                                business_partners_data) {
  if (is.null(its_personnel) || is.na(its_personnel) || its_personnel == "") {
    return(relationships_data)
  }

  # Remove existing relationships for the selected ITS personnel
  updated_relationships <- relationships_data %>%
    filter(`PARTNER (IT)` != its_personnel)

  # Handle NULL or empty assigned_business_partners (means remove all relationships)
  if (is.null(assigned_business_partners) || length(assigned_business_partners) == 0) {
    return(updated_relationships)
  }

  # Create new relationships
  new_relationships <- data.frame(
    `PARTNER (IT)` = its_personnel,
    `DIRECTORS/MANAGERS` = assigned_business_partners,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  # Merge with Business Partner details
  new_relationships <- new_relationships %>%
    left_join(business_partners_data,
              by = c("DIRECTORS/MANAGERS" = "Business_Partner")) %>%
    rename(
      `DEPARTMENT (Bus.)` = Department,
      DIVISION = Division
    ) %>%
    select(`PARTNER (IT)`, `DIRECTORS/MANAGERS`, `DEPARTMENT (Bus.)`, DIVISION)

  # Add the new relationships
  updated_relationships <- bind_rows(updated_relationships, new_relationships)

  return(updated_relationships)
}

#' Get assigned business partners for an ITS personnel
#'
#' @param relationships_data Relationships dataframe
#' @param its_personnel ITS personnel name
#' @return Vector of assigned business partner names
get_assigned_business_partners <- function(relationships_data, its_personnel) {
  if (is.null(its_personnel) || is.na(its_personnel) || its_personnel == "") {
    return(character(0))
  }

  relationships_data %>%
    filter(`PARTNER (IT)` == its_personnel) %>%
    pull(`DIRECTORS/MANAGERS`) %>%
    unique() %>%
    na.omit()
}
