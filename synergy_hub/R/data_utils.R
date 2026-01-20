# Data Utility Functions for Synergy Hub
# This module handles all data loading, saving, and manipulation operations

library(arrow)
library(readr)
library(dplyr)

#' Initialize empty entries dataframe
#'
#' @return A dataframe with the correct structure for entries
initialize_entries <- function() {
  data.frame(
    Date = as.Date(character()),
    ITS_Partner = character(),
    Business_Partner = character(),
    Department = character(),
    Division = character(),
    Service_Experience_Score = numeric(),
    Work_Product_Score = numeric(),
    Completed = character(),
    Comments = character(),
    Leadership_Review = character(),
    Action_Requested = character(),
    Resolution = character(),
    stringsAsFactors = FALSE
  )
}

#' Load entries from Parquet file
#'
#' @param file_path Path to the Parquet file
#' @return Dataframe of entries or empty dataframe if file doesn't exist
load_entries <- function(file_path) {
  if (file.exists(file_path)) {
    tryCatch({
      read_parquet(file_path)
    }, error = function(e) {
      warning(paste("Error loading entries:", e$message))
      initialize_entries()
    })
  } else {
    initialize_entries()
  }
}

#' Save entries to Parquet file
#'
#' @param entries Dataframe of entries to save
#' @param file_path Path to save the Parquet file
#' @return TRUE if successful, FALSE otherwise
save_entries <- function(entries, file_path) {
  tryCatch({
    # Create directory if it doesn't exist
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
    write_parquet(entries, file_path)
    TRUE
  }, error = function(e) {
    warning(paste("Error saving entries:", e$message))
    FALSE
  })
}

#' Load relationships data from CSV file
#'
#' @param file_path Path to the CSV file
#' @return Dataframe of relationships
load_relationships <- function(file_path) {
  if (file.exists(file_path) && file.info(file_path)$size > 0) {
    tryCatch({
      read_csv(file_path, show_col_types = FALSE) %>%
        select(`PARTNER (IT)`, `DIRECTORS/MANAGERS`,
               `DEPARTMENT (Bus.)`, DIVISION)
    }, error = function(e) {
      warning(paste("Error loading relationships:", e$message))
      data.frame(
        `PARTNER (IT)` = character(),
        `DIRECTORS/MANAGERS` = character(),
        `DEPARTMENT (Bus.)` = character(),
        DIVISION = character(),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    })
  } else {
    data.frame(
      `PARTNER (IT)` = character(),
      `DIRECTORS/MANAGERS` = character(),
      `DEPARTMENT (Bus.)` = character(),
      DIVISION = character(),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
}

#' Load ITS personnel data
#'
#' @param file_path Path to the CSV file
#' @param relationships_data Relationships dataframe to initialize from if file doesn't exist
#' @return Dataframe of ITS personnel
load_its_personnel <- function(file_path, relationships_data = NULL) {
  if (file.exists(file_path) && file.info(file_path)$size > 0) {
    tryCatch({
      read_csv(file_path, show_col_types = FALSE)
    }, error = function(e) {
      warning(paste("Error loading ITS personnel:", e$message))
      if (!is.null(relationships_data)) {
        initialize_its_personnel_from_relationships(relationships_data)
      } else {
        data.frame(ITS_Partner = character(), stringsAsFactors = FALSE)
      }
    })
  } else {
    if (!is.null(relationships_data)) {
      initialize_its_personnel_from_relationships(relationships_data)
    } else {
      data.frame(ITS_Partner = character(), stringsAsFactors = FALSE)
    }
  }
}

#' Initialize ITS personnel from relationships data
#'
#' @param relationships_data Relationships dataframe
#' @return Dataframe of ITS personnel
initialize_its_personnel_from_relationships <- function(relationships_data) {
  relationships_data %>%
    select(`PARTNER (IT)`) %>%
    distinct() %>%
    filter(!is.na(`PARTNER (IT)`)) %>%
    rename(ITS_Partner = `PARTNER (IT)`)
}

#' Load business partners data
#'
#' @param file_path Path to the CSV file
#' @param relationships_data Relationships dataframe to initialize from if file doesn't exist
#' @return Dataframe of business partners
load_business_partners <- function(file_path, relationships_data = NULL) {
  if (file.exists(file_path) && file.info(file_path)$size > 0) {
    tryCatch({
      read_csv(file_path, show_col_types = FALSE)
    }, error = function(e) {
      warning(paste("Error loading business partners:", e$message))
      if (!is.null(relationships_data)) {
        initialize_business_partners_from_relationships(relationships_data)
      } else {
        data.frame(
          Business_Partner = character(),
          Department = character(),
          Division = character(),
          stringsAsFactors = FALSE
        )
      }
    })
  } else {
    if (!is.null(relationships_data)) {
      initialize_business_partners_from_relationships(relationships_data)
    } else {
      data.frame(
        Business_Partner = character(),
        Department = character(),
        Division = character(),
        stringsAsFactors = FALSE
      )
    }
  }
}

#' Initialize business partners from relationships data
#'
#' @param relationships_data Relationships dataframe
#' @return Dataframe of business partners
initialize_business_partners_from_relationships <- function(relationships_data) {
  relationships_data %>%
    select(`DIRECTORS/MANAGERS`, `DEPARTMENT (Bus.)`, DIVISION) %>%
    distinct() %>%
    filter(!is.na(`DIRECTORS/MANAGERS`)) %>%
    rename(
      Business_Partner = `DIRECTORS/MANAGERS`,
      Department = `DEPARTMENT (Bus.)`,
      Division = DIVISION
    )
}

#' Save CSV data
#'
#' @param data Dataframe to save
#' @param file_path Path to save the CSV file
#' @return TRUE if successful, FALSE otherwise
save_csv_data <- function(data, file_path) {
  tryCatch({
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
    write_csv(data, file_path)
    TRUE
  }, error = function(e) {
    warning(paste("Error saving CSV:", e$message))
    FALSE
  })
}

#' Create shortened text with HTML tooltip
#'
#' @param text Text to shorten
#' @param max_length Maximum length before truncating
#' @return HTML string with tooltip
create_tooltip_text <- function(text, max_length = 30) {
  if (is.na(text) || text == "") {
    return('<span title=""></span>')
  }

  if (nchar(text) > max_length) {
    paste0('<span title="', text, '">',
           substr(text, 1, max_length), '...</span>')
  } else {
    paste0('<span title="', text, '">', text, '</span>')
  }
}

#' Add new entry to entries dataframe
#'
#' @param entries Existing entries dataframe
#' @param date Date of the entry
#' @param its_partner ITS partner name
#' @param business_partner Business partner name
#' @param department Department name
#' @param division Division name
#' @param service_score Service experience score (1-10)
#' @param work_score Work product score (1-10)
#' @param comments Optional comments
#' @param leadership_review Optional leadership review
#' @param action_requested Optional action requested
#' @param resolution Optional resolution
#' @return Updated entries dataframe
add_entry <- function(entries, date, its_partner, business_partner,
                     department, division, service_score, work_score,
                     comments = "", leadership_review = "",
                     action_requested = "", resolution = "") {
  new_entry <- data.frame(
    Date = as.Date(date),
    ITS_Partner = its_partner,
    Business_Partner = business_partner,
    Department = department,
    Division = division,
    Service_Experience_Score = service_score,
    Work_Product_Score = work_score,
    Completed = "No",
    Comments = ifelse(is.null(comments) || is.na(comments), "", comments),
    Leadership_Review = ifelse(is.null(leadership_review) || is.na(leadership_review),
                               "", leadership_review),
    Action_Requested = ifelse(is.null(action_requested) || is.na(action_requested),
                             "", action_requested),
    Resolution = ifelse(is.null(resolution) || is.na(resolution), "", resolution),
    stringsAsFactors = FALSE
  )

  rbind(entries, new_entry)
}

#' Validate entry data
#'
#' @param date Date value
#' @param its_partner ITS partner name
#' @param business_partner Business partner name
#' @param department Department name
#' @param division Division name
#' @param service_score Service experience score
#' @param work_score Work product score
#' @return List with valid (TRUE/FALSE) and message
validate_entry <- function(date, its_partner, business_partner, department,
                          division, service_score, work_score) {
  if (is.null(date) || is.na(date)) {
    return(list(valid = FALSE, message = "Date is required"))
  }

  if (is.null(its_partner) || is.na(its_partner) || its_partner == "") {
    return(list(valid = FALSE, message = "ITS Partner is required"))
  }

  if (is.null(business_partner) || is.na(business_partner) || business_partner == "") {
    return(list(valid = FALSE, message = "Business Partner is required"))
  }

  if (is.null(department) || is.na(department) || department == "") {
    return(list(valid = FALSE, message = "Department is required"))
  }

  if (is.null(division) || is.na(division) || division == "") {
    return(list(valid = FALSE, message = "Division is required"))
  }

  if (is.null(service_score) || is.na(service_score) ||
      service_score < 1 || service_score > 10) {
    return(list(valid = FALSE, message = "Service score must be between 1 and 10"))
  }

  if (is.null(work_score) || is.na(work_score) ||
      work_score < 1 || work_score > 10) {
    return(list(valid = FALSE, message = "Work score must be between 1 and 10"))
  }

  return(list(valid = TRUE, message = "Valid"))
}
