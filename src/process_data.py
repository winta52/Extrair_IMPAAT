import requests
from bs4 import BeautifulSoup
import csv
import time
import sys
import os
import json

def read_csv_ids(csv_path):
    """Read IMPPAT IDs from CSV file"""
    ids = []
    try:
        with open(csv_path, 'r', newline='', encoding='utf-8') as file:
            reader = csv.reader(file)
            header = next(reader)  # Skip header
            for row in reader:
                if row:  # Skip empty rows
                    ids.append(row[0])
        print(f"Successfully loaded {len(ids)} IDs from CSV file")
        return ids
    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        sys.exit(1)

def save_progress(progress_file, results):
    """Save current progress to a JSON file"""
    try:
        with open(progress_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2)
    except Exception as e:
        print(f"Warning: Could not save progress: {e}")

def load_progress(progress_file):
    """Load previous progress from JSON file"""
    try:
        if os.path.exists(progress_file):
            with open(progress_file, 'r', encoding='utf-8') as f:
                return json.load(f)
    except Exception as e:
        print(f"Warning: Could not load progress: {e}")
    return {}

def scrape_admet_properties(compound_id, max_retries=3):
    """Scrape ADMET properties for a given compound ID with retry logic"""
    url = f"https://cb.imsc.res.in/imppat/admetproperties/{compound_id}"

    for attempt in range(max_retries):
        try:
            # Send HTTP request with headers to mimic a browser
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
            response = requests.get(url, timeout=30, headers=headers)
            response.raise_for_status()

            # Parse HTML content
            soup = BeautifulSoup(response.content, 'html.parser')

            # Find the ADMET properties section
            contact2_div = soup.find('div', id='contact2')
            if not contact2_div:
                print(f"Error: Could not find ADMET properties section for {compound_id}")
                return None

            # Find the table with ADMET properties
            table = contact2_div.find('table', class_='table table-bordered table-sm')
            if not table:
                print(f"Error: Could not find ADMET properties table for {compound_id}")
                return None

            # Initialize variables to store the target properties
            bbb_permeation = None
            gi_absorption = None

            # Parse table rows to find target
