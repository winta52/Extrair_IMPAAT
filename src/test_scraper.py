import requests
from bs4 import BeautifulSoup
import csv
import time
import sys
import os

def test_single_compound(compound_id):
    """Test scraping for a single compound ID"""
    url = f"https://cb.imsc.res.in/imppat/admetproperties/{compound_id}"
    print(f"Testing URL: {url}")

    try:
        # Send HTTP request
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        print(f"HTTP Status: {response.status_code}")

        # Parse HTML content
        soup = BeautifulSoup(response.content, 'html.parser')

        # Find the ADMET properties section
        contact2_div = soup.find('div', id='contact2')
        if not contact2_div:
            print(f"Error: Could not find ADMET properties section")
            return None

        print("Found ADMET properties section")

        # Find the table with ADMET properties
        table = contact2_div.find('table', class_='table table-bordered table-sm')
        if not table:
            print(f"Error: Could not find ADMET properties table")
            return None

        print("Found ADMET properties table")

        # Initialize variables to store the target properties
        bbb_permeation = None
        gi_absorption = None

        # Parse table rows to find target properties
        rows = table.find_all('tr')
        print(f"Found {len(rows)} rows in table")

        for i, row in enumerate(rows):
            cells = row.find_all('td')
            if len(cells) >= 3:
                property_name = cells[0].get_text(strip=True)
                property_value = cells[2].get_text(strip=True)

                print(f"Row {i}: {property_name} = {property_value}")

                if 'Blood Brain Barrier permeation' in property_name:
                    bbb_permeation = property_value
                    print(f"Found BBB: {bbb_permeation}")
                elif 'Gastrointestinal absorption' in property_name:
                    gi_absorption = property_value
                    print(f"Found GI: {gi_absorption}")

        # Check if both properties were found
        if bbb_permeation is None or gi_absorption is None:
            print(f"Warning: Could not find required properties")
            print(f"BBB: {bbb_permeation}, GI: {gi_absorption}")
            return None

        print(f"Final results - BBB: {bbb_permeation}, GI: {gi_absorption}")

        # Apply the classification logic
        if bbb_permeation == "No" and gi_absorption == "Low":
            result = 0
            print(f"Classification: 0 (BBB=No AND GI=Low)")
        elif bbb_permeation == "Yes" and gi_absorption == "High":
            result = 1
            print(f"Classification: 1 (BBB=Yes AND GI=High)")
        else:
            result = 0  # Default value
            print(f"Classification: 0 (default for BBB={bbb_permeation}, GI={gi_absorption})")

        return result

    except requests.exceptions.RequestException as e:
        print(f"Request error: {e}")
        return None
    except Exception as e:
        print(f"Parsing error: {e}")
        return None

def test_multiple_compounds():
    """Test scraping for the first few compounds from the CSV"""
    # Define paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    csv_input_path = os.path.join(project_root, "Output_csv", "imppat_ids.csv")

    # Read first 3 IDs from CSV for testing
    test_ids = []
    try:
        with open(csv_input_path, 'r', newline='', encoding='utf-8') as file:
            reader = csv.reader(file)
            header = next(reader)  # Skip header
            for i, row in enumerate(reader):
                if i >= 3:  # Only test first 3 compounds
                    break
                if row:  # Skip empty rows
                    test_ids.append(row[0])
    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_input_path}")
        return

    print(f"Testing with {len(test_ids)} compounds: {test_ids}")
    print("=" * 60)

    results = []
    for i, compound_id in enumerate(test_ids, 1):
        print(f"\nTest {i}/{len(test_ids)}: {compound_id}")
        print("-" * 40)

        result = test_single_compound(compound_id)
        results.append((compound_id, result))

        if i < len(test_ids):  # Don't wait after last compound
            print("Waiting 1 second before next request...")
            time.sleep(1)

    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    for compound_id, result in results:
        status = "SUCCESS" if result is not None else "FAILED"
        print(f"{compound_id}: {result} ({status})")

def main():
    print("IMPPAT ADMET Properties Scraper - TEST MODE")
    print("=" * 50)

    # Test with the known working example first
    print("Testing with known working example: IMPHY015133")
    print("-" * 50)
    test_result = test_single_compound("IMPHY015133")
    print(f"Test result: {test_result}")

    print("\n" + "=" * 50)
    input("Press Enter to continue with CSV test compounds...")

    # Test with first few compounds from CSV
    test_multiple_compounds()

if __name__ == "__main__":
    main()
