# IMPPAT Data Extraction - Usage Guide

## Overview

This script extracts "IMPPAT phytochemical identifier" data from the IMPPAT website (https://cb.imsc.res.in/imppat/) based on specific search criteria and saves the results to a CSV file.

## Prerequisites

### Python Requirements
- Python 3.6 or higher
- Required packages (install using pip):

```bash
pip install -r requirements.txt
```

Or install individually:
```bash
pip install requests>=2.25.1 beautifulsoup4>=4.9.3 lxml>=4.6.3
```

### Network Requirements
- Internet connection to access the IMPPAT website
- Firewall/proxy settings should allow HTTP/HTTPS requests to `cb.imsc.res.in`

## Usage

### Basic Usage

Navigate to the project directory and run the script:

```bash
cd C:\Dev\Faculdade\Extrair_IMPAAT
python src/extract_data(2).py
```

### Search Parameters

The script is configured to search for:
- **Search field**: "Indian medicinal plant"
- **Search for**: "Camellia Sinensis"
- **Filter for**: "leaf"

To modify these parameters, edit the `search_data` dictionary in the `perform_search()` method:

```python
search_data = {
    'field': 'Indian medicinal plant',
    'searchfor': 'Your_Plant_Name',
    'filterfor': 'Your_Filter_Criteria'
}
```

## Output

### CSV File
- **Location**: Project root directory (`C:\Dev\Faculdade\Extrair_IMPAAT\`)
- **Filename**: `imppat_identifiers.csv`
- **Format**: Single column with header "IMPPAT phytochemical identifier"

### Log File
- **Location**: Same directory as the script
- **Filename**: `extraction.log`
- **Content**: Detailed logging information including errors, progress, and debugging info

## Script Features

### Error Handling
The script includes comprehensive error handling for:
- Network connectivity issues
- Website timeouts
- HTML parsing errors
- File I/O errors
- Unexpected website structure changes

### Logging
- Real-time progress updates in the console
- Detailed logs saved to `extraction.log`
- Different log levels (INFO, WARNING, ERROR)

### Respectful Web Scraping
- Uses appropriate User-Agent headers
- Implements delays between requests
- Maintains session cookies
- Handles form tokens automatically

## Troubleshooting

### Common Issues

1. **Network Errors**
   - Check internet connection
   - Verify firewall/proxy settings
   - The IMPPAT website might be temporarily unavailable

2. **No Data Found**
   - Website structure may have changed
   - Search parameters might not return results
   - Check the log file for detailed error messages

3. **Permission Errors**
   - Ensure write permissions for the output directory
   - Check if the CSV file is open in another application

### Debug Mode

To get more detailed output, you can modify the logging level in the script:

```python
logging.basicConfig(level=logging.DEBUG, ...)
```

## Script Architecture

The script follows the flowchart design and includes these main components:

1. **IMPPATExtractor Class**: Main extraction logic
2. **fetch_homepage()**: Establishes session with the website
3. **navigate_to_search_page()**: Loads the search interface
4. **perform_search()**: Executes search with specified parameters
5. **parse_html_and_extract_data()**: Extracts identifiers from results
6. **save_to_csv()**: Saves data to CSV format

## Customization

### Changing Output Format
To modify the CSV output, edit the `save_to_csv()` method:

```python
# Change header
writer.writerow(['Your_Custom_Header'])

# Add additional columns
writer.writerow([identifier, additional_data])
```

### Adding New Search Fields
Modify the `search_data` dictionary in `perform_search()` to include additional search parameters based on the website's form structure.

### Changing Output Location
Modify the `filename` parameter in the `save_to_csv()` method call or provide a full path:

```python
csv_file = self.save_to_csv(identifiers, "custom_output.csv")
```

## Support

For issues or questions:
1. Check the log file (`extraction.log`) for detailed error information
2. Verify that the IMPPAT website is accessible manually
3. Ensure all dependencies are correctly installed
4. Review the script's error handling sections for specific error types

## Legal and Ethical Considerations

- This script is designed for educational and research purposes
- Please respect the website's terms of service and robots.txt
- Implement appropriate delays between requests to avoid overloading the server
- Use the extracted data responsibly and in accordance with applicable laws and regulations