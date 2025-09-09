# Project Plan: Automated Replacement of Molecule Names in CSV

## Objective

To automate the process of updating the "Molecule" column in the `swissadme_unified.csv` file by replacing all existing names (both generic and specific) with a new, ordered list of molecule names provided in `names_of_molecules.txt`. The process must ensure data integrity, create a backup of the original CSV, and make no other changes to the dataset.

---

## Background

The current CSV file contains a mix of generic molecule names (e.g., "Molecule 1") and specific names. For consistency and accuracy, all names should be replaced with the correct names from a curated TXT file, where each line corresponds to the intended name for each row in the CSV.

---

## Detailed Steps

### 1. Input File Handling

- **CSV File:**
  - Path: `swiss_adme_info/swissadme_unified.csv`
  - Contains all molecule data, with the first column labeled "Molecule".
- **TXT File:**
  - Path: `swiss_adme_info/names_of_molecules.txt`
  - Contains the new molecule names, one per line, in the exact order they should appear in the CSV.

### 2. Data Validation

- Ensure the number of lines in `names_of_molecules.txt` matches the number of data rows in the CSV (excluding the header).
- If there is a mismatch, the script should halt and report an error to prevent misalignment.

### 3. Backup

- Before making any changes, create a backup of the original CSV file.
  - The backup should be saved in the same directory, with a timestamp or `_backup` suffix (e.g., `swissadme_unified_backup.csv`).

### 4. Name Replacement Logic

- Read the CSV file into memory, preserving all columns and data.
- Read the TXT file into a list or vector.
- Replace the value in the "Molecule" column for each row with the corresponding name from the TXT file, strictly by order (first TXT line to first data row, etc.).
- Do not alter any other columns or data.

### 5. Output

- Save the updated CSV file, overwriting the original or as a new file (as per user preference).
- Ensure the output file is saved in the same directory as the original.

---

## Script Requirements

- The script must be written in R.
- It should use robust file reading and writing functions (`read.csv`, `write.csv`, etc.).
- Include error handling for file existence, read/write permissions, and row count mismatches.
- The script should be well-commented for clarity and future maintenance.

---

## Deliverables

- **R Script** that performs the above steps automatically.
- **Updated CSV File** with all molecule names replaced.
- **Backup CSV File** preserving the original data.

---

## Example Workflow

1. User runs the R script.
2. Script checks that both files exist and are readable.
3. Script validates that the number of names matches the number of rows.
4. Script creates a backup of the original CSV.
5. Script replaces all molecule names in the CSV.
6. Script writes the updated CSV to disk.
7. User is notified of completion and the location of the backup.

---

## Notes

- No other data transformation or manipulation is to be performed.
- The process is fully automated and repeatable.
- This approach ensures traceability and data integrity throughout the update process.

---