
"""
File: validate_output_runner.py

Description:
    This script validates the extracted text chunks and their associated metadata files
    in the `../data/text_chunks` directory. It uses helper functions from
    `helpers.validate_output` to:
        - Check pairing consistency between `.txt` and `.metadata.json` files.
        - Detect duplicates and empty text files.
        - Generate a detailed validation report.

Workflow:
    1. Calls `validate_text_chunks()` to produce a report dictionary.
    2. Prints a formatted summary to the console using `print_report()`.
    3. Exports the full report to a Markdown file (`../reports/validation.md`)
       for documentation or sharing.

Usage:
    Run this script directly or from a notebook cell:
        python validate_output_runner.py
    Or in Jupyter:
        %run validate_output_runner.py

Output:
    - Console: Human-readable validation summary.
    - File: Markdown report saved to `../reports/validation.md`.

Dependencies:
    - Python 3.x
    - Project module: helpers.validate_output
    - Standard library: os, sys

Notes:
    - Ensure the `../data/text_chunks` folder exists and contains extracted files.
    - Adjust `max_items` in `print_report()` and `export_report_markdown()` for
      longer or shorter lists in the output.
"""

import os
import sys

# Add project root to Python path
sys.path.append(os.path.abspath(os.path.join(os.getcwd(), "..")))
from helpers.apug.extraction.response_validator_03 import validate_text_chunks, print_report, export_report_markdown

report = validate_text_chunks("../data/text_chunks")
print_report(report, max_items=15)  # show up to 15 per section
export_report_markdown(report, "../reports/validation.md", max_items=100)