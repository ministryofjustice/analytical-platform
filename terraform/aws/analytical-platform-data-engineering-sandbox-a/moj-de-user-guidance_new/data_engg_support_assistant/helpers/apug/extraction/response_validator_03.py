
"""
Script Name: validate_text_chunks.py

Description:
    This script validates a folder containing extracted text chunks and their associated metadata files.
    It performs several checks to ensure data integrity and consistency, including:
        - Verifying that each text file (.txt) has a corresponding metadata file (.metadata.json) and vice versa.
        - Detecting duplicate text content by comparing MD5 hashes of files.
        - Identifying empty text files or files that cannot be opened.
    The script generates a detailed validation report that includes:
        - Counts of text and metadata files.
        - Lists of missing pairs (TXT without metadata and metadata without TXT).
        - Duplicate file pairs.
        - Empty text files.
    It also provides:
        - A pretty-printed report for console output.
        - An optional function to export the report in Markdown format for documentation or sharing.

Usage:
    - Set TEXT_FOLDER to the path of the directory containing text chunks and metadata.
    - Call `validate_text_chunks(TEXT_FOLDER)` to generate the validation report.
    - Use `print_report(report)` to display the report in the console.
    - Optionally, use `export_report_markdown(report, "report.md")` to save the report as a Markdown file.

Dependencies:
    - Python 3.x
    - Standard libraries: os, glob, hashlib, typing

Notes:
    - The script reads files in chunks to compute MD5 hashes efficiently.
    - Handles errors gracefully when opening files.
    - Designed for use in data processing pipelines where text chunks and metadata must remain consistent.
"""


import os
import glob
import hashlib
from typing import Dict, List, Tuple, Set, Optional

# --------------------
# Config: path to your text_chunks folder
# --------------------

TEXT_FOLDER = "../data/text_chunks"

# --------------------
# Hash helper
# --------------------
def file_hash(path: str) -> str:
    """Compute MD5 of a file (chunked read to avoid high memory)."""
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

# --------------------
# Core validation
# --------------------
def validate_text_chunks(text_folder: str) -> Dict:
    """
    Validate extracted text chunks and metadata in a folder.

    Checks:
      - Counts of .txt and .metadata.json
      - Pairing consistency (same base names)
      - Duplicate text content (MD5 hash)
      - Empty text files

    Returns:
      report: Dict with counts and lists (missing_meta, missing_txt, duplicates, empty_txt).
    """
    # Collect files recursively
    txt_files = glob.glob(os.path.join(text_folder, "**", "*.txt"), recursive=True)
    meta_files = glob.glob(os.path.join(text_folder, "**", "*.metadata.json"), recursive=True)

    # Base names
    txt_bases: Set[str] = {os.path.splitext(os.path.basename(f))[0] for f in txt_files}
    meta_bases: Set[str] = {os.path.basename(f).replace(".metadata.json", "") for f in meta_files}

    # Pairing consistency
    missing_meta = sorted(txt_bases - meta_bases)
    missing_txt  = sorted(meta_bases - txt_bases)

    # Duplicate content detection
    hash_map: Dict[str, str] = {}
    duplicates: List[Tuple[str, str]] = []
    for f in txt_files:
        h = file_hash(f)
        if h in hash_map:
            duplicates.append((f, hash_map[h]))  # (dup, original)
        else:
            hash_map[h] = f

    # Empty text files
    empty_txt: List[str] = []
    for f in txt_files:
        try:
            with open(f, "r", encoding="utf-8", errors="ignore") as fh:
                if not fh.read().strip():
                    empty_txt.append(f)
        except Exception as e:
            empty_txt.append(f"ERROR_OPENING::{f}::{e}")

    folder_abs = os.path.abspath(text_folder)
    status = "ok" if not (missing_meta or missing_txt or duplicates or empty_txt) else "warnings"

    return {
        "folder": folder_abs,
        "txt_count": len(txt_files),
        "meta_count": len(meta_files),
        "missing_meta": missing_meta,        # list[str] basenames
        "missing_txt": missing_txt,          # list[str] basenames
        "duplicates": duplicates,            # list[(dup_path, orig_path)]
        "empty_txt": empty_txt,              # list[str] paths (or error markers)
        "status": status,
    }

# --------------------
# Pretty printing
# --------------------
def _basename(path: str) -> str:
    """Return filename without directory (friendly display)."""
    return os.path.basename(path)

def print_report(report: Dict, *, max_items: int = 10) -> None:
    """
    Pretty-print the validation report with clean sections and aligned counts.

    Args:
        report: dict returned by validate_text_chunks()
        max_items: limit the number of list entries printed per section
    """
    folder = report["folder"]
    txt_count = report["txt_count"]
    meta_count = report["meta_count"]
    missing_meta = report["missing_meta"]
    missing_txt  = report["missing_txt"]
    duplicates   = report["duplicates"]
    empty_txt    = report["empty_txt"]
    status       = report["status"]

    # Header
    print(f"\n Validation report")
    print(f" Folder: {folder}")
    print("-" * 70)
    print(f"{'Total TXT files':<28}: {txt_count}")
    print(f"{'Total Metadata files':<28}: {meta_count}")
    print(f"{'Status':<28}: {' OK' if status == 'ok' else ' Warnings found'}")

    # Missing pairs
    if missing_meta or missing_txt:
        print("\n Pairing consistency")
        if missing_meta:
            print(f"  • TXT without metadata ({len(missing_meta)})")
            for b in missing_meta[:max_items]:
                print(f"    - {b}.txt")
            if len(missing_meta) > max_items:
                print(f"    … +{len(missing_meta) - max_items} more")
        else:
            print("  • TXT without metadata: none")

        if missing_txt:
            print(f"  • Metadata without TXT ({len(missing_txt)})")
            for b in missing_txt[:max_items]:
                print(f"    - {b}.metadata.json")
            if len(missing_txt) > max_items:
                print(f"    … +{len(missing_txt) - max_items} more")
        else:
            print("  • Metadata without TXT: none")
    else:
        print("\n Pairing consistency:  all pairs present")

    # Duplicates
    if duplicates:
        print(f"\n Duplicate text content ({len(duplicates)})")
        for dup, orig in duplicates[:max_items]:
            print(f"  - {_basename(dup)}  <=>  {_basename(orig)}")
        if len(duplicates) > max_items:
            print(f"  … +{len(duplicates) - max_items} more")
    else:
        print("\n Duplicate text content:  none detected")

    # Empty text files
    if empty_txt:
        print(f"\n Empty text files ({len(empty_txt)})")
        for p in empty_txt[:max_items]:
            print(f"  - {_basename(p)}")
        if len(empty_txt) > max_items:
            print(f"  … +{len(empty_txt) - max_items} more")
    else:
        print("\n Empty text files: none detected")

    print("-" * 70)

# --------------------
# Optional: Export to Markdown
# --------------------
def export_report_markdown(report: Dict, md_path: str, *, max_items: int = 50) -> None:
    """
    Export the validation report to a Markdown file for sharing in docs/PRs.

    Args:
        report: dict returned by validate_text_chunks()
        md_path: output .md path
        max_items: limit the number of list entries written per section
    """
    def md_list(items: List[str], suffix: str = "") -> str:
        lines = [f"- {i}{suffix}" for i in items[:max_items]]
        extra = len(items) - max_items
        if extra > 0:
            lines.append(f"- … +{extra} more")
        return "\n".join(lines)

    folder = report["folder"]
    txt_count = report["txt_count"]
    meta_count = report["meta_count"]
    missing_meta = report["missing_meta"]
    missing_txt  = report["missing_txt"]
    duplicates   = report["duplicates"]
    empty_txt    = report["empty_txt"]
    status       = report["status"]

    lines = []
    lines.append(f"# Validation Report\n")
    lines.append(f"- **Folder:** `{folder}`")
    lines.append(f"- **Total TXT files:** {txt_count}")
    lines.append(f"- **Total Metadata files:** {meta_count}")
    lines.append(f"- **Status:** {'OK' if status == 'ok' else 'Warnings found'}\n")

    # Pairing
    lines.append("## Pairing Consistency")
    if missing_meta:
        lines.append(f"- TXT without metadata ({len(missing_meta)}):\n{md_list(missing_meta, suffix='.txt')}")
    else:
        lines.append("- TXT without metadata: none")
    if missing_txt:
        lines.append(f"- Metadata without TXT ({len(missing_txt)}):\n{md_list(missing_txt, suffix='.metadata.json')}")
    else:
        lines.append("- Metadata without TXT: none")
    lines.append("")

    # Duplicates
    lines.append("## Duplicate Text Content")
    if duplicates:
        dup_lines = []
        for dup, orig in duplicates[:max_items]:
            dup_lines.append(f"- `{_basename(dup)}`  <=>  `{_basename(orig)}`")
        extra = len(duplicates) - max_items
        if extra > 0:
            dup_lines.append(f"- … +{extra} more")
        lines.extend(dup_lines)
    else:
        lines.append("- none")
    lines.append("")

    # Empty files
    lines.append("## Empty Text Files")
    if empty_txt:
        lines.extend([f"- `{_basename(p)}`" for p in empty_txt[:max_items]])
        extra = len(empty_txt) - max_items
        if extra > 0:
            lines.append(f"- … +{extra} more")
    else:
        lines.append("- none")
    lines.append("")

    os.makedirs(os.path.dirname(md_path) or ".", exist_ok=True)
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
