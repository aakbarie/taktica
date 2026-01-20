# Synergy Hub Configuration File
#
# IMPORTANT: This file contains critical file path configurations.
# DO NOT DELETE OR MODIFY unless you know what you're doing.
#
# For backup instructions, see BACKUP_STRATEGY.md

# Production File Paths
# These paths point to your actual data storage location
entries_file <- "/winset/BAU/Data Science/ShinyAppsData/BRM/entries.parquet"
its_personnel_file <- "/winset/BAU/Data Science/ShinyAppsData/BRM/its_personnel.csv"
business_partners_file <- "/winset/BAU/Data Science/ShinyAppsData/BRM/business_partners.csv"
relationships_file <- "/winset/BAU/Data Science/ShinyAppsData/BRM/brm_assignments.csv"

# Backup Configuration
backup_enabled <- TRUE
backup_directory <- "/winset/BAU/Data Science/ShinyAppsData/BRM/backups"
backup_frequency <- "daily"  # Options: "manual", "daily", "weekly"
backup_retention_days <- 30  # Keep backups for 30 days

# Application Settings
app_title <- "Synergy Hub"
app_version <- "1.0.1"
max_file_size_mb <- 100  # Maximum size for data files in MB

# Data Validation Settings
require_all_fields <- TRUE
score_min <- 1
score_max <- 10

# Session Settings
session_timeout_minutes <- 60
auto_save_enabled <- TRUE

# Logging
log_enabled <- TRUE
log_file <- "/winset/BAU/Data Science/ShinyAppsData/BRM/logs/synergy_hub.log"

# NOTES:
# - All file paths use forward slashes (/)
# - Paths should be absolute, not relative
# - Ensure write permissions exist for all directories
# - Test paths before deploying to production
