#' Data Access Layer for Taktica
#'
#' Provides functions for data persistence, retrieval, and validation
#' @importFrom arrow read_parquet write_parquet
#' @importFrom dplyr bind_rows filter mutate
#' @importFrom lubridate is.Date
#' @importFrom logger log_info log_error log_warn
#' @importFrom tibble tibble

# Data file paths
get_data_dir <- function() {
  config <- config::get()
  dir <- config$data_dir
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  dir
}

get_project_file <- function() {
  file.path(get_data_dir(), "projects.parquet")
}

get_team_file <- function() {
  file.path(get_data_dir(), "team_members.parquet")
}

get_allocation_file <- function() {
  file.path(get_data_dir(), "allocations.parquet")
}

get_audit_file <- function() {
  file.path(get_data_dir(), "audit_log.parquet")
}

#' Initialize default data
#' @export
initialize_data <- function() {
  logger::log_info("Initializing default data")

  # Default projects
  projects <- tibble::tibble(
    Project = c("HNI 360", "Readmission GenAI", "DUR Risk Flag"),
    Owner = c("Amanda", "Steve", "Akbar"),
    Start_Date = as.Date(c("2024-08-01", "2024-09-01", "2024-08-20")),
    End_Date = as.Date(c("2024-11-01", "2024-10-15", "2024-09-20")),
    Category = c("Evaluation", "GenAI", "ML"),
    Status = c("Active", "Active", "Active"),
    Created_At = Sys.time(),
    Updated_At = Sys.time()
  )

  # Default team members
  team_members <- tibble::tibble(
    Name = c("Akbar", "Amanda", "Steve", "Romina"),
    Role = c("Manager", "Senior DS", "Senior DS", "Junior DS"),
    Weekly_Capacity_Hours = c(20, 40, 40, 15),
    Email = c("akbar@company.com", "amanda@company.com",
              "steve@company.com", "romina@company.com"),
    Active = TRUE,
    Created_At = Sys.time()
  )

  # Default allocations
  allocations <- tibble::tibble(
    Week = rep(seq(as.Date("2024-08-01"), by = "week", length.out = 12), each = 4),
    Name = rep(c("Akbar", "Amanda", "Steve", "Romina"), times = 12),
    Project = rep(c("DUR Risk Flag", "HNI 360", "Readmission GenAI", NA), times = 12),
    Hours_Allocated = c(10, 30, 35, 0, 10, 30, 35, 0, 10, 30, 35, 0,
                        10, 30, 35, 0, 10, 30, 35, 0, 10, 30, 35, 0,
                        8, 28, 30, 5, 8, 28, 30, 5, 8, 28, 30, 5,
                        12, 32, 38, 0, 12, 32, 38, 0, 12, 32, 38, 0),
    Created_At = Sys.time()
  )

  list(
    projects = projects,
    team_members = team_members,
    allocations = allocations
  )
}

#' Validate project data
#' @param project Named list or data frame with project fields
#' @param team_members Data frame of team members (optional, for owner validation)
#' @return List with valid (TRUE/FALSE) and message
#' @export
validate_project <- function(project, team_members = NULL) {
  errors <- character(0)

  # Check required fields
  if (is.null(project$Project) || nchar(trimws(project$Project)) == 0) {
    errors <- c(errors, "Project name is required")
  }

  if (is.null(project$Owner) || nchar(trimws(project$Owner)) == 0) {
    errors <- c(errors, "Owner is required")
  }

  # Validate owner exists in team
  if (!is.null(team_members) && !is.null(project$Owner)) {
    if (!(project$Owner %in% team_members$Name)) {
      errors <- c(errors, sprintf("Owner '%s' not found in team members", project$Owner))
    }
  }

  # Validate dates
  if (!is.null(project$Start_Date) && !is.null(project$End_Date)) {
    if (!lubridate::is.Date(project$Start_Date)) {
      errors <- c(errors, "Start_Date must be a valid date")
    }
    if (!lubridate::is.Date(project$End_Date)) {
      errors <- c(errors, "End_Date must be a valid date")
    }

    if (lubridate::is.Date(project$Start_Date) && lubridate::is.Date(project$End_Date)) {
      if (project$End_Date <= project$Start_Date) {
        errors <- c(errors, "End date must be after start date")
      }
    }
  }

  # Validate category
  valid_categories <- c("Evaluation", "ML", "GenAI", "Shiny App", "Other")
  if (!is.null(project$Category) && !(project$Category %in% valid_categories)) {
    errors <- c(errors, sprintf("Category must be one of: %s",
                                paste(valid_categories, collapse = ", ")))
  }

  # Validate status
  valid_statuses <- c("Active", "Completed", "On Hold", "Cancelled")
  if (!is.null(project$Status) && !(project$Status %in% valid_statuses)) {
    errors <- c(errors, sprintf("Status must be one of: %s",
                               paste(valid_statuses, collapse = ", ")))
  }

  if (length(errors) > 0) {
    return(list(valid = FALSE, message = paste(errors, collapse = "; ")))
  }

  list(valid = TRUE, message = "Valid")
}

#' Validate team member data
#' @export
validate_team_member <- function(member) {
  errors <- character(0)

  if (is.null(member$Name) || nchar(trimws(member$Name)) == 0) {
    errors <- c(errors, "Name is required")
  }

  if (is.null(member$Role) || nchar(trimws(member$Role)) == 0) {
    errors <- c(errors, "Role is required")
  }

  if (!is.null(member$Weekly_Capacity_Hours)) {
    if (!is.numeric(member$Weekly_Capacity_Hours) ||
        member$Weekly_Capacity_Hours < 0 ||
        member$Weekly_Capacity_Hours > 168) {
      errors <- c(errors, "Weekly capacity must be between 0 and 168 hours")
    }
  }

  if (!is.null(member$Email)) {
    if (!grepl("^[^@]+@[^@]+\\.[^@]+$", member$Email)) {
      errors <- c(errors, "Invalid email format")
    }
  }

  if (length(errors) > 0) {
    return(list(valid = FALSE, message = paste(errors, collapse = "; ")))
  }

  list(valid = TRUE, message = "Valid")
}

#' Validate allocation data
#' @export
validate_allocation <- function(allocation, team_members = NULL, projects = NULL) {
  errors <- character(0)

  if (!is.null(allocation$Hours_Allocated)) {
    if (!is.numeric(allocation$Hours_Allocated) || allocation$Hours_Allocated < 0) {
      errors <- c(errors, "Hours allocated must be non-negative")
    }

    # Check against capacity
    if (!is.null(team_members) && !is.null(allocation$Name)) {
      member <- team_members[team_members$Name == allocation$Name, ]
      if (nrow(member) > 0 && allocation$Hours_Allocated > member$Weekly_Capacity_Hours[1]) {
        errors <- c(errors, sprintf("Hours (%s) exceed capacity (%s) for %s",
                                   allocation$Hours_Allocated,
                                   member$Weekly_Capacity_Hours[1],
                                   allocation$Name))
      }
    }
  }

  if (!is.null(allocation$Week) && !lubridate::is.Date(allocation$Week)) {
    errors <- c(errors, "Week must be a valid date")
  }

  if (length(errors) > 0) {
    return(list(valid = FALSE, message = paste(errors, collapse = "; ")))
  }

  list(valid = TRUE, message = "Valid")
}

#' Load projects from file
#' @export
load_projects <- function() {
  file <- get_project_file()

  if (!file.exists(file)) {
    logger::log_warn("Projects file not found, initializing default data")
    data <- initialize_data()
    save_projects(data$projects)
    return(data$projects)
  }

  tryCatch({
    projects <- arrow::read_parquet(file)
    logger::log_info(sprintf("Loaded %d projects", nrow(projects)))
    projects
  }, error = function(e) {
    logger::log_error(sprintf("Error loading projects: %s", e$message))
    stop("Failed to load projects data")
  })
}

#' Save projects to file
#' @export
save_projects <- function(projects) {
  file <- get_project_file()

  tryCatch({
    # Add/update timestamps
    if (!"Created_At" %in% names(projects)) {
      projects$Created_At <- Sys.time()
    }
    projects$Updated_At <- Sys.time()

    arrow::write_parquet(projects, file)
    logger::log_info(sprintf("Saved %d projects", nrow(projects)))

    # Create backup
    backup_file <- file.path(get_data_dir(),
                             sprintf("projects_backup_%s.parquet",
                                    format(Sys.time(), "%Y%m%d_%H%M%S")))
    arrow::write_parquet(projects, backup_file)

    TRUE
  }, error = function(e) {
    logger::log_error(sprintf("Error saving projects: %s", e$message))
    FALSE
  })
}

#' Load team members
#' @export
load_team_members <- function() {
  file <- get_team_file()

  if (!file.exists(file)) {
    logger::log_warn("Team members file not found, initializing default data")
    data <- initialize_data()
    save_team_members(data$team_members)
    return(data$team_members)
  }

  tryCatch({
    team <- arrow::read_parquet(file)
    logger::log_info(sprintf("Loaded %d team members", nrow(team)))
    team
  }, error = function(e) {
    logger::log_error(sprintf("Error loading team members: %s", e$message))
    stop("Failed to load team members data")
  })
}

#' Save team members
#' @export
save_team_members <- function(team_members) {
  file <- get_team_file()

  tryCatch({
    if (!"Created_At" %in% names(team_members)) {
      team_members$Created_At <- Sys.time()
    }

    arrow::write_parquet(team_members, file)
    logger::log_info(sprintf("Saved %d team members", nrow(team_members)))
    TRUE
  }, error = function(e) {
    logger::log_error(sprintf("Error saving team members: %s", e$message))
    FALSE
  })
}

#' Load allocations
#' @export
load_allocations <- function() {
  file <- get_allocation_file()

  if (!file.exists(file)) {
    logger::log_warn("Allocations file not found, initializing default data")
    data <- initialize_data()
    save_allocations(data$allocations)
    return(data$allocations)
  }

  tryCatch({
    alloc <- arrow::read_parquet(file)
    logger::log_info(sprintf("Loaded %d allocation records", nrow(alloc)))
    alloc
  }, error = function(e) {
    logger::log_error(sprintf("Error loading allocations: %s", e$message))
    stop("Failed to load allocations data")
  })
}

#' Save allocations
#' @export
save_allocations <- function(allocations) {
  file <- get_allocation_file()

  tryCatch({
    if (!"Created_At" %in% names(allocations)) {
      allocations$Created_At <- Sys.time()
    }

    arrow::write_parquet(allocations, file)
    logger::log_info(sprintf("Saved %d allocation records", nrow(allocations)))
    TRUE
  }, error = function(e) {
    logger::log_error(sprintf("Error saving allocations: %s", e$message))
    FALSE
  })
}

#' Log audit event
#' @export
log_audit_event <- function(action, entity_type, entity_id, user = "system", details = "") {
  file <- get_audit_file()

  audit_entry <- tibble::tibble(
    Timestamp = Sys.time(),
    User = user,
    Action = action,
    Entity_Type = entity_type,
    Entity_ID = as.character(entity_id),
    Details = details
  )

  tryCatch({
    if (file.exists(file)) {
      existing <- arrow::read_parquet(file)
      audit_log <- dplyr::bind_rows(existing, audit_entry)
    } else {
      audit_log <- audit_entry
    }

    arrow::write_parquet(audit_log, file)
    logger::log_info(sprintf("Audit: %s %s %s", user, action, entity_type))
  }, error = function(e) {
    logger::log_error(sprintf("Error logging audit event: %s", e$message))
  })
}

#' Add new project with validation
#' @export
add_project <- function(project, team_members = NULL, user = "system") {
  validation <- validate_project(project, team_members)

  if (!validation$valid) {
    logger::log_warn(sprintf("Invalid project: %s", validation$message))
    return(list(success = FALSE, message = validation$message))
  }

  projects <- load_projects()

  # Check for duplicates
  if (project$Project %in% projects$Project) {
    msg <- sprintf("Project '%s' already exists", project$Project)
    logger::log_warn(msg)
    return(list(success = FALSE, message = msg))
  }

  # Add project
  new_project <- tibble::tibble(
    Project = project$Project,
    Owner = project$Owner,
    Start_Date = project$Start_Date,
    End_Date = project$End_Date,
    Category = project$Category,
    Status = ifelse(is.null(project$Status), "Active", project$Status),
    Created_At = Sys.time(),
    Updated_At = Sys.time()
  )

  updated <- dplyr::bind_rows(projects, new_project)

  if (save_projects(updated)) {
    log_audit_event("CREATE", "Project", project$Project, user)
    return(list(success = TRUE, message = "Project added successfully"))
  } else {
    return(list(success = FALSE, message = "Failed to save project"))
  }
}

#' Update existing project
#' @export
update_project <- function(old_name, project, team_members = NULL, user = "system") {
  validation <- validate_project(project, team_members)

  if (!validation$valid) {
    return(list(success = FALSE, message = validation$message))
  }

  projects <- load_projects()
  idx <- which(projects$Project == old_name)

  if (length(idx) == 0) {
    return(list(success = FALSE, message = "Project not found"))
  }

  # Keep original Created_At
  projects$Project[idx] <- project$Project
  projects$Owner[idx] <- project$Owner
  projects$Start_Date[idx] <- project$Start_Date
  projects$End_Date[idx] <- project$End_Date
  projects$Category[idx] <- project$Category
  projects$Status[idx] <- project$Status
  projects$Updated_At[idx] <- Sys.time()

  if (save_projects(projects)) {
    log_audit_event("UPDATE", "Project", old_name, user,
                   sprintf("Updated to: %s", project$Project))
    return(list(success = TRUE, message = "Project updated successfully"))
  } else {
    return(list(success = FALSE, message = "Failed to update project"))
  }
}

#' Delete project
#' @export
delete_project <- function(project_name, user = "system") {
  projects <- load_projects()

  if (!(project_name %in% projects$Project)) {
    return(list(success = FALSE, message = "Project not found"))
  }

  projects <- projects[projects$Project != project_name, ]

  if (save_projects(projects)) {
    log_audit_event("DELETE", "Project", project_name, user)
    return(list(success = TRUE, message = "Project deleted successfully"))
  } else {
    return(list(success = FALSE, message = "Failed to delete project"))
  }
}

#' Export data to CSV
#' @export
export_to_csv <- function(data, filename) {
  tryCatch({
    write.csv(data, filename, row.names = FALSE)
    logger::log_info(sprintf("Exported data to %s", filename))
    list(success = TRUE, message = sprintf("Data exported to %s", filename))
  }, error = function(e) {
    logger::log_error(sprintf("Export failed: %s", e$message))
    list(success = FALSE, message = e$message)
  })
}
