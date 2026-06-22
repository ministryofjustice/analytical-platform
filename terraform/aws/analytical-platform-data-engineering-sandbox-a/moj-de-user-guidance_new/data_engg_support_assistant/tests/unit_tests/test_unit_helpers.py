
"""
File: tests/test_naming_utils.py

Description:
    Unit tests for naming utilities used in the extraction pipeline:
      - slugify(): normalizes headings into filesystem-safe, URL-friendly slugs.
      - generate_unqiue_filename(): builds unique filenames from H1/H2 headings
        with collision handling via USED_FILENAMES.

What’s covered:
    - slugify basic normalization (lowercasing, hyphenation).
    - removal of punctuation/symbols.
    - expected fallback behavior for empty strings (project-specific -> "page").
    - generate_unqiue_filename behavior:
        * H1-only filenames.
        * H1 + H2 composite filenames with underscore separator.
        * Collision handling: second identical input receives a suffix.

Test data & assumptions:
    - Collisions are tracked in a shared set/dict: USED_FILENAMES.
      Tests clear this structure before each scenario.
    - Composite names follow: "{slug(H1)}_{slug(H2)}".
    - Empty H1/H2 fall back align with current project expectations.
      If you decide a different fallback (e.g., "section"), update both
      implementation and tests accordingly.

Usage:
    Run with pytest:
        pytest tests/test_naming_utils.py
    or run the whole test suite:
        pytest

Dependencies:
    - pytest
    - Project module: helpers.extraction (slugify, generate_unqiue_filename, USED_FILENAMES)

Notes:
    - The function name in helpers.extraction is spelled "generate_unqiue_filename".
      Consider renaming to "generate_unique_filename" in code and tests for clarity.
    - Ensure project root is on sys.path so `helpers` is importable.
"""

import os
import sys
import pytest

# Add project root to Python path
sys.path.append(os.path.abspath(os.path.join(os.getcwd(), "..")))
from helpers.apug.extraction.extraction_01 import slugify, generate_unqiue_filename, USED_FILENAMES

# -----------------------
# slugify tests
# -----------------------

def test_slugify_basic():
    assert slugify("Data Platform Overview") == "data-platform-overview"

def test_slugify_symbols():
    assert slugify("Hello ! world??") == "hello-world"

def test_slugify_empty_string():
    # Your generate_filename uses slugify(h1 or "page"),
    # so for slugify("") alone your project expects "page"
    # If you want slugify("") -> "section", change slugify impl.
    assert slugify("") == "page"  # align with your current usage


# -----------------------
# generate_filename tests
# -----------------------
def test_generate_unqiue_filename_h1_only():
    USED_FILENAMES.clear()
    fname = generate_unqiue_filename("Data Platform", None, 'page1')
    assert fname =="data-platform"

def test_generate_unique_filename_h1_h2():
    USED_FILENAMES.clear()
    fname = generate_unqiue_filename("Data Platform", "Overview", 'page1')
    assert fname =="data-platform_overview"

def test_generate_unique_filename_collision():
    USED_FILENAMES.clear()
    fname1 = generate_unqiue_filename("Data Platform", "Overview", "page1")
    fname2 = generate_unqiue_filename("Data Platform", "Overview", "page1")
    assert fname1 != fname2
    assert fname2.startswith("data-platform_overview-")

