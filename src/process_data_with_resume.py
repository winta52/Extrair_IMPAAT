import requests
from bs4 import BeautifulSoup
import csv
import time
import sys
import os
import json
from datetime import datetime

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

def load_progress(progress_file):
    """Load previous progress from JSON file"""
    if os.path.exists(progress_file):
        try:
            with open(progress_file, 'r') as f:
                progress = json.load(f)
            print(f"Found previous progress: {len(progress['results'])} compounds processed")
            return progress
        except Exception as e:
            print(f"Error loading progress file: {e}")
            return None
    return None

def save_progress(progress_file, ids, results, current_index):
    """Save current progress to JSON file"""
    progress_data = {
        'timestamp': datetime.now().isoformat(),
        'total_compounds': len(ids),
        'processed_count': current_index + 1,
        'ids': ids,
        'results': results,
        'current_index': current_index
    }
    try:
        with open(progress_file, 'w') as f:
            json.dump(progress_data, f, indent=2)
    except Exception as e:
        print(f"Warning: Could not save progress: {e}")

def scrape_admet_properties(compound_id):
    """Scrape ADMET properties for a given compound ID"""
    url = f"https://cb.imsc.res.in/imppat/admetproperties/{compound_id}"

    try:
        # Send HTTP request with headers to appear more like a browser
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

        # Parse table rows to find target properties
        rows = table.find_all('tr')
        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 3:
                property_name = cells[0].get_text(strip=True)
                property_value = cells[2].get_text(strip=True)

                if 'Blood Brain Barrier permeation' in property_name:
                    bbb_permeation = property_value
                elif 'Gastrointestinal absorption' in property_name:
                    gi_absorption = property_value

        # Check if both properties were found
        if bbb_permeation is None or gi_absorption is None:
            print(f"Warning: Could not find required properties for {compound_id}")
            print(f"BBB: {bbb_permeation}, GI: {gi_absorption}")
            return None

        print(f"{compound_id}: BBB={bbb_permeation}, GI={gi_absorption}")

        # Apply the classification logic
        if bbb_permeation == "No" and gi_absorption == "Low":
            return 0
        elif bbb_permeation == "Yes" and gi_absorption == "High":
            return 1
        else:
            # Default value for other combinations
            return 0  # Setting default to 0 as per typical drug screening criteria

    except requests.exceptions.RequestException as e:
        print(f"Request error for {compound_id}: {e}")
        return None
    except Exception as e:
        print(f"Parsing error for {compound_id}: {e}")
        return None

def write_results_to_csv(csv_path, ids, results):
    """Write results to CSV file with original IDs and new results column"""
    try:
        # Create backup of original file
        backup_path = csv_path.replace('.csv', '_backup.csv')
        if os.path.exists(csv_path):
            import shutil
            shutil.copy2(csv_path, backup_path)
            print(f"Backup created: {backup_path}")

        with open(csv_path, 'w', newline='', encoding='utf-8') as file:
            writer = csv.writer(file)
            # Write header with new column
            writer.writerow(["IMPPAT phytochemical identifier", "ADMET_Classification"])

            # Write data rows
            for i, compound_id in enumerate(ids):
                result = results[i] if i < len(results) and results[i] is not None else "Error"
                writer.writerow([compound_id, result])

        print(f"Results successfully written to {csv_path}")
    except Exception as e:
        print(f"Error writing to CSV file: {e}")
        sys.exit(1)

def main():
    # Define paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    csv_input_path = os.path.join(project_root, "Output_csv", "imppat_ids.csv")
    progress_file = os.path.join(project_root, "scraping_progress.json")

    print("IMPPAT ADMET Properties Web Scraper with Resume Capability")
    print("=" * 60)

    # Check for existing progress
    progress = load_progress(progress_file)

    if progress:
        print(f"Previous session found:")
        print(f"- Processed: {progress['processed_count']}/{progress['total_compounds']}")
        print(f"- Last saved: {progress['timestamp']}")

        resume = input("Do you want to resume from where you left off? (y/n): ").lower().strip()
        if resume == 'y':
            ids = progress['ids']
            results = progress['results']
            start_index = progress['current_index'] + 1
            print(f"Resuming from compound {start_index + 1}")
        else:
            # Start fresh
            ids = read_csv_ids(csv_input_path)
            results = []
            start_index = 0
            # Remove old progress file
            if os.path.exists(progress_file):
                os.remove(progress_file)
    else:
        # Read IDs from CSV
        ids = read_csv_ids(csv_input_path)
        results = []
        start_index = 0

    # Initialize counters
    successful_scrapes = len([r for r in results if r is not None])
    failed_scrapes = len([r for r in results if r is None])

    print(f"Processing {len(ids) - start_index} remaining compounds...")
    print("This may take several minutes due to rate limiting...")
    print("Press Ctrl+C to stop and save progress at any time")

    try:
        # Process each ID starting from start_index
        for i in range(start_index, len(ids)):
            compound_id = ids[i]
            print(f"Processing {i + 1}/{len(ids)}: {compound_id}")

            # Scrape ADMET properties
            result = scrape_admet_properties(compound_id)

            # Ensure results list is the right size
            while len(results) <= i:
                results.append(None)

            results[i] = result

            if result is not None:
                successful_scrapes += 1
            else:
                failed_scrapes += 1
                print(f"Failed to process {compound_id}")

            # Save progress every 5 compounds
            if (i + 1) % 5 == 0:
                save_progress(progress_file, ids, results, i)
                print(f"Progress saved (processed {i + 1}/{len(ids)})")

            # Add delay to respect the website (0.5 seconds as specified)
            time.sleep(0.5)

            # Progress update every 10 compounds
            if (i + 1) % 10 == 0:
                print(f"Progress: {i + 1}/{len(ids)} completed ({successful_scrapes} successful, {failed_scrapes} failed)")

    except KeyboardInterrupt:
        print("\n\nProcess interrupted by user!")
        print(f"Processed {len([r for r in results if r is not None])}/{len(ids)} compounds")
        save_progress(progress_file, ids, results, len(results) - 1)
        print(f"Progress saved to {progress_file}")

        save_partial = input("Do you want to save partial results to CSV? (y/n): ").lower().strip()
        if save_partial == 'y':
            write_results_to_csv(csv_input_path, ids, results)

        print("You can resume later by running this script again.")
        return

    print("\nScraping completed successfully!")
    print(f"Total processed: {len(ids)}")
    print(f"Successful: {successful_scrapes}")
    print(f"Failed: {failed_scrapes}")

    # Write final results to CSV
    write_results_to_csv(csv_input_path, ids, results)

    # Summary statistics
    valid_results = [r for r in results if r is not None]
    if valid_results:
        count_0 = valid_results.count(0)
        count_1 = valid_results.count(1)
        print(f"\nClassification Results:")
        print(f"Class 0 (BBB=No, GI=Low or other combinations): {count_0}")
        print(f"Class 1 (BBB=Yes, GI=High): {count_1}")
        print(f"Success rate: {len(valid_results)/len(ids)*100:.1f}%")

    # Clean up progress file
    if os.path.exists(progress_file):
        os.remove(progress_file)
        print("Progress file cleaned up.")

if __name__ == "__main__":
    main()
