# =============================================================================
# R Script: Automated Replacement of Molecule Names in CSV
# =============================================================================
#
# Purpose: Replace all molecule names in swissadme_unified.csv with new names
#          from names_of_molecules.txt, maintaining data integrity and creating
#          a backup of the original file.
#
# Author: Automated Script Generator
# Date: Created for molecule name standardization project
# =============================================================================

# Load required libraries
if (!require(utils)) {
  stop("Required package 'utils' is not available")
}

# =============================================================================
# CONFIGURATION
# =============================================================================

# Define file paths
csv_file_path <- "swiss_adme_info/swissadme_unified.csv"
names_file_path <- "swiss_adme_info/names_of_molecules.txt"
backup_suffix <- "_backup"

# Get current timestamp for backup filename
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
backup_file_path <- paste0("swiss_adme_info/swissadme_unified", backup_suffix, "_", timestamp, ".csv")

# =============================================================================
# FUNCTIONS
# =============================================================================

#' Check if file exists and is readable
#' @param file_path Path to the file to check
#' @return TRUE if file exists and is readable, FALSE otherwise
check_file_exists <- function(file_path) {
  if (!file.exists(file_path)) {
    cat("ERROR: File does not exist:", file_path, "\n")
    return(FALSE)
  }

  if (!file.access(file_path, 4) == 0) {
    cat("ERROR: File is not readable:", file_path, "\n")
    return(FALSE)
  }

  return(TRUE)
}

#' Read and validate molecule names from text file
#' @param file_path Path to the names text file
#' @return Vector of molecule names
read_molecule_names <- function(file_path) {
  tryCatch({
    # Read all lines from the file
    names_vector <- readLines(file_path, warn = FALSE, encoding = "UTF-8")

    # Remove empty lines and trim whitespace
    names_vector <- trimws(names_vector)
    names_vector <- names_vector[nchar(names_vector) > 0]

    if (length(names_vector) == 0) {
      stop("No valid molecule names found in the file")
    }

    cat("Successfully read", length(names_vector), "molecule names from", file_path, "\n")
    return(names_vector)

  }, error = function(e) {
    stop("Error reading molecule names file: ", e$message)
  })
}

#' Read CSV file with proper handling
#' @param file_path Path to the CSV file
#' @return Data frame containing the CSV data
read_csv_data <- function(file_path) {
  tryCatch({
    # Read CSV with proper settings
    csv_data <- read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)

    if (nrow(csv_data) == 0) {
      stop("CSV file appears to be empty")
    }

    if (!"Molecule" %in% colnames(csv_data)) {
      stop("CSV file does not contain a 'Molecule' column")
    }

    cat("Successfully read CSV with", nrow(csv_data), "rows and", ncol(csv_data), "columns\n")
    return(csv_data)

  }, error = function(e) {
    stop("Error reading CSV file: ", e$message)
  })
}

#' Create backup of the original CSV file
#' @param original_path Path to the original file
#' @param backup_path Path for the backup file
create_backup <- function(original_path, backup_path) {
  tryCatch({
    file.copy(original_path, backup_path, overwrite = FALSE)

    if (!file.exists(backup_path)) {
      stop("Backup file was not created successfully")
    }

    cat("Backup created successfully:", backup_path, "\n")

  }, error = function(e) {
    stop("Error creating backup: ", e$message)
  })
}

#' Replace molecule names in the CSV data
#' @param csv_data Data frame containing CSV data
#' @param new_names Vector of new molecule names
#' @return Updated data frame with replaced names
replace_molecule_names <- function(csv_data, new_names) {
  tryCatch({
    # Validate that we have the right number of names
    if (length(new_names) != nrow(csv_data)) {
      stop(sprintf("Mismatch in row counts: CSV has %d rows, but names file has %d names",
                   nrow(csv_data), length(new_names)))
    }

    # Create a copy of the data to avoid modifying the original
    updated_data <- csv_data

    # Replace the Molecule column with new names
    updated_data$Molecule <- new_names

    cat("Successfully replaced", length(new_names), "molecule names\n")
    return(updated_data)

  }, error = function(e) {
    stop("Error replacing molecule names: ", e$message)
  })
}

#' Write updated CSV data to file
#' @param data Data frame to write
#' @param file_path Output file path
write_csv_data <- function(data, file_path) {
  tryCatch({
    write.csv(data, file_path, row.names = FALSE, quote = TRUE)

    if (!file.exists(file_path)) {
      stop("Output file was not created successfully")
    }

    cat("Updated CSV saved successfully:", file_path, "\n")

  }, error = function(e) {
    stop("Error writing CSV file: ", e$message)
  })
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main <- function() {
  cat("=============================================================================\n")
  cat("MOLECULE NAME REPLACEMENT SCRIPT\n")
  cat("=============================================================================\n\n")

  # Step 1: Validate input files exist and are readable
  cat("Step 1: Validating input files...\n")

  if (!check_file_exists(csv_file_path)) {
    stop("Cannot proceed: CSV file validation failed")
  }

  if (!check_file_exists(names_file_path)) {
    stop("Cannot proceed: Names file validation failed")
  }

  cat("✓ All input files validated successfully\n\n")

  # Step 2: Read molecule names from text file
  cat("Step 2: Reading molecule names...\n")
  molecule_names <- read_molecule_names(names_file_path)
  cat("✓ Molecule names loaded\n\n")

  # Step 3: Read CSV data
  cat("Step 3: Reading CSV data...\n")
  csv_data <- read_csv_data(csv_file_path)
  cat("✓ CSV data loaded\n\n")

  # Step 4: Validate row count match
  cat("Step 4: Validating data consistency...\n")
  if (length(molecule_names) != nrow(csv_data)) {
    stop(sprintf("CRITICAL ERROR: Row count mismatch!\n  CSV rows: %d\n  Names count: %d\n  These must match exactly for safe replacement.",
                 nrow(csv_data), length(molecule_names)))
  }
  cat("✓ Row counts match:", nrow(csv_data), "rows\n\n")

  # Step 5: Create backup
  cat("Step 5: Creating backup...\n")
  create_backup(csv_file_path, backup_file_path)
  cat("✓ Backup completed\n\n")

  # Step 6: Replace molecule names
  cat("Step 6: Replacing molecule names...\n")
  updated_csv <- replace_molecule_names(csv_data, molecule_names)

  # Display first few replacements for verification
  cat("\nFirst 5 name replacements:\n")
  for (i in 1:min(5, nrow(csv_data))) {
    cat(sprintf("  Row %d: '%s' → '%s'\n", i, csv_data$Molecule[i], updated_csv$Molecule[i]))
  }
  cat("✓ Molecule names replaced\n\n")

  # Step 7: Save updated CSV
  cat("Step 7: Saving updated CSV...\n")
  write_csv_data(updated_csv, csv_file_path)
  cat("✓ Updated CSV saved\n\n")

  # Final summary
  cat("=============================================================================\n")
  cat("PROCESS COMPLETED SUCCESSFULLY\n")
  cat("=============================================================================\n")
  cat("Summary:\n")
  cat("  • Processed", nrow(csv_data), "molecule records\n")
  cat("  • Original file backed up to:", backup_file_path, "\n")
  cat("  • Updated file saved to:", csv_file_path, "\n")
  cat("  • No other data was modified\n")
  cat("\nThe molecule name replacement process is now complete.\n")
}

# =============================================================================
# ERROR HANDLING AND EXECUTION
# =============================================================================

# Execute main function with comprehensive error handling
tryCatch({

  # Set working directory to script location if needed
  # Uncomment the next line if you want to set working directory automatically
  # setwd(dirname(rstudioapi::getSourceEditorContext()$path))

  main()

}, error = function(e) {
  cat("\n=============================================================================\n")
  cat("SCRIPT EXECUTION FAILED\n")
  cat("=============================================================================\n")
  cat("Error:", e$message, "\n")
  cat("\nPlease check:\n")
  cat("  1. File paths are correct\n")
  cat("  2. Files exist and are accessible\n")
  cat("  3. CSV file has proper format with 'Molecule' column\n")
  cat("  4. Names file has one name per line\n")
  cat("  5. Number of names matches number of CSV rows\n")
  cat("  6. You have write permissions in the target directory\n")

}, warning = function(w) {
  cat("Warning:", w$message, "\n")

}, finally = {
  cat("\n=============================================================================\n")
})

# End of script
