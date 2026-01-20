#!/usr/bin/env Rscript
# Synergy Hub - Manual Backup Script
# Run this script to create a backup of all Synergy Hub data

cat("\n===============================================\n")
cat("Synergy Hub - Data Backup\n")
cat("===============================================\n\n")

# Load configuration
tryCatch({
  source("config.R")
  cat("✓ Configuration loaded\n")
}, error = function(e) {
  cat("❌ Error loading config.R:", e$message, "\n")
  quit(status = 1)
})

# Load backup utilities
tryCatch({
  source("R/backup_utils.R")
  cat("✓ Backup utilities loaded\n\n")
}, error = function(e) {
  cat("❌ Error loading backup_utils.R:", e$message, "\n")
  quit(status = 1)
})

# Check current data size
cat("Checking current data size...\n")
current_size <- get_data_size(
  entries_file,
  its_personnel_file,
  business_partners_file,
  relationships_file
)
cat("Current data: ", round(current_size, 2), " MB\n\n")

# Create backup
cat("Creating backup...\n")
cat("-----------------------------------------------\n")

success <- create_backup(
  entries_file,
  its_personnel_file,
  business_partners_file,
  relationships_file,
  backup_directory
)

if (!success) {
  cat("\n❌ Backup failed! Check errors above.\n")
  quit(status = 1)
}

cat("-----------------------------------------------\n\n")

# Clean old backups if retention is set
if (exists("backup_retention_days") && backup_retention_days > 0) {
  cat("Cleaning old backups (retention:", backup_retention_days, "days)...\n")
  deleted <- clean_old_backups(backup_directory, backup_retention_days)

  if (deleted > 0) {
    cat("✓ Cleaned", deleted, "old backup(s)\n\n")
  } else {
    cat("✓ No old backups to clean\n\n")
  }
}

# List current backups
cat("Current backups:\n")
cat("-----------------------------------------------\n")
backups <- list_backups(backup_directory)
if (nrow(backups) > 0) {
  print(backups[, c("Timestamp", "Date", "Size_MB", "Files")])
  cat("\nTotal backups:", nrow(backups), "\n")
} else {
  cat("No backups found\n")
}

cat("===============================================\n")
cat("✓ Backup operation completed!\n")
cat("===============================================\n\n")

quit(status = 0)
