
"""
File: tests/test_extraction_pipeline.py

Description:
    Unit tests for the HTML content extraction pipeline.
    This test verifies that hierarchical content (headings and associated text)
    is correctly extracted from HTML and saved as paired `.txt` and `.metadata.json` files.

Key Points:
    - Uses BeautifulSoup to parse a sample HTML snippet containing H1 and H2 headings.
    - Monkeypatches `save_text_and_metadata` to write output into a temporary directory
      instead of the real filesystem.
    - Calls `extract_hierarchical_content()` from `helpers.extraction` and validates:
        * Correct number of extracted sections (intro + one H2 section).
        * Headings match expected values.
        * Output files (.txt and .metadata.json) are created for each section.

Test Expectations:
    - `results` should contain 2 entries: ["Data Platform", "Overview"].
    - Temporary folder should contain 4 files (2 text + 2 metadata).

Dependencies:
    - pytest (for `tmp_path` and `monkeypatch` fixtures)
    - BeautifulSoup (for HTML parsing)
    - Project module: helpers.extraction

Usage:
    Run with pytest:
        pytest tests/test_extraction_pipeline.py
"""

# tests/test_extraction_pipeline.py
import os
import sys
from bs4 import BeautifulSoup

# Ensure project root is on sys.path so `helpers` is importable
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from helpers.apug.extraction.extraction_01 import extract_hierarchical_content
import helpers.apug.extraction.extraction_01 as extraction_mod

# Sample code to test
HTML = """
<html>
  <body>
    <h1>Data Platform</h1>
    <p>Intro paragraph.</p>
    <h2>Overview</h2>
    <p>Section text.</p>
  </body>
</html>
"""
b = soup = BeautifulSoup(HTML, "html.parser")

print("H1 text:", b.find("h1").get_text(strip=True) if b.find("h1") else None)
print("H2 count:", len(b.find_all("h2")))

def test_extract_hierarchical_content(tmp_path, monkeypatch):
    # Monkeypatch save_text_and_metadata to write into the tmp folder
    def fake_save(text, metadata, filename):
        (tmp_path / f"{filename}.txt").write_text(text, encoding="utf-8")
        (tmp_path / f"{filename}.metadata.json").write_text(str(metadata), encoding="utf-8")
    monkeypatch.setattr(extraction_mod, "save_text_and_metadata", fake_save)

    soup = BeautifulSoup(HTML, "html.parser")
    results = extract_hierarchical_content(
        soup,
        page_url="https://example.com",
        page_id="1",
        DOWNLOAD_IMAGES=False,
        HEADERS={}
    )
    # Expect intro (H1) and the H2 section
    assert len(results) == 2

    # Explicit heading check
    headings = [r["heading"] for r in results]
    assert headings == ["Data Platform", "Overview"]

    # 2 .txt + 2 .metadata.json
    files = list(tmp_path.glob("*"))
    assert len(files) == 4