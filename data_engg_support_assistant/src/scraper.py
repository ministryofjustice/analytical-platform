
# =============================================================================
# Notebook: Analytical Platform Guidance — Site Crawler & Hierarchical Extractor
# =============================================================================
# Overview
# --------
# This notebook crawls the Analytical Platform user-guidance website starting from
# `apug_base_url`, extracts hierarchical content (Pre‑H2 intro + H2-guided sections),
# saves each section as a text chunk with metadata, optionally downloads images,
# and writes a consolidated JSON with per-page statistics and anomaly flags.
#
# What this notebook does
# -----------------------
# 1) Crawl internal links within the base domain (breadth-first).
# 2) For each page:
#    - Parse HTML and extract content between H1 → first H2 (intro).
#    - Extract each H2 section (H2 → next H2), walking descendants to capture:
#      paragraphs, list items, blockquotes, images, and subheadings (H3/H4).
#    - Save a `.txt` and a matching `.metadata.json` for each section.
#    - (Optional) Download images referenced in the content to `IMAGE_DIR`.
# 3) Compute per-page stats (sections, chunks, paragraphs, links, images).
# 4) Flag anomalies (e.g., “no sections extracted”, “links present but no paragraphs”).
# 5) Write the full crawl output to `OUTPUT requests.# 5) Write the full crawl output to `OUTPUT_JSON`.
# - DOWNLOAD_IMAGES:   Toggle image downloading (True/False).
# - TEXT_DIR:          Folder for text chunks & metadata (set in helper/module).
# - IMAGE_DIR:         Folder for downloaded images (set in helper/module).
# - PROCESSED_DIR:     Folder for processed JSON outputs (set in helper/module).
# - OUTPUT_JSON:       Path to the consolidated site-level JSON.
#
# Key functions (expected to be imported/defined)
# -----------------------------------------------
# - extract_hierarchical_content(soup, url, page_id, DOWNLOAD_IMAGES, HEADERS)
#     Extracts Pre‑H2 + H2 sections, saves `.txt` & `.metadata.json`, returns a
#     list of section descriptors (heading, level, file names).
#
# - compute_page_stats(sections, text_dir=TEXT_DIR)
#     Reads saved files and computes per-page counts for sections, chunks,
#     paragraphs, links, and images.
#
# - log_page_stats(url, title, stats)
#     Logs a concise one-line summary per page; returns the formatted log line.
#
# - detect_anomalies(stats)
#     Returns anomaly strings (e.g., “no sections extracted”, “intro exists but no H2 sections”).
#
# Outputs
# -------
# - Text chunks     →  TEXT_DIR/{page_id}_{counter}.txt
# - Metadata JSON   →  TEXT_DIR/{page_id}_{counter}.metadata.json
# - Images (opt)    →  IMAGE_DIR/{filename}
# - Crawl JSON      →  OUTPUT_JSON (site-level dictionary of pages and stats)
#
# How to run
# ----------
# 1) Adjust configuration (base URL, headers, delay, DOWNLOAD_IMAGES).
# 2) Ensure directories exist (the code creates `PROCESSED_DIR` if missing).
# 3) Run `scrape_site()` cell to start the crawl.
# 4) Review console logs and anomalies; inspect files in `TEXT_DIR` and `IMAGE_DIR`.
# 5) Use `OUTPUT_JSON` for downstream indexing/search.
#
# Logging & Debugging
# -------------------
# - Crawl progress:   `[CRAWL] <url>`
# - Errors:           `[ERROR] ...` or `logging.error(...)`
# - Stats summary:    `[STATS] <title> | sections=... chunks=... paragraphs=... links=... images=...`
# - Anomalies:        `[ANOMALY] <url> -> <reason(s)>`
# - Save confirmation (from helper): text/metadata success messages.
#
# Edge Cases & Notes
# ------------------
# - Pages without `<h2>`: handled via a no‑H2 fallback (intro chunk from after H1).
# - Blockquotes: captured per `<p>` inside `<blockquote>`; links inside are preserved.
# - Empty paragraphs: ignored; save conditions ensure only meaningful content is written.
# - JS-rendered pages: if a page relies on client-side rendering, `requests+BeautifulSoup`
#   may miss content; consider a headless browser (e.g., Playwright) for those pages.
# - URL normalization: `urldefrag` strips fragments; domain checks restrict to internal links.
#
# Planned Enhancements:
# ---------------------
# - Add fallback for pages without `<h2>` (capture all content after H1).
# - Deduplicate text parts before saving.
# - Add debug prints for saved chunks (items count, first snippet).
# - Improve anomaly detection (e.g., warn if only images or blockquotes exist).
# - Normalize URLs to avoid duplicate crawling.
# - Add CLI flags for base URL, delay, and image toggle.
# - Build vector index from extracted chunks for RAG chatbot integration.
#
# Ethics & Politeness:
# ---------------------
# - Respect `robots.txt` and site terms.
# - Keep `DELAY` reasonable to avoid overloading the server.
# - Identify scraper via `HEADERS["User-Agent"]`.
#
# Inputs & Configuration
# ----------------------
# - apug_base_url:     Base URL to crawl (internal links only).
# - HEADERS:           HTTP headers (e.g., User-Agent).
# =============================================================================

# Import required libraries
import os
import sys
import time
import json
import logging
import requests
from bs4 import BeautifulSoup, Tag
from urllib.parse import urljoin, urldefrag, urlparse

# Add project root to Python path
sys.path.append(os.path.abspath(os.path.join(os.getcwd(), "..")))

from helpers.apug.extraction import extract_hierarchical_content, PROCESSED_DIR, TEXT_DIR
from helpers.apug.old_rag.stats import compute_page_stats, log_page_stats, detect_anomalies

# -------------------
# Configuration
# ------------------
apug_base_url = "https://user-guidance.analytical-platform.service.justice.gov.uk"
HEADERS = {"User-Agent":"InternalScraper/1.0"} # Label for the scrapping
DELAY = 0.5
DOWNLOAD_IMAGES =True

# Create the parent directory if it doesn't exist
OUTPUT_JSON = os.path.join(PROCESSED_DIR, "scraped_hierarchical_h2h3h4.json")
os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)

# --------------------------
# Main crawler
# --------------------------

def scrape_site():
    """
    Crawl the entire site starting from the base URL:
      - Fetch each page.
      - Extract hierarchical content (headings, paragraphs, bullets, images).
      - Discover new internal links and add them to the crawl queue.
      - Save all extracted data as a JSON file.
    """
 
    visited = set()       # Track URLs already processed to avoid duplicates
    output = {}           # Store scraped data for each page
    to_crawl = [apug_base_url]  # Initialize queue with the base URL
    
    while to_crawl:
        # Get next URL from queue and remove any fragment (#section)
        url = url = urldefrag(to_crawl.pop(0))[0]
       
       # Skip if already visited or outside the base domain
        if url in visited or not url.startswith(apug_base_url):
            continue
        visited.add(url)
        print(f"[CRAWL]{url}")

        # Fetch page content
        try:
            resp = requests.get(url, headers = HEADERS, timeout = 10)
            resp.raise_for_status() # Raise error for HTTP 4xx/5xx
        except Exception as e:
            print(f"[ERROR] failed: {e}") # Log error and skip this URL
            continue

        # Parse HTML
        soup = BeautifulSoup(resp.text, "html.parser")
        # Extract page title (prefer <h1>, fallback to <title>)
        title_tag = soup.h1 or soup.title
        title = title_tag.get_text(strip=True) if title_tag else ""
        page_id = str(len(visited))

        # Extract hierarchical content
        try:
            sections = extract_hierarchical_content(
                soup, 
                url ,
                page_id,
                DOWNLOAD_IMAGES, 
                HEADERS
                )
        except Exception as e:
            logging.error(f"[ERROR] extract_hierarchical_content failed for {url}: {e}")
            continue

        #Compute & log per-page stats
        stats = compute_page_stats(sections, text_dir=TEXT_DIR)
        log_line = log_page_stats(url, title, stats)
        anomalies = detect_anomalies(stats)
        if anomalies:
            logging.warning(f"[ANOMALY] {url} -> {', '.join(anomalies)}")

        # Save structured data for this page
        output[url] = {
            "url" : url,
            "title" : title,
            "sections" : sections,
            "stats": stats,
        }

        # Discover and enqueue new links
        for a in soup.find_all("a", href=True):
            link = urljoin(url, a['href']) # Resolve relative URLs
            link = urldefrag(link)[0] # Remove fragments
            # Only add internal links not yet visited
            if link.startswith(apug_base_url) and link not in visited:
                to_crawl.append(link)
        
        # Respect crawl delay to avoid overwhelming the server
        time.sleep(DELAY)

    # Save all scraped data to JSON
    with open(OUTPUT_JSON, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii= False)

    print("\n Done! Scraped hierarchical content saved to scraped_hierarchical.json")

if __name__ == "__main__":
    scrape_site()