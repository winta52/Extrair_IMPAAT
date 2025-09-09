Extrair_IMPAAT\docs\unify_swiss_adme_info\plan_unify.md
# Project Plan: Unification of SwissADME CSV Files

## Objective

Unify all CSV files present in the `swiss_adme_info` directory into a single CSV file named `swissadme_unified.csv` for downstream processing. The process must be robust, modular, cross-platform, and provide detailed logging for traceability and reproducibility.

---

## Requirements

### Input
- All `.csv` files in the `swiss_adme_info` directory are to be merged.
- All input files are UTF-8 encoded and have the same columns in the same order.
- The unified file itself (if present) must be excluded from merging.

### Output
- A single UTF-8 encoded CSV file named `swissadme_unified.csv` saved in the `swiss_adme_info` directory.
- The output file should include the header only once (from the first file).
- All rows from all input files should be included, with no deduplication or sorting.
- If the output file already exists, it should be overwritten.

### Logging
- All actions, including script start/finish, files merged, number of rows per file, and errors, must be logged.
- Logs should be appended to a single log file (e.g., `unify.log`) in the `logs` directory.
- Each log entry should be a single line, as detailed as possible, and also printed to the console.
- Log file name can be chosen by the implementer (default: `unify.log`).

### Configuration
- Input directory, output file path, and log file path should be configurable at the top of the script.
- The script should be modular and easily rerunnable.

### Platform & Language
- The script must be written in R and run cross-platform (Windows, Linux, Mac).
- No external dependencies beyond base R and standard CSV handling packages (e.g., `readr`, `data.table`, or `utils`).

---

## Implementation Plan

### 1. Script Configuration

- Define variables for:
  - Input directory (default: `swiss_adme_info`)
  - Output file path (default: `swiss_adme_info/swissadme_unified.csv`)
  - Log file path (default: `logs/unify.log`)
- Allow these to be changed at the top of the script for flexibility.

### 2. File Discovery

- List all `.csv` files in the input directory.
- Exclude the output file (`swissadme_unified.csv`) if it exists in the directory.
- Sort files alphabetically for reproducibility (optional).

### 3. Logging Setup

- Open the log file in append mode.
- Define a logging function that writes a single-line entry to both the log file and the console.
- Log script start time, configuration, and discovered files.

### 4. Merging Logic

- Initialize an empty data structure for the unified data.
- For each input file:
  - Read the file using UTF-8 encoding.
  - For the first file, include the header; for subsequent files, skip the header.
  - Log the file name and number of rows read.
  - On error (e.g., file read failure, malformed CSV), log the error and stop execution.
- After all files are processed, write the unified data to the output file, overwriting if it exists.
- Log the total number of rows written and script completion time.

### 5. Error Handling

- If any error occurs (file read, write, or unexpected data), log the error with details and stop the script.
- Ensure partial/unified files are not left in an inconsistent state.

### 6. Console Output

- All log messages should also be printed to the console for real-time feedback.

### 7. Documentation & Usage

- The script should include comments explaining configuration, usage, and expected behavior.
- Example usage:
  - Place all input CSVs in `swiss_adme_info`.
  - Run the script in R: `source("unify_swissadme.R")` or via Rscript.
  - Check `swiss_adme_info/swissadme_unified.csv` for output and `logs/unify.log` for logs.

---

## Example Log Entry Format

```
2024-06-01 12:00:00 | INFO | Script started | input_dir=swiss_adme_info | output_file=swissadme_unified.csv
2024-06-01 12:00:01 | INFO | Found 13 input files
2024-06-01 12:00:02 | INFO | Merged file: 1-5 swissadme.csv | rows=5
2024-06-01 12:00:02 | INFO | Merged file: 6-10 swissadme.csv | rows=5
2024-06-01 12:00:03 | ERROR | Failed to read file: 11-15 swissadme.csv | reason=Malformed CSV
2024-06-01 12:00:04 | INFO | Output written | rows=68 | file=swissadme_unified.csv
2024-06-01 12:00:04 | INFO | Script finished
```

---

## Summary of Steps

1. **Configure script paths and options.**
2. **Discover all input CSV files, excluding the output file.**
3. **Set up logging to file and console.**
4. **Iteratively read and merge all CSVs, handling headers and errors.**
5. **Write the unified CSV, overwriting if necessary.**
6. **Log all actions and errors in detail.**
7. **Provide clear documentation and usage instructions in the script.**

---

## Next Steps

- Implement the script in R according to this plan.
- Test with the current set of files in `swiss_adme_info`.
- Review logs and output for correctness and completeness.
- Adjust configuration as needed for future reruns or directory changes.

---