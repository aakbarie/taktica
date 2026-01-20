#!/usr/bin/env Rscript
# Package Installation Script for Synergy Hub
# Run this script to install all required R packages

cat("\n===============================================\n")
cat("Synergy Hub - Package Installation\n")
cat("===============================================\n\n")

# List of required packages
required_packages <- c(
  "shiny",
  "shinydashboard",
  "readr",
  "dplyr",
  "DT",
  "lubridate",
  "ggplot2",
  "arrow",
  "plotly",
  "testthat"  # For testing
)

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]

  if(length(new_packages) > 0) {
    cat("Installing", length(new_packages), "missing packages...\n\n")
    for(pkg in new_packages) {
      cat("Installing:", pkg, "...\n")
      install.packages(pkg, repos = "https://cloud.r-project.org", quiet = FALSE)
    }
  } else {
    cat("All required packages are already installed!\n\n")
  }
}

# Install missing packages
tryCatch({
  install_if_missing(required_packages)

  # Verify all packages can be loaded
  cat("\n===============================================\n")
  cat("Verifying package installation...\n")
  cat("===============================================\n\n")

  all_loaded <- TRUE
  for(pkg in required_packages) {
    result <- tryCatch({
      library(pkg, character.only = TRUE)
      cat("✓", pkg, "loaded successfully\n")
      TRUE
    }, error = function(e) {
      cat("✗", pkg, "failed to load:", e$message, "\n")
      FALSE
    })
    if (!result) all_loaded <- FALSE
  }

  cat("\n===============================================\n")
  if (all_loaded) {
    cat("✓ Installation successful!\n")
    cat("===============================================\n\n")
    cat("Next steps:\n")
    cat("1. Configure file paths in app.R (lines 20-23)\n")
    cat("2. Run the app: shiny::runApp('app.R')\n")
    cat("3. See QUICK_START.md for detailed instructions\n\n")
  } else {
    cat("⚠ Some packages failed to install\n")
    cat("===============================================\n\n")
    cat("Please install failed packages manually:\n")
    cat("install.packages('package_name')\n\n")
  }

}, error = function(e) {
  cat("\n===============================================\n")
  cat("✗ Installation error\n")
  cat("===============================================\n\n")
  cat("Error:", e$message, "\n")
  cat("\nPlease try installing packages manually:\n")
  cat("install.packages(c('shiny', 'shinydashboard', 'readr', 'dplyr', 'DT', 'lubridate', 'ggplot2', 'arrow', 'plotly', 'testthat'))\n\n")
})

cat("\n")
