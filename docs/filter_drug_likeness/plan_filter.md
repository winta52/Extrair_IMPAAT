# Project Plan: Drug-Likeness Filtering from SwissADME Data

## Objective
Develop an R script to process the `swissadme_unified.csv` file and filter molecules based on drug-likeness rules. Molecules that violate **3 or more** of the following rules will be filtered out and excluded from the output:
- Lipinski #violations
- Ghose #violations
- Veber #violations
- Egan #violations
- Muegge #violations

The output will be a CSV file containing only selected columns for the molecules that violate **2 or fewer** rules, along with process logging and a summary report.

## Requirements
- **Input file:** `swiss_adme_info/swissadme_unified.csv`
- **Output directory:** `Output_csv/`
- **Log directory:** `logs/`
- **Script location:** `src/` (R script)
- **Column names:** Must match exactly as in the input CSV
- **Selected columns for output:**
  - Molecule
  - Canonical SMILES
  - Bioavailability Score
  - Lipinski #violations
  - Ghose #violations
  - Veber #violations
  - Egan #violations
  - Muegge #violations

## Filtering Criteria
- **Maximum allowed violations:** 2 rules
- **Filtering threshold:** Molecules violating 3 or more rules will be excluded
- **Violation definition:** A rule is considered violated if its violation count > 0
- **Example scenarios:**
  - Molecule violating Ghose, Veber, and Muegge rules → **FILTERED OUT** (3 violations)
  - Molecule violating only Lipinski and Egan rules → **RETAINED** (2 violations)
  - Molecule violating only Veber rule → **RETAINED** (1 violation)
  - Molecule violating no rules → **RETAINED** (0 violations)

## Workflow
1. **Read Input Data**
   - Load the CSV file using exact column names.
   - If any required column is missing, warn the user and stop execution.

2. **Filter Molecules**
   - For each molecule, count how many of the five rule violation columns have values > 0.
   - If the total number of violated rules ≥ 3, discard the molecule.
   - If any required value is missing for a molecule, warn the user (log and/or console) and exclude from output.

3. **Write Output**
   - Save the filtered data to a new CSV file in `Output_csv/` (e.g., `swissadme_druglike_filtered.csv`).
   - Only include the selected columns in the output file.
   - Do not overwrite existing files with the same name; if the file exists, create a new file with a suffix (e.g., `swissadme_druglike_filtered_2.csv`).

4. **Logging**
   - Log the process to a file in `logs/` (e.g., `filter_drug_likeness.log`).
   - Log the start and end of the process, number of molecules processed, number filtered out, and any warnings (e.g., missing data).
   - Log specific details about violation counts for transparency.

5. **Summary Report**
   - At the end of the process, generate a summary (printed and logged) including:
     - Total molecules processed
     - Total molecules passing the filter (≤2 violations)
     - Total molecules filtered out (≥3 violations)
     - Number of molecules with missing data
     - Distribution of molecules by violation count (0, 1, 2, 3, 4, 5 violations)
     - Count of molecules failing each individual rule
   - Optionally, write this summary to a separate text or CSV file in `Output_csv/` or `logs/`.

## Configuration
- All configuration (input/output paths, file names, etc.) will be done by editing variables at the top of the R script.
- **MAX_VIOLATIONS_ALLOWED:** Configurable threshold (default: 2)
- No interactive prompts; the script is intended to be run as a batch process.

## Error Handling
- If required columns are missing, stop with an error and log the issue.
- If a molecule has missing data in any required column, warn the user (log and/or console), and exclude the molecule from the output.
- Handle non-numeric values in violation columns gracefully with appropriate warnings.

## Extensibility
- The script should be easy to adapt for future changes:
  - Changing the violation threshold (e.g., from 2 to 1 or 3)
  - Adding/removing rules or columns by editing configuration variables
  - Modifying which columns are included in the output
- The workflow should be modular, with clear separation between reading, filtering, writing, and reporting.

## Deliverables
- R script in `src/` implementing the above workflow
- Output CSV file with filtered molecules in `Output_csv/`
- Log file in `logs/`
- Summary report (in log and/or separate file) with detailed violation statistics

## Expected Output Statistics
The summary should include:
- Molecules with 0 violations: X molecules (retained)
- Molecules with 1 violation: X molecules (retained)
- Molecules with 2 violations: X molecules (retained)
- Molecules with 3 violations: X molecules (filtered out)
- Molecules with 4 violations: X molecules (filtered out)
- Molecules with 5 violations: X molecules (filtered out)
- Total retained: X molecules
- Total filtered out: X molecules
