
"""
stats.py
--------
Utilities for computing page-level statistics from extracted sections, logging a concise
summary, and detecting anomalies.

Design goals:
- Pure functions where possible (easy to unit test).
- Configurable paths and thresholds.
- Robust to missing files and legacy keys.

Typical usage:
    from helpers.stats import compute_page_stats, log_page_stats, detect_anomalies

    stats = compute_page_stats(sections, text_dir="data/text")
    log_line = log_page_stats(url, title, stats)
    anomalies = detect_anomalies(stats, max_images=50)
"""

from __future__ import annotations

import json
import logging
import os
from typing import Dict, List, Optional, Tuple


def compute_page_stats(
    sections: List[Dict],
    text_dir: str,
    *,
    paragraph_splitter: Optional[str] = "\n\n",
    include_image_placeholders: bool = False,
) -> Dict[str, int | float]:
    """
    Read each section's metadata and text to compute per-page statistics.

    Args:
        sections: List of section dicts produced by extraction pipeline. Each typically includes:
                  - "level": 1 (intro) or 2 (H2 section)
                  - "metadata_file": filename for metadata JSON
                  - "text_file": filename for section text
        text_dir: Directory where text/metadata files are stored.
        paragraph_splitter: Heuristic delimiter to split paragraphs; default is blank-line split.
        include_image_placeholders: If True, count "[Image: ...]" lines as paragraphs (default False).

    Returns:
        stats: Dictionary of aggregated metrics, including:
            - sections_total
            - sections_intro
            - sections_h2
            - chunks_text
            - paragraphs_total
            - links_total
            - images_total
            - sections_with_links
            - sections_with_images
            - avg_paragraphs_per_section
            - percent_sections_with_links
            - percent_sections_with_images
    """
    stats: Dict[str, int | float] = {
        "sections_total": len(sections),
        "sections_intro": sum(1 for s in sections if s.get("level") == 1),
        "sections_h2":    sum(1 for s in sections if s.get("level") == 2),

        "chunks_text": 0,
        "paragraphs_total": 0,
        "links_total": 0,
        "images_total": 0,

        # Additional derived metrics
        "sections_with_links": 0,
        "sections_with_images": 0,
        "avg_paragraphs_per_section": 0.0,
        "percent_sections_with_links": 0.0,
        "percent_sections_with_images": 0.0,
    }

    # Local counters for per-section contributions
    sections_counted_for_paragraphs = 0

    for s in sections:
        meta_file = s.get("metadata_file")
        txt_file = s.get("text_file") or s.get("text")  # fallback for older key names

        # --- Read metadata for links/images ---
        links_in_section = 0
        images_in_section = 0
        if meta_file:
            meta_path = os.path.join(text_dir, meta_file)
            try:
                with open(meta_path, "r", encoding="utf-8") as f:
                    meta = json.load(f)
                # links list: [{"text": "...", "url": "..."}]
                links_in_section = len(meta.get("links", []) or [])
                # images list (optional): [{"alt": "...", "url": "..."}], if you store it
                images_in_section = len(meta.get("images", []) or [])
                stats["links_total"]  += links_in_section
                stats["images_total"] += images_in_section

                if links_in_section > 0:
                    stats["sections_with_links"] += 1
                if images_in_section > 0:
                    stats["sections_with_images"] += 1

            except FileNotFoundError:
                logging.info(f"[STATS] metadata not found (expected): {meta_path}")
            except Exception as e:
                logging.warning(f"[STATS] failed to read metadata {meta_path}: {e}")

        # --- Read text to estimate paragraphs ---
        if txt_file:
            txt_path = os.path.join(text_dir, txt_file)
            try:
                with open(txt_path, "r", encoding="utf-8") as f:
                    txt = f.read()
                stats["chunks_text"] += 1

                # Heuristic: split paragraphs by blank lines; ignore list lines and image placeholders
                segments = [seg.strip() for seg in txt.split(paragraph_splitter)]
                if include_image_placeholders:
                    paras = [p for p in segments if p]
                else:
                    paras = [
                        p for p in segments
                        if p and not p.startswith("- ") and not p.startswith("[Image:")
                    ]
                stats["paragraphs_total"] += len(paras)
                sections_counted_for_paragraphs += 1

            except FileNotFoundError:
                logging.info(f"[STATS] text not found (expected): {txt_path}")
            except Exception as e:
                logging.warning(f"[STATS] failed to read text {txt_path}: {e}")

    # --- Derived metrics ---
    if sections_counted_for_paragraphs > 0:
        stats["avg_paragraphs_per_section"] = round(
            stats["paragraphs_total"] / sections_counted_for_paragraphs, 2
        )

    if stats["sections_total"] > 0:
        stats["percent_sections_with_links"] = round(
            (stats["sections_with_links"] / stats["sections_total"]) * 100, 2
        )
        stats["percent_sections_with_images"] = round(
            (stats["sections_with_images"] / stats["sections_total"]) * 100, 2
        )

    return stats


def log_page_stats(
    url: str,
    title: Optional[str],
    stats: Dict[str, int | float],
    *,
    logger: logging.Logger = logging.getLogger(__name__),
    level: int = logging.INFO,
) -> str:
    """
    Log a concise one-line summary of per-page counts and return the string.

    Args:
        url: Page URL (used as fallback label).
        title: Page title (preferred label).
        stats: Dictionary returned by `compute_page_stats`.
        logger: Logger to use (defaults to module logger).
        level: Logging level (defaults to INFO).

    Returns:
        The formatted stats line as a string (also logged).
    """
    label = (title or url).strip()
    line = (
        f"[STATS] {label} | "
        f"sections={stats.get('sections_total', 0)} "
        f"(intro={stats.get('sections_intro', 0)}, h2={stats.get('sections_h2', 0)}), "
        f"chunks={stats.get('chunks_text', 0)}, paragraphs={stats.get('paragraphs_total', 0)}, "
        f"links={stats.get('links_total', 0)} ({stats.get('percent_sections_with_links', 0.0)}%), "
        f"images={stats.get('images_total', 0)} ({stats.get('percent_sections_with_images', 0.0)}%), "
        f"avg_paras/section={stats.get('avg_paragraphs_per_section', 0.0)}"
    )
    logger.log(level, line)
    return line


def detect_anomalies(
    stats: Dict[str, int | float],
    *,
    max_images: int = 50,
    min_sections_expected: int = 1,
    require_h2_if_intro: bool = True,
) -> List[str]:
    """
    Return a list of anomaly strings if thresholds or logical expectations fail.

    Args:
        stats: Dictionary returned by `compute_page_stats`.
        max_images: Upper bound for total images before flagging anomaly (default 50).
        min_sections_expected: Minimum number of sections expected (default 1).
        require_h2_if_intro: If True, flag anomaly when intro exists but no H2 sections.

    Returns:
        List of anomaly messages.
    """
    anomalies: List[str] = []

    # Basic expectations
    if stats.get("sections_total", 0) < min_sections_expected:
        anomalies.append("no sections extracted")
    if stats.get("chunks_text", 0) == 0:
        anomalies.append("no text chunks saved")

    # Logical expectation: if intro exists but no H2 sections
    if require_h2_if_intro and stats.get("sections_intro", 0) > 0 and stats.get("sections_h2", 0) == 0:
        anomalies.append("intro exists but no H2 sections")

    # Links but no paragraphs
    if stats.get("links_total", 0) > 0 and stats.get("paragraphs_total", 0) == 0:
        anomalies.append("links present but no paragraphs")

    # Image upper bound
    if stats.get("images_total", 0) > max_images:
        anomalies.append("unusually high image count")

    # Optional derived checks
    if stats.get("avg_paragraphs_per_section", 0.0) == 0.0 and stats.get("sections_total", 0) > 0:
        anomalies.append("average paragraphs per section is zero")

    return anomalies
