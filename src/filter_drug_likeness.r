#!/usr/bin/env Rscript

# =============================================================================
# Drug-Likeness Filtering Script for SwissADME Data
# =============================================================================
#
# Purpose: Filter molecules from swissadme_unified.csv based on drug-likeness
#          rules. Only molecules with violations in fewer than 3 rules will
#          be retained in the output file.
#
# Filtering Logic: A molecule is EXCLUDED if it has violations (value > 0) in
#                  3 or more of the 5 drug-likeness rules.
#
# Author: Generated for drug-likeness filtering project
# Date: 2024
#
# Usage:
#   - Configure paths in the CONFIGURATION section below
#   - Run this script: source("filter_drug_likeness.r") or Rscript filter_drug_likeness.r
#   - Check Output_csv/ for filtered results
#   - Check logs/filter_drug_likeness.log for detailed process log
#
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION - Modify these settings as needed
# -----------------------------------------------------------------------------

# Input file path
INPUT_FILE <- "swiss_adme_info/swissadme_unified.csv"

# Output directory and base filename
OUTPUT_DIR <- "Output_csv"
OUTPUT_BASE_FILENAME <- "swissadme_druglike_filtered.csv"

# Log directory and filename
LOG_DIR <- "logs"
LOG_FILENAME <- "filter_drug_likeness.log"

# Summary report filename (optional - set to NULL to disable)
SUMMARY_FILENAME <- "filtering_summary.txt"

# Filtering criteria
MAX_VIOLATIONS_ALLOWED <- 2  # Molecules with > this number will be filtered out

# Required column names (must match exactly)
REQUIRED_COLUMNS <- c(
  "Molecule",
  "Canonical SMILES",
  "Bioavailability Score",
  "Lipinski #violations",
  "Ghose #violations",
  "Veber #violations",
  "Egan #violations",
  "Muegge #violations"
)

# Rule violation columns to check (subset of REQUIRED_COLUMNS)
RULE_COLUMNS <- c(
  "Lipinski #violations",
  "Ghose #violations",
  "Veber #violations",
  "Egan #violations",
  "Muegge #violations"
)

# Output columns (in this order)
OUTPUT_COLUMNS <- REQUIRED_COLUMNS

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

# Create full paths
input_file_path <- file.path(script_dir, INPUT_FILE)
output_dir_path <- file.path(script_dir, OUTPUT_DIR)
log_dir_path <- file.path(script_dir, LOG_DIR)
log_file_path <- file.path(log_dir_path, LOG_FILENAME)

# Create directories if they don't exist
if (!dir.exists(output_dir_path)) {
  dir.create(output_dir_path, recursive = TRUE)
}
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

#' Check if input file exists and is readable
#' @param file_path Path to the input file
#' @return TRUE if file is valid, FALSE otherwise
validate_input_file <- function(file_path) {
  if (!file.exists(file_path)) {
    log_error("Input file does not exist", sprintf("path=%s", file_path))
    return(FALSE)
  }

  if (!file.access(file_path, 4) == 0) {
    log_error("Input file is not readable", sprintf("path=%s", file_path))
    return(FALSE)
  }

  return(TRUE)
}

#' Read CSV file with error handling and column validation
#' @param file_path Path to the CSV file
#' @return Data frame or NULL on error
read_csv_safe <- function(file_path) {
  tryCatch({
    data <- read.csv(
      file_path,
      header = TRUE,
      stringsAsFactors = FALSE,
      encoding = "UTF-8",
      check.names = FALSE
    )

    if (nrow(data) == 0) {
      log_error("Input file appears to be empty", sprintf("path=%s", file_path))
      return(NULL)
    }

    # Check for required columns
    missing_columns <- REQUIRED_COLUMNS[!REQUIRED_COLUMNS %in% colnames(data)]
    if (length(missing_columns) > 0) {
      log_error("Required columns are missing from input file",
                sprintf("missing=%s", paste(missing_columns, collapse=", ")))
      return(NULL)
    }

    log_info("Successfully loaded input data",
             sprintf("rows=%d | columns=%d", nrow(data), ncol(data)))

    return(data)

  }, error = function(e) {
    log_error("Failed to read input file", sprintf("path=%s | reason=%s", file_path, e$message))
    return(NULL)
  })
}

#' Filter molecules based on drug-likeness rules
#' @param data Input data frame
#' @return List with filtered data and statistics
filter_molecules <- function(data) {
  log_info("Starting molecule filtering process",
           sprintf("max_violations_allowed=%d", MAX_VIOLATIONS_ALLOWED))

  # Initialize counters
  total_molecules <- nrow(data)
  molecules_with_missing_data <- 0
  molecules_filtered_out <- 0
  rule_violations <- setNames(rep(0, length(RULE_COLUMNS)), RULE_COLUMNS)
  violation_distribution <- setNames(rep(0, length(RULE_COLUMNS) + 1),
                                   paste0(0:length(RULE_COLUMNS), "_violations"))
  missing_molecules <- c()

  # Create logical vector for molecules to keep
  keep_molecule <- rep(TRUE, total_molecules)

  # Check each molecule
  for (i in 1:total_molecules) {
    molecule_name <- data[i, "Molecule"]
    has_missing_data <- FALSE
    violation_count <- 0

    # Check for missing data in required columns
    for (col in REQUIRED_COLUMNS) {
      if (is.na(data[i, col]) || data[i, col] == "" || is.null(data[i, col])) {
        has_missing_data <- TRUE
        break
      }
    }

    if (has_missing_data) {
      molecules_with_missing_data <- molecules_with_missing_data + 1
      missing_molecules <- c(missing_molecules, sprintf("Row %d: %s", i, molecule_name))
      keep_molecule[i] <- FALSE
      log_warn("Molecule has missing data", sprintf("row=%d | molecule=%s", i, molecule_name))
      next
    }

    # Count violations for this molecule
    violated_rules <- c()
    for (rule_col in RULE_COLUMNS) {
      violation_value <- as.numeric(data[i, rule_col])

      if (is.na(violation_value)) {
        has_missing_data <- TRUE
        break
      }

      if (violation_value > 0) {
        violation_count <- violation_count + 1
        violated_rules <- c(violated_rules, rule_col)
        rule_violations[rule_col] <- rule_violations[rule_col] + 1
      }
    }

    if (has_missing_data) {
      molecules_with_missing_data <- molecules_with_missing_data + 1
      missing_molecules <- c(missing_molecules, sprintf("Row %d: %s", i, molecule_name))
      keep_molecule[i] <- FALSE
      log_warn("Molecule has missing rule data", sprintf("row=%d | molecule=%s", i, molecule_name))
      next
    }

    # Update violation distribution
    violation_key <- paste0(violation_count, "_violations")
    violation_distribution[violation_key] <- violation_distribution[violation_key] + 1

    # Apply filtering logic: exclude if violation_count > MAX_VIOLATIONS_ALLOWED
    if (violation_count > MAX_VIOLATIONS_ALLOWED) {
      molecules_filtered_out <- molecules_filtered_out + 1
      keep_molecule[i] <- FALSE

      # Log detailed information for filtered molecules
      if (length(violated_rules) > 0) {
        log_info("Molecule filtered out due to excessive violations",
                sprintf("row=%d | molecule=%s | violations=%d | rules=%s",
                       i, molecule_name, violation_count,
                       paste(violated_rules, collapse=", ")))
      }
    }
  }

  # Filter the data
  filtered_data <- data[keep_molecule, OUTPUT_COLUMNS, drop = FALSE]
  molecules_passing <- nrow(filtered_data)

  # Log filtering results
  log_info("Molecule filtering completed",
           sprintf("total=%d | retained=%d | filtered_out=%d | missing_data=%d",
                   total_molecules, molecules_passing, molecules_filtered_out, molecules_with_missing_data))

  # Log violation distribution
  for (i in 0:length(RULE_COLUMNS)) {
    violation_key <- paste0(i, "_violations")
    count <- violation_distribution[violation_key]
    if (count > 0) {
      status <- if (i <= MAX_VIOLATIONS_ALLOWED) "RETAINED" else "FILTERED OUT"
      log_info(sprintf("Molecules with %d violations: %d (%s)", i, count, status))
    }
  }

  # Return results
  return(list(
    filtered_data = filtered_data,
    total_molecules = total_molecules,
    molecules_passing = molecules_passing,
    molecules_filtered_out = molecules_filtered_out,
    molecules_with_missing_data = molecules_with_missing_data,
    rule_violations = rule_violations,
    violation_distribution = violation_distribution,
    missing_molecules = missing_molecules
  ))
}

#' Generate a unique output filename if file already exists
#' @param base_path Base file path
#' @return Unique file path
get_unique_output_path <- function(base_path) {
  if (!file.exists(base_path)) {
    return(base_path)
  }

  # Extract directory, base name, and extension
  dir_path <- dirname(base_path)
  file_name <- basename(base_path)
  name_parts <- strsplit(file_name, "\\.")[[1]]

  if (length(name_parts) > 1) {
    base_name <- paste(name_parts[1:(length(name_parts)-1)], collapse = ".")
    extension <- name_parts[length(name_parts)]
  } else {
    base_name <- file_name
    extension <- ""
  }

  # Try numbered versions
  counter <- 2
  while (counter <= 1000) {  # Safety limit
    if (extension != "") {
      new_name <- sprintf("%s_%d.%s", base_name, counter, extension)
    } else {
      new_name <- sprintf("%s_%d", base_name, counter)
    }

    new_path <- file.path(dir_path, new_name)
    if (!file.exists(new_path)) {
      return(new_path)
    }
    counter <- counter + 1
  }

  # If we get here, something is wrong
  stop("Could not generate unique filename after 1000 attempts")
}

#' Write filtered data to CSV file
#' @param data Data frame to write
#' @param output_path Output file path
#' @return TRUE on success, FALSE on error
write_output_csv <- function(data, output_path) {
  tryCatch({
    write.csv(
      data,
      file = output_path,
      row.names = FALSE,
      fileEncoding = "UTF-8",
      quote = TRUE
    )

    log_info("Output file written successfully",
             sprintf("path=%s | rows=%d", output_path, nrow(data)))

    return(TRUE)

  }, error = function(e) {
    log_error("Failed to write output file",
              sprintf("path=%s | reason=%s", output_path, e$message))
    return(FALSE)
  })
}

#' Generate and save summary report
#' @param results Filtering results from filter_molecules()
#' @param output_path Output file path used
generate_summary_report <- function(results, output_path) {
  # Create summary text
  summary_lines <- c(
    "=============================================================================",
    "DRUG-LIKENESS FILTERING SUMMARY REPORT",
    "=============================================================================",
    "",
    sprintf("Processing Date: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    sprintf("Input File: %s", INPUT_FILE),
    sprintf("Output File: %s", basename(output_path)),
    sprintf("Filtering Criterion: Molecules with > %d rule violations excluded", MAX_VIOLATIONS_ALLOWED),
    "",
    "FILTERING RESULTS:",
    sprintf("  Total molecules processed: %d", results$total_molecules),
    sprintf("  Molecules retained (≤%d violations): %d", MAX_VIOLATIONS_ALLOWED, results$molecules_passing),
    sprintf("  Molecules filtered out (>%d violations): %d", MAX_VIOLATIONS_ALLOWED, results$molecules_filtered_out),
    sprintf("  Molecules with missing data: %d", results$molecules_with_missing_data),
    "",
    sprintf("Retention rate: %.1f%%",
            (results$molecules_passing / results$total_molecules) * 100),
    "",
    "VIOLATION DISTRIBUTION:"
  )

  # Add violation distribution details
  for (i in 0:length(RULE_COLUMNS)) {
    violation_key <- paste0(i, "_violations")
    count <- results$violation_distribution[violation_key]
    if (count > 0) {
      percentage <- (count / results$total_molecules) * 100
      status <- if (i <= MAX_VIOLATIONS_ALLOWED) "RETAINED" else "FILTERED OUT"
      summary_lines <- c(summary_lines,
                        sprintf("  %d violations: %d molecules (%.1f%%) - %s",
                               i, count, percentage, status))
    }
  }

  summary_lines <- c(summary_lines,
    "",
    "INDIVIDUAL RULE VIOLATION COUNTS:",
    sprintf("  Lipinski violations: %d molecules", results$rule_violations["Lipinski #violations"]),
    sprintf("  Ghose violations: %d molecules", results$rule_violations["Ghose #violations"]),
    sprintf("  Veber violations: %d molecules", results$rule_violations["Veber #violations"]),
    sprintf("  Egan violations: %d molecules", results$rule_violations["Egan #violations"]),
    sprintf("  Muegge violations: %d molecules", results$rule_violations["Muegge #violations"]),
    ""
  )

  if (results$molecules_with_missing_data > 0) {
    summary_lines <- c(
      summary_lines,
      "MOLECULES WITH MISSING DATA:",
      results$missing_molecules,
      ""
    )
  }

  summary_lines <- c(
    summary_lines,
    sprintf("FILTERING LOGIC: Molecules violating >%d rules were excluded from output.", MAX_VIOLATIONS_ALLOWED),
    sprintf("RETAINED: Molecules with 0-%d rule violations.", MAX_VIOLATIONS_ALLOWED),
    "============================================================================="
  )

  # Print to console
  cat(paste(summary_lines, collapse = "\n"), "\n")

  # Log the summary
  for (line in summary_lines) {
    if (line != "" && !startsWith(line, "=")) {
      log_info(line)
    }
  }

  # Save to file if requested
  if (!is.null(SUMMARY_FILENAME)) {
    summary_path <- file.path(output_dir_path, SUMMARY_FILENAME)
    tryCatch({
      writeLines(summary_lines, summary_path)
      log_info("Summary report saved", sprintf("path=%s", summary_path))
    }, error = function(e) {
      log_warn("Failed to save summary report", sprintf("reason=%s", e$message))
    })
  }
}

# -----------------------------------------------------------------------------
# MAIN PROCESSING FUNCTION
# -----------------------------------------------------------------------------

#' Main function to filter drug-likeness data
filter_drug_likeness <- function() {
  start_time <- Sys.time()

  # Log script start
  config_details <- sprintf("input=%s | output_dir=%s | max_violations=%d | log_file=%s",
                           INPUT_FILE, OUTPUT_DIR, MAX_VIOLATIONS_ALLOWED, LOG_FILENAME)
  log_info("Drug-likeness filtering script started", config_details)

  # Step 1: Validate input file
  log_info("Step 1: Validating input file")
  if (!validate_input_file(input_file_path)) {
    log_error("Input file validation failed - stopping execution")
    return(FALSE)
  }
  log_info("Input file validation successful")

  # Step 2: Read input data
  log_info("Step 2: Reading input data")
  input_data <- read_csv_safe(input_file_path)
  if (is.null(input_data)) {
    log_error("Failed to read input data - stopping execution")
    return(FALSE)
  }

  # Step 3: Filter molecules
  log_info("Step 3: Filtering molecules based on drug-likeness rules")
  filtering_results <- filter_molecules(input_data)

  if (filtering_results$molecules_passing == 0) {
    log_warn("No molecules passed the filtering criteria")
  }

  # Step 4: Write output file
  log_info("Step 4: Writing filtered results to output file")
  base_output_path <- file.path(output_dir_path, OUTPUT_BASE_FILENAME)
  final_output_path <- get_unique_output_path(base_output_path)

  if (final_output_path != base_output_path) {
    log_info("Output file already exists, using alternative filename",
             sprintf("new_name=%s", basename(final_output_path)))
  }

  if (!write_output_csv(filtering_results$filtered_data, final_output_path)) {
    log_error("Failed to write output file - stopping execution")
    return(FALSE)
  }

  # Step 5: Generate summary report
  log_info("Step 5: Generating summary report")
  generate_summary_report(filtering_results, final_output_path)

  # Log completion
  end_time <- Sys.time()
  execution_time <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)

  completion_details <- sprintf("execution_time=%ss | output_file=%s",
                               execution_time, basename(final_output_path))
  log_info("Drug-likeness filtering completed successfully", completion_details)

  return(TRUE)
}

# -----------------------------------------------------------------------------
# SCRIPT EXECUTION
# -----------------------------------------------------------------------------

# Main execution block
main <- function() {
  tryCatch({
    success <- filter_drug_likeness()
    if (success) {
      cat("\n=== DRUG-LIKENESS FILTERING COMPLETED SUCCESSFULLY ===\n")
      cat(sprintf("Check the output directory: %s\n", output_dir_path))
      cat(sprintf("Check the log file: %s\n", log_file_path))
      cat(sprintf("Filtering criterion: Excluded molecules with >%d rule violations\n", MAX_VIOLATIONS_ALLOWED))
    } else {
      cat("\n=== DRUG-LIKENESS FILTERING FAILED ===\n")
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
  cat("Drug-likeness filtering script loaded.\n")
  cat("Run main() to execute filtering.\n\n")
  cat("Configuration:\n")
  cat(sprintf("  Input file: %s\n", input_file_path))
  cat(sprintf("  Output directory: %s\n", output_dir_path))
  cat(sprintf("  Log file: %s\n", log_file_path))
  cat(sprintf("  Max violations allowed: %d\n", MAX_VIOLATIONS_ALLOWED))
  cat("\nFiltering Logic:\n")
  cat(sprintf("  - Molecules with 0-%d violations: RETAINED\n", MAX_VIOLATIONS_ALLOWED))
  cat(sprintf("  - Molecules with %d+ violations: FILTERED OUT\n", MAX_VIOLATIONS_ALLOWED + 1))
  cat("\nRequired columns:\n")
  for (col in REQUIRED_COLUMNS) {
    cat(sprintf("  - %s\n", col))
  }
  cat("\nRule columns to check:\n")
  for (col in RULE_COLUMNS) {
    cat(sprintf("  - %s\n", col))
  }
}
