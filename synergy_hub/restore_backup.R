#!/usr/bin/env Rscript
# Synergy Hub - Interactive Backup Restore Script
# Run this script to restore data from a backup

cat("\n===============================================\n")
cat("Synergy Hub - Data Restore\n")
cat("===============================================\n\n")

cat("⚠️  WARNING: This will overwrite current data!\n")
cat("Make sure you have a recent backup before proceeding.\n\n")

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

# List available backups
cat("Available backups:\n")
cat("-----------------------------------------------\n")
backups <- list_backups(backup_directory)

if (nrow(backups) == 0) {
  cat("❌ No backups found!\n")
  cat("Backup directory:", backup_directory, "\n")
  quit(status = 1)
}

# Show backups with index
for (i in 1:nrow(backups)) {
  cat(sprintf("[%d] %s - %s (%.2f MB, %d files)\n",
              i,
              backups$Timestamp[i],
              backups$Date[i],
              backups$Size_MB[i],
              backups$Files[i]))
}

cat("-----------------------------------------------\n\n")

# Get user input
cat("Enter the number of the backup to restore (1-", nrow(backups), "): ", sep = "")

# For non-interactive mode (when running via Rscript without terminal)
# we'll provide a fallback
if (interactive()) {
  choice <- as.integer(readline())
} else {
  # In non-interactive mode, you can pass the backup index as argument
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 0) {
    choice <- as.integer(args[1])
  } else {
    cat("\nNon-interactive mode: specify backup index as argument\n")
    cat("Example: Rscript restore_backup.R 1\n")
    quit(status = 1)
  }
}

if (is.na(choice) || choice < 1 || choice > nrow(backups)) {
  cat("❌ Invalid choice!\n")
  quit(status = 1)
}

selected_backup <- backups[choice, ]

cat("\nYou selected:\n")
cat("  Timestamp:", selected_backup$Timestamp, "\n")
cat("  Date:", selected_backup$Date, "\n")
cat("  Size:", selected_backup$Size_MB, "MB\n")
cat("  Files:", selected_backup$Files, "\n")
cat("  Path:", selected_backup$Path, "\n\n")

# Confirm
cat("⚠️  This will OVERWRITE the following files:\n")
cat("  -", entries_file, "\n")
cat("  -", its_personnel_file, "\n")
cat("  -", business_partners_file, "\n")
cat("  -", relationships_file, "\n\n")

if (interactive()) {
  cat("Are you sure you want to continue? (yes/no): ")
  confirm <- tolower(trimws(readline()))
} else {
  # In non-interactive mode, you can pass 'yes' as second argument
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 1 && tolower(args[2]) == "yes") {
    confirm <- "yes"
  } else {
    cat("Non-interactive mode: add 'yes' as second argument to confirm\n")
    cat("Example: Rscript restore_backup.R 1 yes\n")
    quit(status = 1)
  }
}

if (confirm != "yes") {
  cat("\nRestore cancelled.\n")
  quit(status = 0)
}

# Perform restore
cat("\n===============================================\n")
cat("Restoring backup...\n")
cat("===============================================\n\n")

# Get the target directory from the config paths
target_dir <- dirname(entries_file)

success <- restore_backup(selected_backup$Path, target_dir)

if (!success) {
  cat("\n❌ Restore failed! Check errors above.\n")
  cat("Your original data may be intact. Check manually.\n")
  quit(status = 1)
}

cat("\n===============================================\n")
cat("✓ Restore completed successfully!\n")
cat("===============================================\n\n")

cat("Next steps:\n")
cat("1. Verify the restored data\n")
cat("2. Restart the Synergy Hub application\n")
cat("3. Check that everything works as expected\n\n")

quit(status = 0)
