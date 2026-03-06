
"""
helper.py
----------
This module contains utility functions for extracting structured content from HTML pages.
Functions include:
    - save_text_and_metadata(): Saves extracted text and metadata to files.
    - extract_paragraph_with_links(): Extracts paragraph text and associated links.
    - resolve_img_url(): Resolves image URLs from src, data-src, or srcset.
    - walk_section(): Extracts text, links, and images from a section.
    - download_image(): Downloads images to local storage.
    - tag_siblings(): Yields sibling tags for section parsing.
    - extract_pre_h2(): Extracts content before the first <h2>.
    - extract_h2_sections(): Extracts content under each <h2>.
    - extract_no_h2_section(): Handles pages without <h2>.
    - extract_hierarchical_content(): Orchestrates full page extraction.
   

Purpose:
    These helpers are used by the main scraper to process HTML pages into structured text and metadata.
"""
# Import required libraries
import os
import re
import json
import time
import requests
import logging
from typing import List, Dict
from bs4 import NavigableString, Tag
from urllib.parse import urljoin, urldefrag, urlparse

from typing import Dict, List, Tuple
from urllib.parse import urlparse, unquote

# -----------------------------
# Configure Logging
# -----------------------------

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# -----------------------------
# Directory Setup
# -----------------------------
BASE_DIR = os.path.join("..", "data")  # Adjust for notebooks folder
TEXT_DIR = os.path.join(BASE_DIR, "text_chunks")
IMAGE_DIR = os.path.join(BASE_DIR, "images")
PROCESSED_DIR = os.path.join(BASE_DIR, "processed")

os.makedirs(TEXT_DIR, exist_ok=True)
os.makedirs(IMAGE_DIR, exist_ok=True)
os.makedirs(PROCESSED_DIR, exist_ok=True)

# -----------------------------
# Slugify helper
# -----------------------------

def slugify(text: str) -> str:
    """
    Convert text into a slug suitable for filenames:
    - Lowercase
    - Replace non-alphanumeric characters with '-'
    - Strip leading/trailing '-'
    """
    if not text:
        return "page"
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")

def generate_filename(h1: str, h2: str | None, page_id:str, section_counter:int) -> str:
    """
    Safely generate a filename based on H1 and H2
    Falls back t page_id_sectionCounter if slug is invalid/empty
    """
    try:
        h1_slug = slugify(h1 or "page")
        h2_slug = slugify(h2) if h2 else None

        # If both are valid non-empty slugs  --> use them
        if h2_slug and (h2_slug or h2 is None):
            if h2_slug:
                return f"{h1_slug}_{h2_slug}"
            return h1_slug
    except Exception:
        pass # Fallback
    # Fallback 
    return f"{page_id}_{section_counter}"

USED_FILENAMES = set()

def generate_unqiue_filename(h1, h2, fallback_base):
    """
    Safely generate a filename based on H1 and H2
    Falls back t page_id_sectionCounter if slug is invalid/empty
    """

    try:
        h1_slug = slugify(h1 or "page")
        if h2:
            h2_slug = slugify(h2) 
            base_name = f"{h1_slug}_{h2_slug}"
        else:
            base_name = h1_slug
    except:
        base_name = fallback_base

    # Ensure uniqueness
    filename= base_name
    counter = 1
    while filename in USED_FILENAMES:
        counter += 1
        filename = f"{base_name}-{counter}"
    
    USED_FILENAMES.add(filename)
    return filename

def get_main_h1(body, soup):
    """
    Get the most relevant H1 for the page:
    - Prefer first <h1> inside <main> or body
    - Fallback to any <h1> in the page
    - Last fallback: <title> or 'page'
    """
    # First try <main> or <body>
    h1_tag = body.find("h1")
    if h1_tag and h1_tag.get_text(strip=True):
        return h1_tag.get_text(strip=True)

    # Next: any where in the soup
    h1_tag = soup.find("h1")
    if h1_tag and h1_tag.get_text(strip=True):
        return h1_tag.get_text(strip=True)

    # Last fallback: <title> or 'page'
    title_tag = soup.title
    if title_tag and title_tag.get_text(strip=True):
        return title_tag.get_text(strip=True)
    
    return "page"

# ---------------------------
# Save .txt + .metadata.json
# ---------------------------

def save_text_and_metadata(text, metadata, base_filename):
    """
    Save scraped text and its associated metadata into separate files with error handling.

    Args:
        text (str): The raw text content to save.
        metadata (dict): Metadata information related to the text (e.g., source URL, timestamp).
        base_filename (str): Base name for the files without extension.
    """

    try:
        # Ensure TEXT_DIR exists before writing files
        if not os.path.exists(TEXT_DIR):
            logging.warning(f"Directory {TEXT_DIR} does not exist. Creating it...")
            os.makedirs(TEXT_DIR, exist_ok=True)

        # Construct file paths
        text_path = os.path.join(TEXT_DIR, f"{base_filename}.txt")
        meta_path = os.path.join(TEXT_DIR, f"{base_filename}.txt.metadata.json")

        # Save text content
        try:
            with open(text_path, "w", encoding="utf-8") as f:
                f.write(text.strip())
            logging.info(f"Text saved successfully at {text_path}")
        except Exception as e:
            logging.error(f"Failed to save text file: {e}")
            return False

        # Save metadata as JSON
        try:
            with open(meta_path, "w", encoding="utf-8") as f:
                json.dump(metadata, f, indent=2, ensure_ascii=False)
            logging.info(f"Metadata saved successfully at {meta_path}")
        except Exception as e:
            logging.error(f"Failed to save metadata file: {e}")
            return False

        return True

    except Exception as e:
        logging.critical(f"Failed to save files: {e}")
        return False
    

# ---------------------------------------
# Extract paragraph/list text with links
# ---------------------------------------
def extract_paragraph_with_links(tag, base_url):
    """
    Extracts plain text and hyperlinks from a BeautifulSoup tag (e.g., <p>), 
    returns Markdown-ready text with inline links and a structured list of links.

    Args:
        tag: A BeautifulSoup element whose descendants will be scanned (e.g., a <p> tag).
        base_url (str): The base URL used to resolve relative hrefs via urljoin.

    Returns:
        tuple:
            - final_text (str): Combined paragraph text where <a> tags are converted 
              into Markdown-style links: link text.
            - links (list[dict]): A list of link dictionaries with keys:
                {"text": <link text>, "url": <absolute URL>}
    """

    # Accumulators for textual content and extracted link metadata
    text_parts = []
    links = []

    # Iterate through all descendants (text nodes and elements) inside the tag
    for element in tag.descendants:

        # If the descendant is a plain text node (NavigableString), append its content
        if isinstance(element, NavigableString):
            # Convert to str to avoid issues with special types and ensure concatenation
            text_parts.append(str(element))

        # If the descendant is an anchor element (<a>) with an href attribute
        elif getattr(element, "name", None) == "a" and element.get("href"):
            # Extract the human-readable text inside the link
            # - get_text(" ", strip=True) collapses internal whitespace and trims ends
            link_text = element.get_text(" ", strip=True)

            # Resolve the href against the base URL (handles relative URLs gracefully)
            link_url = urljoin(base_url, element["href"])

            # Append Markdown inline link representation to text stream
            text_parts.append(f"[{link_text}]")

            # Also collect a structured representation for downstream processing
            links.append({"text": link_text, "url": link_url})

    # Join all text parts:
    # 1) First join contiguous parts without delimiter to preserve original flow.
    # 2) Then split() to normalize whitespace (collapse multiple spaces/newlines).
    # 3) Finally join with single spaces and trim leading/trailing whitespace.
    final_text = " ".join("".join(text_parts).split()).strip()

    # Return the Markdown-ready text and the link list
    return final_text, links

# -----------------------------
# Resolve image URL (src, data-src, srcset)
# -----------------------------
def resolve_img_url(img_tag, page_url):
    """
    Resolve an <img> URL using src, data-src, or srcset (first candidate).
    Returns (img_url, filename) or (None, None) if nothing is usable.
    """
    # Try src or data-src first
    src = img_tag.get("src") or img_tag.get("data-src")

    if not src and img_tag.get("srcset"):
        # srcset example: "img1.png 1x, img2.png 2x" or "small.jpg 320w, large.jpg 1024w"
        first_candidate = img_tag.get("srcset").split(",")[0].strip()
        src = first_candidate.split(" ")[0]  # URL part before descriptor

    if not src:
        return None, None

    img_url = urljoin(page_url, src)
    filename = os.path.basename(urlparse(img_url).path) or f"img_{int(time.time()*1000)}.png"
    return img_url, filename


def fill_empty_link_text(link: Dict[str, str]) -> Tuple[str, str]:
    """
    Returns (text, url) where text is guaranteed if possible.
    If link['text'] is empty, derive it from the last non-empty path segment of the URL.
    Fallbacks:
      - If path is empty, use the URL's hostname (netloc).
      - Percent-encodings are decoded.
      - Trailing slashes are ignored when picking the segment.
    """
    text = (link.get("text") or "").strip()
    url = (link.get("url") or "").strip()

    if not url:
        # No URL -> cannot derive text reliably
        return text, url

    if not text:
        parsed = urlparse(url)
        # Get last non-empty segment from path
        parts = [p for p in parsed.path.split("/") if p]  # ignore empty segments
        if parts:
            slug = parts[-1]
        else:
            # If the path is empty, derive from hostname; otherwise full URL
            slug = parsed.netloc or url

        # Decode percent-encodings (e.g., %20 -> space)
        slug = unquote(slug)

        # Optional prettification: replace separators with spaces & normalize casing
        pretty = slug.replace("_", " ").replace("-", " ").strip()
        pretty = " ".join(pretty.split())  # collapse multiple spaces
        if pretty:
            text = pretty[0].upper() + pretty[1:].lower()
        else:
            text = slug  # fall back to raw slug if prettification ends up empty

    return text, url


def add_flattened_links(attrs: Dict[str, str], links: List[Dict[str, str]]) -> Dict[str, str]:
    """
    Mutates and returns `attrs` by adding flattened link entries:
      link_1_text, link_1_url, link_2_text, link_2_url, ...

    Skips entries that end up with missing text or url after normalization.
    """
    i = 1
    for link in links:
        text, url = fill_empty_link_text(link)

        # Skip if either key is empty after normalization
        if not text or not url:
            continue

        attrs[f"link_{i}_text"] = text
        attrs[f"link_{i}_url"] = url
        i += 1

    return attrs



        
'''
# This is full function written first, then broke this into a small functions which are added after his function in this notebook.

def extract_hierarchical_content(page_soup, page_url,page_id, DOWNLOAD_IMAGES, HEADERS):

"""
    
    #Extract TOC-guided sections (pre-H2 intro + H2-guided chunks).
    #Each chunk becomes: {page_id}_{counter}.txt + {page_id}_{counter}.metadata.json

"""

    results = []

    # Locate main content area
    body = page_soup.find("main") or page_soup("body") or page_soup
    if not body:
        return results

    section_counter = 0
    used_headings = set()

    # --------
    # Helper: Walk a section
    # --------
    
    def walk_section(element, full_text_parts, full_links, links_set):
        for child in element.descendants:
            if isinstance(child, NavigableString):
                continue
            
            # Paragraphs
            if getattr(child, "name", None) == 'p':
                text, links = extract_paragraph_with_links(child, page_url)
                if text:
                    full_text_parts.append(text)
                for link in links:
                    key = (link['text'], link['url'])
                    if key not in links_set:
                        links_set.add(key)
                        full_links.append(link)
                        
            # Lists
            elif child.name in ['ul', 'ol']:
                for li in child.find_all('li', recursive=False):
                    li_text, li_links = extract_paragraph_with_links(li, page_url)
                    if li_text:

                        full_text_parts.append(f"-{li_text}")
                    for link in li_links:
                        key = (link['text'], link['url'])
                        if key not in links_set:
                            links_set.add(key)
                            full_links.append(link)
            
            # Blockquotes
            elif child.name == 'blockquote':
                
                # Capture <p> inside blockquote individually
                bps = child.find_all("p")
                if bps:
                    for bp in bps:
                        b_text, b_links = extract_paragraph_with_links(bp, page_url)
                        if b_text:
                            full_text_parts.append(f"> {b_text}")
                        for link in b_links:
                            key = (link['text'], link['url'])
                            if key not in links_set:
                                links_set.add(key)
                                full_links.append(link)
                else:
                    # Fallback: blockquote text + direct links
                    b_text = child.get_text(" ", strip=True)
                    if b_text:
                        full_text_parts.append(f"> {b_text}")
                    for a in child.find_all("a", href=True):
                        lt = a.get_text(" ", strip=True)
                        lu = urljoin(page_url, a["href"])
                        key = (lt, lu)
                        if key not in links_set:
                            links_set.add(key)
                            full_links.append({"text": lt, "url": lu})

                
            # Images
            elif child.name == 'img':
                src = child.get("src")
                if src:
                    img_url = urljoin(page_url, src)
                    filename = os.path.basename(urlparse(img_url).path) or f"img_{uuid.uuid4()}.png"

                    if DOWNLOAD_IMAGES:
                        try:
                            resp =  requests.get(img_url, headers=HEADERS, timeout=10)
                            if resp.status_code == 200:
                                with open(os.path.join(IMAGE_DIR, filename), "wb") as f:
                                    f.write(resp.content)
                                
                        except:
                            pass

                    alt = child.get("alt", "")
                    full_text_parts.append(f"[Image: {alt}]")
            
            # Subheadings
            elif child.name in ["h3", 'h4']:
                heading = child.get_text(strip=True)
                if heading:
                    full_text_parts.append(heading)
    
    # ----------------------
    # Extarct H1 (title)
    # ----------------------

    h1 = body.find('h1')
    h1_text = h1.get_text(strip=True) if h1 else None
    first_h2 = body.find('h2')

    processed_ids = set()

    # ----------------------
    # Pre-H2 Section from top to first H2
    # ----------------------
    if first_h2:
        #cursor = h1.next_siblings if h1 else body.children
        pre_nodes = []
        for element in body.contents:
            if element == first_h2:
                break
            if getattr(element, "name", None):
                pre_nodes.append(element)
        
        if pre_nodes:
            wrapper = page_soup.new_tag("div")
            for element in pre_nodes:
                wrapper.append(element)
            
            full_text_parts = []
            full_links = []
            links_set = set()

            walk_section(wrapper, full_text_parts, full_links, links_set)

            #for node in pre_nodes:
            #    walk_section(node, full_text_parts, full_links, links_set)
            
            full_text_parts = list(dict.fromkeys(full_text_parts))
            if full_text_parts:
                section_counter += 1
                base_name = f"{page_id}_{section_counter}"
                full_text = "\n\n".join(full_text_parts)


                # DEBUG: shows how many items and the first snippet
                print(
                    f"[DEBUG] saving chunk {base_name} (pre-H2) items={len(full_text_parts)}; "
                    f"first item={full_text_parts[0][:80] if full_text_parts else 'N/A'}",
                    flush=True
                    )

                metadata = {
                    "page_url" : page_url,
                    "root_heading": h1_text,
                    "level" : 1,
                    "text" : None,
                    "links" : full_links
                }

                save_text_and_metadata(full_text, metadata, base_name)

                results.append({
                        "heading" : h1_text,
                        "level ": 1,
                        "children" : None,
                        "text_file" : f"{base_name}.txt",
                        "metadata_file" : f"{base_name}.metadata.json"
                })

            # Track processed nodes and descendants
            for node in pre_nodes:
                if isinstance(node, Tag):
                    processed_ids.add(id(node))
                    for desc in node.descendants:
                        if isinstance(desc, Tag):
                            processed_ids.add(id(desc))

            # Remove the nodes from original DOM to avoid reprocessing in H2 sections
            for element in pre_nodes:
                try:
                    element.extract()
                except Exception:
                    pass

    # -----------------------------
    # Process H2 Sections
    # -----------------------------
    h2_headers = body.find_all(["h2"]) # H2 root sections

    for h2 in h2_headers:
        h2_text = h2.get_text(strip=True)

        if h2_text in used_headings:
            continue
        used_headings.add(h2_text)

        full_text_parts = [h2_text]
        full_links = []
        links_set = set()
        child_headings = []

        # Section wrapper: from this H2 until next H2
        section_nodes = []
        for element in h2.next_siblings:
            if getattr(element, "name", None) == 'h2':
                break

            # Skip any node already consumed in pre-H2
            skip = False
            if isinstance(element, Tag):
                if id(element) in processed_ids:
                    skip = True
                else:
                    for desc in element.descendants:
                        if isinstance(desc, Tag) and id(desc) in processed_ids:
                            skip=True
                            break
            
            if skip:
                continue

            section_nodes.append(element)
        wrapper = page_soup.new_tag("div")
        for element in section_nodes:
            wrapper.append(element)
        walk_section(wrapper, full_text_parts, full_links, links_set)
        if len(full_text_parts) > 1:
            section_counter += 1
            base_name = f"{page_id}_{section_counter}"
            full_text = "\n\n".join(full_text_parts)

            # DEBUG: shows items count and first text line
            print(
                    f"[DEBUG] saving chunk {base_name} (H2='{h2_text}') items={len(full_text_parts)}; "
                    f"first item={full_text_parts[0][:80] if full_text_parts else 'N/A'}",
                    flush=True
                )
            metadata = {
                    "page_url" : page_url,
                    "page_h1": h1_text,
                    "root_heading": h2_text,
                    "level" : 2,
                    "children" : child_headings if child_headings else None,
                    "links" : full_links
                }
            save_text_and_metadata(full_text, metadata, base_name)
            results.append({
                "heading":h2_text,
                "level" : 2,
                "children" : child_headings if child_headings else None,
                "text" : f"{base_name}.txt",
                "metadata_file": f"{base_name}.metadata.json"
            })
    return results

'''
# ---------------------------------
# Walk a section: paragraphs, lists, images, subheadings
# --------------------------------

def walk_section(el, page_url, DOWNLOAD_IMAGES, HEADERS):
    
    """
    Traverse a section wrapper `el` (BeautifulSoup node) and extract:
      - Text content from paragraphs, list items, blockquotes, and subheadings (h3/h4)
      - Unique hyperlinks found inside those text nodes
      - Image placeholders (with alt text), and optionally download the images

    Supports:
      - Lazy-loaded images via `data-src`
      - Responsive images via `srcset` (first candidate)
      - Deduplication of text parts and links

    Args:
        el (bs4.element.Tag): A wrapper Tag that contains the section's nodes to process.
        page_url (str): Base page URL used to resolve relative links and image sources.
        DOWNLOAD_IMAGES (bool): If True, images are downloaded via `download_image()`.
        HEADERS (dict): HTTP headers used during image download requests.

    Returns:
        tuple:
            - list[str]: Ordered, de-duplicated text parts capturing the section's content.
            - list[dict]: Unique links found, each dict like {"text": "...", "url": "..."}.
    """

    full_text_parts = []  # Holds text fragments to be joined later; preserves content order.
    full_links = []       # Accumulates link dicts from paragraphs, lists, blockquotes.
    links_set = set()     # Used for deduping links by (text, url) pair.
    
    # Iterate over all descendants of the wrapper `el`. We only care about Tag nodes.
    for child in el.descendants:
        if not isinstance(child, Tag):
            # Skip NavigableString / comments; we extract text from Tag contexts only.
            continue
        
        # ---- Paragraphs and list items ----
        if child.name in ('p', 'li'):
            # Extract paragraph text and hyperlinks using a helper.
            text, links = extract_paragraph_with_links(child, page_url)
            # Add a list-style prefix for LI items (so bullets become consistent in output).
            prefix = "- " if child.name == "li" else ""
            if text.strip():
                full_text_parts.append(f"{prefix}{text.strip()}") 

            # Deduplicate links: avoid duplicates across the section. 
            for link in links:
                key = (link['text'], link['url'])
                if key not in links_set:
                    links_set.add(key)
                    full_links.append(link)

        # ---- Lists (UL/OL) container: process direct LI children only ----         
        elif child.name in ['ul', 'ol']:
            # Only process immediate li children to avoid double-processing nested structures.
            for li in child.find_all('li', recursive=False):
                li_text, li_links = extract_paragraph_with_links(li, page_url)
                if li_text.strip():
                    full_text_parts.append(f"- {li_text.strip()}")   
                for link in li_links:
                    key = (link['text'], link['url'])
                    if key not in links_set:
                        links_set.add(key)
                        full_links.append(link)
        
        # ---- Blockquotes ----
        elif child.name == 'blockquote':
            # Capture <p> inside blockquote individually
            bps = child.find_all("p")
            if bps:
                for bp in bps:
                    b_text, b_links = extract_paragraph_with_links(bp, page_url)
                    if b_text.strip():
                        # Use markdown-style quote prefix for readability.
                        full_text_parts.append(f"gt; {b_text}")
                    for link in b_links:
                        key = (link['text'], link['url'])
                        if key not in links_set:
                            links_set.add(key)
                            full_links.append(link)
            else:
                # Fallback: get the whole blockquote text if no <p> children exist.
                b_text = child.get_text(" ", strip=True)
                if b_text:
                    full_text_parts.append(f"> {b_text}")
        # ---- Images (supports src, data-src, srcset via resolve_img_url) ----
        elif child.name == 'img':
            # Resolve the best candidate image URL and a safe filename.
            img_url, filename = resolve_img_url(child, page_url)
            if img_url:
                # Optionally download the image content to local storage.
                if DOWNLOAD_IMAGES:
                    download_image(img_url, filename, HEADERS)

                # Append an image placeholder to text output (alt text helps preserve context).
                alt = child.get("alt", "") # Empty string if alt missing.
                full_text_parts.append(f"[Image: {alt}]")

        # ---- Subheadings within the section (h3/h4) ----  
        elif child.name in ["h3", 'h4']:
            # Capture subheading text to preserve structure and context.
            heading = child.get_text(strip=True)
            if heading:
                full_text_parts.append(heading)
    # Deduplicate text parts while preserving insertion order.
    # This helps avoid repeated entries when markup causes multiple passes over similar nodes.     
    return list(dict.fromkeys(full_text_parts)), full_links

# --------------------------
# Download image helper
# --------------------------
def download_image(img_url, filename, HEADERS):

    """
    Download an image from the given URL and save it locally.

    Args:
        img_url (str): Absolute URL of the image to download.
        filename (str): Filename to save the image as.
        HEADERS (dict): HTTP headers for the request (e.g., User-Agent).

    Behavior:
        - Creates IMAGE_DIR if it doesn't exist.
        - Saves the image in binary mode.
        - Logs a warning if download fails.
    """

    try:
        # Make an HTTP GET request to fetch the image
        resp = requests.get(img_url, headers=HEADERS, timeout=10)
        resp.raise_for_status() # Raise an error for non-200 responses

        # Ensure the image directory exists
        os.makedirs(IMAGE_DIR, exist_ok=True)

        # Save the image content to a file
        with open(os.path.join(IMAGE_DIR, filename), "wb") as f:
            f.write(resp.content)
    except Exception as e:
        # Log a warning if any error occurs during download
        logging.warning(f"[IMG] {img_url} -> {e}")

# --------------------------
# Get siblings that are tags
# --------------------------
def tag_siblings(node):

    """
    Generator that yields sibling elements of a given node,
    filtering out non-Tag objects (e.g., text nodes, comments).

    Args:
        node (bs4.element.Tag): The starting node.

    Returns:
        generator: Yields Tag siblings only.
    """
    # Iterate over next siblings and yield only Tag objects
    return (sib for sib in node.next_siblings if isinstance(sib, Tag))


def extract_pre_h2(soup, body, page_url, page_id, DOWNLOAD_IMAGES, HEADERS, section_counter):

    """
    Extract content that appears before the first <h2> in the page body.
    This is typically the introduction section.

    Args:
        soup (BeautifulSoup): Parsed HTML document.
        body (Tag): Main content container (usually <main> or <body>).
        page_url (str): URL of the page being processed.
        page_id (str): Unique identifier for the page.
        DOWNLOAD_IMAGES (bool): Whether to download images.
        HEADERS (dict): HTTP headers for image download.
        section_counter (int): Counter for naming output files.

    Returns:
        tuple:
            - results (list): Extracted section metadata dictionaries.
            - processed_tags (set): Tags already processed (to avoid duplication later).
            - section_counter (int): Updated section counter.
    """

    results = []
    h2_tags = body.find_all("h2")
    first_h2 = h2_tags[0] if h2_tags else None
    processed_tags = set()

    # If no <h2> exists, nothing to extract here (handled elsewhere)
    if not first_h2:
        return results, processed_tags, section_counter
    
    # Collect all nodes before the first <h2>
    pre_nodes = []
    for el in list(body.contents):
        if el == first_h2:
            break
        pre_nodes.append(el)

    if not pre_nodes:
        return results, processed_tags, section_counter
    
    # Wrap pre_nodes in a temporary <div> for unified processing
    wrapper = soup.new_tag("div")
    for el in pre_nodes:
        wrapper.append(el)

    # Extract text and links from the wrapper
    full_text_parts, full_links = walk_section(wrapper, page_url, DOWNLOAD_IMAGES, HEADERS)

    # Mark these nodes as processed to avoid duplication later
    for n in pre_nodes:
        if isinstance(n, Tag):
            processed_tags.add(n)
            processed_tags.update(n.find_all(True))

    # Save section if it contains meaningful text
    if any(t.strip() for t in full_text_parts):
        section_counter += 1

        # version-1  with no names
        #base_name = f"{page_id}_{section_counter}"

        # version-2 with names but not handled slug collides, use base_name in results
        h1_text = get_main_h1(body, soup)
        #base_name = generate_filename(get_main_h1(body, soup), None, page_id, section_counter)

        # version-3 with handling slug collides, use safe_name in results
        fallback_base = f"{page_id}_{section_counter}"
        h2_text = None
        safe_name = generate_unqiue_filename(h1_text, h2_text, fallback_base)

        full_text = "\n\n".join(full_text_parts)
        metadata = {
            "page_url": page_url,
            "page_h1": h1_text,
            "root_heading": h1_text,
            "level": 1,
        }

        # flatten links 
        #metadata.update(flatten_links_for_metadata(full_links))
        metadata = add_flattened_links(metadata, full_links)

        save_text_and_metadata(full_text, {"metadataAttributes":metadata}, safe_name)# for version 3
        #save_text_and_metadata(full_text, metadata, base_name)# for version1, 2

        results.append({
            "heading": metadata['root_heading'],
            "level": 1,
            "text_file": f"{safe_name}.txt",
            "metadata_file": f"{safe_name}.txt.metadata.json"
        })

    # Remove processed nodes from DOM to simplify later extraction
    for el in pre_nodes:
        try:
            el.extract()
        except:
            pass

    return results, processed_tags, section_counter


def extract_h2_sections(soup, body, page_url, page_id, DOWNLOAD_IMAGES, HEADERS, processed_tags, section_counter):

    """
    Extract content for each <h2> section in the page body.

    Args:
        soup (BeautifulSoup): Parsed HTML document.
        body (Tag): Main content container.
        page_url (str): URL of the page.
        page_id (str): Unique identifier for the page.
        DOWNLOAD_IMAGES (bool): Whether to download images.
        HEADERS (dict): HTTP headers for image download.
        processed_tags (set): Tags already processed (e.g., intro section).
        section_counter (int): Counter for naming output files.

    Returns:
        tuple:
            - results (list): Extracted section metadata dictionaries.
            - section_counter (int): Updated section counter.
    """

    results = []
    used_headings = set()
    h2_tags = body.find_all("h2")

    for h2 in h2_tags:
        heading = h2.get_text(strip=True)
        if heading in used_headings:
            continue # Skip duplicate headings
        used_headings.add(heading)

        # Start section text with the heading itself
        full_text_parts = [heading]
        full_links = []

        # Collect all nodes until the next <h2>
        section_nodes = []
        for el in tag_siblings(h2):
            if el.name == 'h2': # Stop at next <h2>
                break
            # Skip nodes already processed (intro or previous sections)
            if el in processed_tags or any(d in processed_tags for d in el.find_all(True)):
                continue
            section_nodes.append(el)

        # Wrap section nodes for unified processing
        wrapper = soup.new_tag("div")
        for el in section_nodes:
            wrapper.append(el)

        # Extract text and links from this section
        parts, links = walk_section(wrapper, page_url, DOWNLOAD_IMAGES, HEADERS)
        full_text_parts.extend(parts)
        full_links.extend(links)

        # Save section if it has meaningful content
        if any(t.strip() for t in full_text_parts[1:]) or len(full_text_parts) > 1:
            section_counter += 1

            # version-1  with no names
            #base_name = f"{page_id}_{section_counter}"

            # version-2 with names but not handled slug collides, use base_name in results
            h1_text = get_main_h1(body, soup)
            #base_name = generate_filename(get_main_h1(body, soup), heading, page_id, section_counter)

            # version-3 with handling slug collides, use safe_name in results
            h2_text = h2.get_text(strip=True) # Current H2 heading

            fallback_base = f"{page_id}_{section_counter}"
            safe_name = generate_unqiue_filename(h1_text, h2_text, fallback_base)


            full_text = "\n\n".join(full_text_parts)
            metadata = {
                "page_url": page_url,
                "page_h1": h1_text,
                "root_heading": heading,
                "level": 2,
            }

            # flatten links
            #metadata.update(flatten_links_for_metadata(full_links))
            metadata = add_flattened_links(metadata, full_links)

            #save_text_and_metadata(full_text, metadata, base_name)# for version 1,2
            save_text_and_metadata(full_text, {"metadataAttributes":metadata}, safe_name)# for version 3

            results.append({
                "heading": heading,
                "level": 2,
                "text_file": f"{safe_name}.txt",
                "metadata_file": f"{safe_name}.txt.metadata.json"
            })

    return results, section_counter


def extract_no_h2_section(soup, body, page_url, page_id, DOWNLOAD_IMAGES, HEADERS, section_counter):
    
    """
    Extract content from a page that has NO <h2> headings.
    In this case, we treat everything after <h1> as a single section.

    Args:
        soup (BeautifulSoup): Parsed HTML document.
        body (Tag): Main content container (usually <main> or <body>).
        page_url (str): URL of the page being processed.
        page_id (str): Unique identifier for the page.
        DOWNLOAD_IMAGES (bool): Whether to download images found in the section.
        HEADERS (dict): HTTP headers for image download requests.
        section_counter (int): Counter for naming output files.

    Returns:
        tuple:
            - results (list): Extracted section metadata dictionaries.
            - section_counter (int): Updated section counter.
    """

    results = []

    # Create a wrapper <div> to hold all content after <h1>
    wrapper = soup.new_tag("div")

    # Flag to start collecting nodes after encountering <h1>
    started = False
    for el in body.children:
        if isinstance(el, Tag):
            if el.name == 'h1':
                started = True
                continue
            if started:
                wrapper.append(el)

    # Extract text and links from the collected nodes
    full_text_parts, full_links = walk_section(wrapper, page_url, DOWNLOAD_IMAGES, HEADERS)

    # If there is meaningful text, save this section
    if any(t.strip() for t in full_text_parts):
        section_counter += 1

        # version-1  with no names
        #base_name = f"{page_id}_{section_counter}"

        # version-2 with names but not handled slug collides, use base_name in results
        h1_text = get_main_h1(body, soup)
        #base_name = generate_filename(h1_text, None, page_id, section_counter)

        # version-3 with handling slug collides, use safe_name in results
        h2_text = None

        fallback_base = f"{page_id}_{section_counter}"
        safe_name = generate_unqiue_filename(h1_text, h2_text, fallback_base)

        full_text = "\n\n".join(full_text_parts)

        # Build metadata for this section
        metadata = {
            "page_url": page_url,
            "page_h1": h1_text,
            "root_heading": h1_text,
            "level": 1,
        }
        metadata = add_flattened_links(metadata, full_links)

        # Save text and metadata to files
        #save_text_and_metadata(full_text, metadata, base_name)# for version 1,2
        save_text_and_metadata(full_text, {"metadataAttributes":metadata}, safe_name)# for version 3
        
        # Append section info to results
        results.append({
            "heading": metadata['root_heading'],
            "level": 1,
            "text_file": f"{safe_name}.txt",
            "metadata_file": f"{safe_name}.txt.metadata.json"
        })

    return results, section_counter


def extract_hierarchical_content(soup, page_url, page_id, DOWNLOAD_IMAGES, HEADERS):
    """
    Extracts hierarchical content from a page using BeautifulSoup.
    Handles three scenarios:
      1. Pages with <h2> sections (normal case)
      2. Intro content before first <h2>
      3. Pages with NO <h2> (special case: treat everything after <h1> as one section)
    
    Args:
        soup (BeautifulSoup): Parsed HTML document.
        page_url (str): URL of the page being processed.
        page_id (str): Unique identifier for the page.
        DOWNLOAD_IMAGES (bool): Whether to download images found in the content.
        HEADERS (dict): HTTP headers for image download requests.

    Returns:
        list: A list of extracted section metadata dictionaries.
    """
    results = []

    # Find the main content area: prefer <main>, fallback to <body>, then entire soup
    body = soup.find("main") or soup.body or soup
    if not body:
        return results  # No content found, return empty list

    section_counter = 0  # Tracks section numbering for file naming

    # Special Case: If NO <h2> exists, treat everything after <h1> as one section
    if not body.find_all("h2"):
        no_h2_results, section_counter = extract_no_h2_section(
            soup, body, page_url, page_id, DOWNLOAD_IMAGES, HEADERS, section_counter
        )
        results.extend(no_h2_results)
        return results  # Early return because no further hierarchical sections exist

    # Normal Case: Extract content before first <h2> (intro section)
    pre_results, processed_tags, section_counter = extract_pre_h2(
        soup, body, page_url, page_id, DOWNLOAD_IMAGES, HEADERS, section_counter
    )
    results.extend(pre_results)

    # Extract all <h2> sections and their content
    h2_results, section_counter = extract_h2_sections(
        soup, body, page_url, page_id, DOWNLOAD_IMAGES, HEADERS, processed_tags, section_counter
    )
    results.extend(h2_results)

    return results