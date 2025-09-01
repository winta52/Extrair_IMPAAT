import csv
from bs4 import BeautifulSoup

def extract_imppat_ids_from_html(html_file_paths, csv_file_path):
    """
    Extracts IMPPAT phytochemical identifiers from HTML tables in multiple files and saves them to a CSV file.

    Args:
        html_file_paths (list): A list of paths to the HTML files.
        csv_file_path (str): The path to the CSV file to be created.
    """

    all_imppat_ids = []

    for html_file_path in html_file_paths:
        try:
            with open(html_file_path, 'r', encoding='utf-8') as html_file:
                html_content = html_file.read()

            soup = BeautifulSoup(html_content, 'html.parser')

            # Find the table containing the data.  The table has id="table_id".
            table = soup.find('table', {'id': 'table_id'})

            if table is None:
                print(f"Error: Table with id 'table_id' not found in the HTML: {html_file_path}")
                continue

            # Extract the data from the "IMPPAT Phytochemical identifier" column.
            imppat_ids = []
            for row in table.find_all('tr'):
                # Get all the cells in the row
                cells = row.find_all('td')

                # Check if the row has enough cells
                if len(cells) >= 3:
                    # Get the 3rd cell, which contains the IMPPAT ID
                    imppat_id_cell = cells[2]
                    # Extract the link from the cell.
                    link = imppat_id_cell.find('a')
                    if link:
                        imppat_ids.append(link.text.strip())

            all_imppat_ids.extend(imppat_ids)

            print(f"Successfully extracted {len(imppat_ids)} IMPPAT IDs from {html_file_path}")

        except FileNotFoundError:
            print(f"Error: HTML file not found at {html_file_path}")
        except Exception as e:
            print(f"An error occurred while processing {html_file_path}: {e}")

    # Write the extracted data to a CSV file.
    try:
        with open(csv_file_path, 'w', newline='', encoding='utf-8') as csv_file:
            csv_writer = csv.writer(csv_file)

            # Define the header for the CSV file.
            csv_writer.writerow(["IMPPAT phytochemical identifier"])

            # Write each extracted identifier as a row in the CSV file.
            for imppat_id in all_imppat_ids:
                csv_writer.writerow([imppat_id])

        print(f"Successfully extracted {len(all_imppat_ids)} IMPPAT IDs and saved them to {csv_file_path}")

    except Exception as e:
        print(f"An error occurred while writing to CSV: {e}")


if __name__ == "__main__":
    html_file_paths = [
        "html_files/IMPPAT _ IMPPAT_ Indian Medicinal Plants, Phytochemistry And Therapeutics.htm",
        "html_files/IMPPAT _ IMPPAT_ Indian Medicinal Plants, Phytochemistry And Therapeutics.html"
    ]
    csv_file_path = "Output_csv/imppat_ids.csv"
    extract_imppat_ids_from_html(html_file_paths, csv_file_path)
