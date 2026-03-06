"""
    Script Name: metadata_validator.py

    Description:
        Utilities to validate Amazon Bedrock Knowledge Base metadata files before upload/ingestion.
        The primary entry point is `validate_metadata_file(filepath)`, which checks a single
        JSON metadata file against size and schema constraints and returns a list of human‑readable
        issue strings. An empty list means the file passed all validations.

    What this validates:
        1) File size:
            - Rejects files larger than MAX_FILE_SIZE.
            NOTE: In this script MAX_FILE_SIZE is set to 10 * 1014 (≈ 10,140 bytes),
            which is close to (but not exactly) 10 KB.
        2) JSON structure:
            - Rejects files that are not valid JSON.
        3) Required top-level key:
            - Ensures "metadataAttributes" exists.
            - Ensures "metadataAttributes" is a dictionary.
        4) Keys & values in "metadataAttributes":
            - Key length must be <= MAX_KEY_LENGTH (default 255).
            - Value must be non-null (no None) and, if a string, non-empty (not just whitespace).
            - Value types allowed: str, int, float, bool (see ALLOWED_VALUE_TYPES).
            - Lists and dicts are not allowed as values.
            - String values must be <= MAX_VALUE_LENGTH (default 1000 chars).

    Constants:
        - MAX_FILE_SIZE       = 10 * 1014   # ~10 KB (approx.)
        - MAX_KEY_LENGTH      = 255
        - MAX_VALUE_LENGTH    = 1000
        - ALLOWED_VALUE_TYPES = (str, int, float, bool)

    Function:
        validate_metadata_file(filepath: str) -> list[str]
            - Parameters:
                filepath: Path to a JSON metadata file ending with ".metadata.json".
            - Returns:
                A list of issue strings. If the list is empty, the file is considered valid.

    Typical usage (Notebook or Script):
        >>> from helpers.metada_validater import validate_metadata_file
        >>> issues = validate_metadata_file("../data/text_chunks/guides/my-file.txt.metadata.json")
        >>> if issues:
        ...     for issue in issues:
        ...         print("-", issue)
        ... else:
        ...     print("No issues found.")

    Example outputs (reflecting this validator’s exact messages):

        1) File too large:
            - "File size 15234 bytes exceeds 10KB limit"

        2) Invalid JSON:
            - "Invalid JSON:Expecting property name enclosed in double quotes: line 12 column 5 (char 231)"

        3) Missing or invalid 'metadataAttributes':
            - "Missing 'metadataAttributes' key"
            - "'metadataAttributes' is not a dict"

        4) Attribute key/value problems:
            - "key 'very_long_key_name_...' exceeds 255 characters"
            - "key'missing_title' has null value"
            - "key'description' has empty string"
            - "key'links' has unsupported type list/dict"
            - "key 'rating' has unsupported type NoneType"
            - "Value for key 'summary' is too long (1345 chars)"

    Notes:
        - This module does not modify files; it only reports issues.
        - Integrate with your uploader or ingestion pipeline to fail fast when issues are present.
        - Ensure your calling code handles the return value (a list of strings) appropriately.

"""

import json
import os
import sys

# Add project root to Python path
sys.path.append(os.path.abspath(os.path.join(os.getcwd(), "..")))

filepath = "../data/text_chunks"

# ----------------------
# Bedrock metadata Constriants
# ----------------------

MAX_FILE_SIZE = 10* 1014 # 10KB
MAX_KEY_LENGTH = 255
MAX_VALUE_LENGTH = 1000
ALLOWED_VALUE_TYPES = (str, int, float, bool)


def validate_metadata_file(filepath):

    issues = []

    # ----------------
    # Check file size
    # ----------------
    file_size = os.path.getsize(filepath)
    if file_size > MAX_FILE_SIZE:
        issues.append(f"File size {file_size} bytes exceeds 10KB limit")
    

    # ----------------
    # Load JSON file
    # ----------------
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            metadata = json.load(f)
    except Exception as e:
        issues.append(f"Invalid JSON:{e}")
        return issues
    
    # ----------------
    # metadata Attributes must exist
    # ----------------
    if "metadataAttributes" not in metadata:
        issues.append("Missing 'metadataAttributes' key")
        return issues
    
    attrs = metadata["metadataAttributes"]

    # Must be a dictionary
    if not isinstance(attrs, dict):
        issues.append("'metadataAttributes' is not a dict")
        return issues
    
    # ----------------
    # validate keys & issues
    # ----------------
    for key, value in attrs.items():

        # key length
        if len(key) > MAX_KEY_LENGTH:
            issues.append(f"key '{key}' exceeds {MAX_KEY_LENGTH} characters")

        # value must not be null or empty
        if value is None:
            issues.append(f"key'{key}' has null value")
            continue

        if isinstance(value, str) and value.strip() =="":
            issues.append(f"key'{key}' has empty string")

        # Unsupported complex objects
        if isinstance(value, (list, dict)):
            issues.append(f"key'{key}' has unsupported type list/dict")
            continue

        # Allowed types
        if not isinstance(value, ALLOWED_VALUE_TYPES):
            issues.append(f"key '{key}' has unsupported type {type(value).__name__}")
            continue

        # Value length for strings
        if isinstance(value, str) and len(value) > MAX_VALUE_LENGTH:
            issues.append(
                f"Value for key '{key}' is too long ({len(value)} chars)"
            )
    
    return issues

