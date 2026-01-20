# Backup Utility Functions for Synergy Hub
# Protects against data loss with automated and manual backup options

library(readr)
library(arrow)

#' Create a timestamped backup of all data files
#'
#' @param entries_file Path to entries parquet file
#' @param its_personnel_file Path to ITS personnel CSV
#' @param business_partners_file Path to business partners CSV
#' @param relationships_file Path to relationships CSV
#' @param backup_dir Directory to store backups
#' @return TRUE if successful, FALSE otherwise
create_backup <- function(entries_file, its_personnel_file,
                         business_partners_file, relationships_file,
                         backup_dir) {
  # Create backup directory if it doesn't exist
  if (!dir.exists(backup_dir)) {
    dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Create timestamp for backup
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  backup_subdir <- file.path(backup_dir, timestamp)
  dir.create(backup_subdir, recursive = TRUE, showWarnings = FALSE)

  success <- TRUE

  # Backup entries file
  if (file.exists(entries_file)) {
    tryCatch({
      backup_path <- file.path(backup_subdir, basename(entries_file))
      file.copy(entries_file, backup_path, overwrite = TRUE)
      message("✓ Backed up entries to: ", backup_path)
    }, error = function(e) {
      warning("Failed to backup entries: ", e$message)
      success <<- FALSE
    })
  }

  # Backup ITS personnel file
  if (file.exists(its_personnel_file)) {
    tryCatch({
      backup_path <- file.path(backup_subdir, basename(its_personnel_file))
      file.copy(its_personnel_file, backup_path, overwrite = TRUE)
      message("✓ Backed up ITS personnel to: ", backup_path)
    }, error = function(e) {
      warning("Failed to backup ITS personnel: ", e$message)
      success <<- FALSE
    })
  }

  # Backup business partners file
  if (file.exists(business_partners_file)) {
    tryCatch({
      backup_path <- file.path(backup_subdir, basename(business_partners_file))
      file.copy(business_partners_file, backup_path, overwrite = TRUE)
      message("✓ Backed up business partners to: ", backup_path)
    }, error = function(e) {
      warning("Failed to backup business partners: ", e$message)
      success <<- FALSE
    })
  }

  # Backup relationships file
  if (file.exists(relationships_file)) {
    tryCatch({
      backup_path <- file.path(backup_subdir, basename(relationships_file))
      file.copy(relationships_file, backup_path, overwrite = TRUE)
      message("✓ Backed up relationships to: ", backup_path)
    }, error = function(e) {
      warning("Failed to backup relationships: ", e$message)
      success <<- FALSE
    })
  }

  # Create backup manifest
  manifest <- list(
    timestamp = timestamp,
    created = Sys.time(),
    files = list(
      entries = basename(entries_file),
      its_personnel = basename(its_personnel_file),
      business_partners = basename(business_partners_file),
      relationships = basename(relationships_file)
    )
  )

  manifest_file <- file.path(backup_subdir, "backup_manifest.txt")
  writeLines(
    c(
      paste("Backup created:", manifest$created),
      paste("Timestamp:", manifest$timestamp),
      "",
      "Files backed up:",
      paste("- ", manifest$files$entries),
      paste("- ", manifest$files$its_personnel),
      paste("- ", manifest$files$business_partners),
      paste("- ", manifest$files$relationships)
    ),
    manifest_file
  )

  if (success) {
    message("\n✓ Backup completed successfully!")
    message("Backup location: ", backup_subdir)
  } else {
    warning("\n⚠ Backup completed with warnings")
  }

  return(success)
}

#' Clean old backups based on retention policy
#'
#' @param backup_dir Directory containing backups
#' @param retention_days Number of days to keep backups
#' @return Number of backups deleted
clean_old_backups <- function(backup_dir, retention_days = 30) {
  if (!dir.exists(backup_dir)) {
    return(0)
  }

  # Get all backup subdirectories
  backup_dirs <- list.dirs(backup_dir, recursive = FALSE)

  deleted_count <- 0
  cutoff_date <- Sys.time() - (retention_days * 24 * 60 * 60)

  for (dir in backup_dirs) {
    dir_info <- file.info(dir)
    if (dir_info$mtime < cutoff_date) {
      tryCatch({
        unlink(dir, recursive = TRUE)
        message("✓ Deleted old backup: ", basename(dir))
        deleted_count <- deleted_count + 1
      }, error = function(e) {
        warning("Failed to delete backup: ", basename(dir), " - ", e$message)
      })
    }
  }

  if (deleted_count > 0) {
    message("\nCleaned ", deleted_count, " old backup(s)")
  } else {
    message("\nNo old backups to clean")
  }

  return(deleted_count)
}

#' Restore data from a backup
#'
#' @param backup_dir Full path to backup directory (timestamp folder)
#' @param target_dir Directory to restore files to
#' @return TRUE if successful, FALSE otherwise
restore_backup <- function(backup_dir, target_dir) {
  if (!dir.exists(backup_dir)) {
    stop("Backup directory does not exist: ", backup_dir)
  }

  # Check for manifest file
  manifest_file <- file.path(backup_dir, "backup_manifest.txt")
  if (file.exists(manifest_file)) {
    message("Backup manifest found:")
    cat(readLines(manifest_file), sep = "\n")
    message("")
  }

  # Get all files in backup directory
  backup_files <- list.files(backup_dir, pattern = "\\.(parquet|csv)$",
                             full.names = TRUE)

  if (length(backup_files) == 0) {
    stop("No data files found in backup directory")
  }

  success <- TRUE

  for (file in backup_files) {
    target_file <- file.path(target_dir, basename(file))

    # Ask for confirmation before overwriting
    if (file.exists(target_file)) {
      message("⚠ File exists: ", target_file)
      message("This will be OVERWRITTEN by the restore operation!")
    }

    tryCatch({
      file.copy(file, target_file, overwrite = TRUE)
      message("✓ Restored: ", basename(file))
    }, error = function(e) {
      warning("Failed to restore: ", basename(file), " - ", e$message)
      success <<- FALSE
    })
  }

  if (success) {
    message("\n✓ Restore completed successfully!")
  } else {
    warning("\n⚠ Restore completed with warnings")
  }

  return(success)
}

#' List all available backups
#'
#' @param backup_dir Directory containing backups
#' @return Dataframe with backup information
list_backups <- function(backup_dir) {
  if (!dir.exists(backup_dir)) {
    message("No backup directory found at: ", backup_dir)
    return(data.frame(
      Timestamp = character(),
      Date = character(),
      Size_MB = numeric(),
      Files = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  backup_dirs <- list.dirs(backup_dir, recursive = FALSE)

  if (length(backup_dirs) == 0) {
    message("No backups found")
    return(data.frame(
      Timestamp = character(),
      Date = character(),
      Size_MB = numeric(),
      Files = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  backups <- data.frame(
    Timestamp = character(),
    Date = character(),
    Size_MB = numeric(),
    Files = numeric(),
    Path = character(),
    stringsAsFactors = FALSE
  )

  for (dir in backup_dirs) {
    dir_info <- file.info(dir)
    files <- list.files(dir, pattern = "\\.(parquet|csv)$")

    # Calculate total size
    file_sizes <- sapply(
      file.path(dir, files),
      function(x) file.info(x)$size
    )
    total_size_mb <- sum(file_sizes, na.rm = TRUE) / (1024 * 1024)

    backups <- rbind(backups, data.frame(
      Timestamp = basename(dir),
      Date = format(dir_info$mtime, "%Y-%m-%d %H:%M:%S"),
      Size_MB = round(total_size_mb, 2),
      Files = length(files),
      Path = dir,
      stringsAsFactors = FALSE
    ))
  }

  # Sort by timestamp descending (newest first)
  backups <- backups[order(backups$Timestamp, decreasing = TRUE), ]

  return(backups)
}

#' Get size of all data files
#'
#' @param entries_file Path to entries file
#' @param its_personnel_file Path to ITS personnel file
#' @param business_partners_file Path to business partners file
#' @param relationships_file Path to relationships file
#' @return Total size in MB
get_data_size <- function(entries_file, its_personnel_file,
                         business_partners_file, relationships_file) {
  files <- c(entries_file, its_personnel_file,
             business_partners_file, relationships_file)

  total_size <- 0
  for (file in files) {
    if (file.exists(file)) {
      total_size <- total_size + file.info(file)$size
    }
  }

  return(total_size / (1024 * 1024))  # Convert to MB
}
