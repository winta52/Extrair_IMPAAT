import requests
from bs4 import BeautifulSoup
import pandas as pd
import time
import logging
import os

# --- Configuration ---
INPUT_CSV = "C:/Dev/Faculdade/Extrair_IMPAAT/Output_csv/imppat_ids_with_data.csv"
OUTPUT_CSV = "C:/Dev/Faculdade/Extrair_IMPAAT/Output_csv/imppat_ids_with_data_rule_of_5.csv"
LOG_FILE = "C:/Dev/Faculdade/Extrair_IMPAAT/logs/scrape.log"
RULE_COL_NAME = "Lipinski_Rule_of_5_Pass"
BASE_URL = "https://cb.imsc.res.in/imppat/druglikeproperties/{}"
RATE_LIMIT_SECONDS = 2

# --- Logging Setup ---
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def log_and_print(msg, level="info"):
    print(msg)
    getattr(logging, level)(msg)

def extract_rule_of_5(html):
    """Extracts Lipinski's rule of 5 result from HTML. Returns 1 for Passed, 0 for Failed, None if not found."""
    soup = BeautifulSoup(html, "html.parser")
    # Find the table row for Lipinski’s rule of 5
    for tr in soup.find_all("tr"):
        tds = tr.find_all("td")
        if len(tds) >= 3 and "Lipinski’s rule of 5" in tds[0].get_text(strip=True):
            value = tds[2].get_text(strip=True)
            if value.lower() == "passed":
                return 1
            elif value.lower() == "failed":
                return 0
    return None

def process_id(mol_id):
    url = BASE_URL.format(mol_id)
    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        rule_val = extract_rule_of_5(resp.text)
        if rule_val is not None:
            log_and_print(f"SUCCESS: {mol_id} - Rule of 5: {rule_val}", "info")
            return rule_val
        else:
            log_and_print(f"ERROR: {mol_id} - Rule of 5 not found", "warning")
            return None
    except Exception as e:
        log_and_print(f"ERROR: {mol_id} - {str(e)}", "error")
        return None

def main():
    log_and_print("Script started.", "info")
    # Load input CSV
    df = pd.read_csv(INPUT_CSV)
    # Only process rows with ADMET_Classification == 1
    selected = df[df["ADMET_Classification"] == 1].copy()
    log_and_print(f"Found {len(selected)} IDs to process.", "info")
    rule_results = []
    for idx, row in selected.iterrows():
        mol_id = row["IMPPAT phytochemical identifier"]
        rule_val = process_id(mol_id)
        rule_results.append((idx, rule_val))
        time.sleep(RATE_LIMIT_SECONDS)
    # Add results to DataFrame
    df[RULE_COL_NAME] = None
    for idx, rule_val in rule_results:
        df.at[idx, RULE_COL_NAME] = rule_val
    # Save output CSV
    df.to_csv(OUTPUT_CSV, index=False)
    log_and_print(f"Script finished. Output written to {OUTPUT_CSV}", "info")

if __name__ == "__main__":
    main()
