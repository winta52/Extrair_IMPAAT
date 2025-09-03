import csv
import time
import re
import requests
import os

# Constants
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_CSV = os.path.join(BASE_DIR, "Output_csv", "imppat_ids.csv")
OUTPUT_CSV = os.path.join(BASE_DIR, "Output_csv", "imppat_ids_with_data.csv")
LOG_FILE = os.path.join(BASE_DIR, "logs", "scrape.log")
BASE_URL = "https://cb.imsc.res.in/imppat/phytochemical-detailedpage/"
REQUEST_DELAY = 0.5  # seconds

def log(message):
    """Append a message to the log file."""
    with open(LOG_FILE, "a", encoding="utf-8") as logf:
        logf.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - {message}\n")

def read_input_ids(input_csv):
    """Read input CSV and return list of IDs with ADMET_Classification == 1."""
    ids = []
    with open(input_csv, newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if row.get("ADMET_Classification") == "1":
                ids.append(row["IMPPAT phytochemical identifier"])
    return ids

def extract_name_smiles(html):
    """Extract molecule name and SMILES from HTML content."""
    # Extract molecule name
    name_match = re.search(
        r"<strong>Phytochemical name:</strong>\s*([^<\n]+)", html)
    molecule_name = name_match.group(1).strip() if name_match else None

    # Extract SMILES
    smiles_match = re.search(
        r"<strong>SMILES:</strong><br\s*/?><text[^>]*>([^<]+)</text>", html)
    smiles = smiles_match.group(1).strip() if smiles_match else None

    return molecule_name, smiles

def fetch_html(url):
    """Fetch HTML content from URL."""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.text
    except Exception as e:
        log(f"ERROR fetching {url}: {e}")
        return None

def main():
    log("Script started.")
    # Read input CSV and get IDs to process
    ids_to_process = read_input_ids(INPUT_CSV)
    log(f"Found {len(ids_to_process)} IDs to process.")

    # Prepare to read input CSV and write output CSV
    with open(INPUT_CSV, newline='', encoding='utf-8') as infile, \
         open(OUTPUT_CSV, "w", newline='', encoding='utf-8') as outfile:

        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            log("ERROR: Input CSV has no header row or is malformed.")
            return
        fieldnames = list(reader.fieldnames) + ["Molecule Name", "SMILES"]
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()

        for row in reader:
            id_val = row["IMPPAT phytochemical identifier"]
            if row.get("ADMET_Classification") == "1":
                url = BASE_URL + id_val
                log(f"Processing {id_val} at {url}")
                html = fetch_html(url)
                if html:
                    molecule_name, smiles = extract_name_smiles(html)
                    if molecule_name and smiles:
                        row["Molecule Name"] = molecule_name
                        row["SMILES"] = smiles
                        log(f"SUCCESS: {id_val} - Name: {molecule_name}, SMILES: {smiles}")
                    else:
                        row["Molecule Name"] = ""
                        row["SMILES"] = ""
                        log(f"ERROR: Could not extract data for {id_val}")
                else:
                    row["Molecule Name"] = ""
                    row["SMILES"] = ""
                    log(f"ERROR: No HTML for {id_val}")
                time.sleep(REQUEST_DELAY)
            else:
                row["Molecule Name"] = ""
                row["SMILES"] = ""
            writer.writerow(row)

    log("Script finished.")

if __name__ == "__main__":
    main()
