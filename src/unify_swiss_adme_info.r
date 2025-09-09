#!/usr/bin/env Rscript

# =============================================================================
# SwissADME CSV Files Unification Script
# =============================================================================
#
# Purpose: Unify all CSV files in the swiss_adme_info directory into a single
#          CSV file for downstream processing.
#
# Author: Generated based on project requirements
# Date: 2024
#
# Usage:
#   - Place all input CSV files in the swiss_adme_info directory
#   - Run this script: source("unify_swiss_adme_info.r") or Rscript unify_swiss_adme_info.r
#   - Check swiss_adme_info/swissadme_unified.csv for output
#   - Check logs/unify_swissadme.log for detailed logs
#
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION - Modify these paths as needed
# -----------------------------------------------------------------------------

# Input directory containing CSV files to merge
INPUT_DIR <- "swiss_adme_info"

# Output file name (will be saved in INPUT_DIR)
OUTPUT_FILENAME <- "swissadme_unified.csv"

# Log file path
LOG_DIR <- "logs"
LOG_FILENAME <- "unify_swissadme.log"

# -----------------------------------------------------------------------------
# SETUP AND INITIALIZATION
# -----------------------------------------------------------------------------

# Load required libraries
suppressPackageStartupMessages({
  if (!require("utils", quietly = TRUE)) {
    stop("utils package is required but not available")
  }
})

# Create absolute paths
script_dir <- tryCatch({
  if (exists("rstudioapi") && rstudioapi::isAvailable()) {
    dirname(rstudioapi::getActiveDocumentContext()$path)
  } else {
    # Fallback for command line execution
    cmdArgs <- commandArgs(trailingOnly = FALSE)
    needle <- "--file="
    match <- grep(needle, cmdArgs)
    if (length(match) > 0) {
      dirname(sub(needle, "", cmdArgs[match]))
    } else {
      getwd()
    }
  }
}, error = function(e) {
  getwd()
})

# If we're in the src directory, go up one level to project root
if (basename(script_dir) == "src") {
  script_dir <- dirname(script_dir)
}

input_dir_path <- file.path(script_dir, INPUT_DIR)
output_file_path <- file.path(input_dir_path, OUTPUT_FILENAME)
log_dir_path <- file.path(script_dir, LOG_DIR)
log_file_path <- file.path(log_dir_path, LOG_FILENAME)

# Create log directory if it doesn't exist
if (!dir.exists(log_dir_path)) {
  dir.create(log_dir_path, recursive = TRUE)
}

# -----------------------------------------------------------------------------
# LOGGING FUNCTIONS
# -----------------------------------------------------------------------------

#' Log a message to both file and console
#' @param level Log level (INFO, ERROR, WARN)
#' @param message Main message
#' @param details Additional details (optional)
log_message <- function(level, message, details = "") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  if (details != "") {
    log_entry <- sprintf("%s | %s | %s | %s", timestamp, level, message, details)
  } else {
    log_entry <- sprintf("%s | %s | %s", timestamp, level, message)
  }

  # Print to console
  cat(log_entry, "\n")

  # Write to log file
  tryCatch({
    cat(log_entry, "\n", file = log_file_path, append = TRUE)
  }, error = function(e) {
    cat("ERROR: Failed to write to log file:", e$message, "\n")
  })
}

#' Log an info message
log_info <- function(message, details = "") {
  log_message("INFO", message, details)
}

#' Log an error message
log_error <- function(message, details = "") {
  log_message("ERROR", message, details)
}

#' Log a warning message
log_warn <- function(message, details = "") {
  log_message("WARN", message, details)
}

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

#' Get list of CSV files to process
#' @return Vector of file paths, excluding the output file
get_csv_files <- function() {
  if (!dir.exists(input_dir_path)) {
    stop(sprintf("Input directory does not exist: %s", input_dir_path))
  }

  # List all CSV files
  all_csv_files <- list.files(
    path = input_dir_path,
    pattern = "\\.csv$",
    ignore.case = TRUE,
    full.names = FALSE
  )

  # Exclude the output file if it exists
  csv_files <- all_csv_files[all_csv_files != OUTPUT_FILENAME]

  # Sort for reproducibility (natural numeric order)
  extract_leading_number <- function(filename) {
    as.numeric(sub("^(\\d+).*", "\\1", filename))
  }
  csv_files <- csv_files[order(sapply(csv_files, extract_leading_number))]

  return(csv_files)
}

#' Read a CSV file with error handling
#' @param file_path Path to the CSV file
#' @param skip_header Whether to skip the header row
#' @return Data frame or NULL on error
read_csv_safe <- function(file_path, skip_header = FALSE) {
  tryCatch({
    if (skip_header) {
      data <- read.csv(
        file_path,
        header = FALSE,
        skip = 1,
        stringsAsFactors = FALSE,
        encoding = "UTF-8",
        check.names = FALSE
      )
    } else {
      data <- read.csv(
        file_path,
        header = TRUE,
        stringsAsFactors = FALSE,
        encoding = "UTF-8",
        check.names = FALSE
      )
    }
    return(data)
  }, error = function(e) {
    log_error(sprintf("Failed to read file: %s", basename(file_path)),
              sprintf("reason=%s", e$message))
    return(NULL)
  })
}

#' Write unified CSV with error handling
#' @param data Data frame to write
#' @param file_path Output file path
#' @return TRUE on success, FALSE on error
write_csv_safe <- function(data, file_path) {
  tryCatch({
    write.csv(
      data,
      file = file_path,
      row.names = FALSE,
      fileEncoding = "UTF-8",
      quote = TRUE
    )
    return(TRUE)
  }, error = function(e) {
    log_error(sprintf("Failed to write output file: %s", basename(file_path)),
              sprintf("reason=%s", e$message))
    return(FALSE)
  })
}

# -----------------------------------------------------------------------------
# MAIN PROCESSING FUNCTION
# -----------------------------------------------------------------------------

#' Main function to unify CSV files
unify_csv_files <- function() {
  start_time <- Sys.time()

  # Log script start
  config_details <- sprintf("input_dir=%s | output_file=%s | log_file=%s",
                           INPUT_DIR, OUTPUT_FILENAME, LOG_FILENAME)
  log_info("Script started", config_details)

  # Get list of CSV files to process
  csv_files <- get_csv_files()

  if (length(csv_files) == 0) {
    log_warn("No CSV files found to process")
    return(FALSE)
  }

  log_info(sprintf("Found %d input files", length(csv_files)))

  # Initialize variables for merging
  unified_data <- NULL
  total_rows <- 0
  files_processed <- 0

  # Process each CSV file
  for (i in seq_along(csv_files)) {
    file_name <- csv_files[i]
    file_path <- file.path(input_dir_path, file_name)

    log_info(sprintf("Processing file %d of %d: %s", i, length(csv_files), file_name))

    # Read the file
    if (i == 1) {
      # First file: include header
      current_data <- read_csv_safe(file_path, skip_header = FALSE)
    } else {
      # Subsequent files: skip header
      current_data <- read_csv_safe(file_path, skip_header = TRUE)
    }

    # Check if file was read successfully
    if (is.null(current_data)) {
      log_error(sprintf("Stopping execution due to error reading: %s", file_name))
      return(FALSE)
    }

    # For subsequent files, ensure column names match
    if (i > 1 && !is.null(unified_data)) {
      if (ncol(current_data) != ncol(unified_data)) {
        log_error(sprintf("Column count mismatch in file: %s", file_name),
                  sprintf("expected=%d | actual=%d", ncol(unified_data), ncol(current_data)))
        return(FALSE)
      }
      # Set column names to match the first file
      colnames(current_data) <- colnames(unified_data)
    }

    # Merge data
    if (is.null(unified_data)) {
      unified_data <- current_data
    } else {
      unified_data <- rbind(unified_data, current_data)
    }

    # Log successful merge
    rows_added <- nrow(current_data)
    total_rows <- total_rows + rows_added
    files_processed <- files_processed + 1

    log_info(sprintf("Merged file: %s", file_name),
             sprintf("rows=%d | total_rows=%d", rows_added, total_rows))
  }

  # Write the unified file
  log_info("Writing unified CSV file")

  if (!write_csv_safe(unified_data, output_file_path)) {
    return(FALSE)
  }

  # Log completion
  end_time <- Sys.time()
  execution_time <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)

  completion_details <- sprintf("files_merged=%d | total_rows=%d | execution_time=%ss",
                               files_processed, total_rows, execution_time)
  log_info("Output written successfully",
           sprintf("file=%s | rows=%d", OUTPUT_FILENAME, total_rows))
  log_info("Script finished", completion_details)

  return(TRUE)
}

# -----------------------------------------------------------------------------
# SCRIPT EXECUTION
# -----------------------------------------------------------------------------

# Main execution block
main <- function() {
  tryCatch({
    success <- unify_csv_files()
    if (success) {
      cat("\n=== UNIFICATION COMPLETED SUCCESSFULLY ===\n")
      cat(sprintf("Output file: %s\n", output_file_path))
      cat(sprintf("Log file: %s\n", log_file_path))
    } else {
      cat("\n=== UNIFICATION FAILED ===\n")
      cat("Check the log file for details.\n")
      quit(status = 1)
    }
  }, error = function(e) {
    log_error("Unexpected error in main execution", sprintf("reason=%s", e$message))
    cat("\n=== SCRIPT EXECUTION FAILED ===\n")
    cat("Check the log file for details.\n")
    quit(status = 1)
  })
}

# Execute main function if script is run directly
if (!interactive()) {
  main()
} else {
  cat("Script loaded. Run main() to execute unification.\n")
  cat(sprintf("Configuration:\n"))
  cat(sprintf("  Input directory: %s\n", input_dir_path))
  cat(sprintf("  Output file: %s\n", output_file_path))
  cat(sprintf("  Log file: %s\n", log_file_path))
}
