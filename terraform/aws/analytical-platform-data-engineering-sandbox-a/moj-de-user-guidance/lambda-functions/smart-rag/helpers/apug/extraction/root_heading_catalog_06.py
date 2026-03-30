"""

# Knowledge Base Catalog Builder

Build a structured Knowledge Base catalog from Analytical Platform metadata 
files containing `root_heading` and `page_h1` attributes.

This utility scans a directory of `.txt.metadata.json` files, extracts relevant 
information, validates it, and produces a single consolidated JSON catalog 
(`kb_catalog.json`) suitable for use in retrieval pipelines, routing logic, 
and LLM-based systems.

---

##  What This Script Does

### 1. Scans metadata files
Recursively scans the directory provided via `--metadata_dir` for files ending in:

### 2. Extracts metadata fields
From each file, it reads:
- `root_heading`
- `page_h1`

### 3. Validates metadata
- Counts missing or empty headings
- Tracks total files processed
- Reports extraction statistics

### 4. Builds structured catalog
Creates a KB catalog containing:

- `headings_by_page` → maps page_h1 → list of root_headings  
- `all_headings` → full list of unique root_heading values  
- `page_h1_list` → full list of unique page_h1 values  
- `metadata` → extraction stats + semantic samples  

### 5. Groups headings semantically (optional)
Uses keyword-based heuristics to group headings into categories such as:
- getting_started  
- troubleshooting  
- access_permissions  
- usage  
- policies  
- pipelines  
- github  
- visualization  
…etc.

These groups are stored inside `metadata.semantic_groups` for inspection or 
prompt-building but **do not restrict the KB catalog structure**.

---

## Output

Produces a single JSON file (default: `kb_catalog.json`):

```json
{
  "headings_by_page": { ... },
  "all_headings": [ ... ],
  "page_h1_list": [ ... ],
  "metadata": {
      "total_headings": 349,
      "total_pages": 49,
      "semantic_groups": { ... },
      "extraction_stats": { ... }
  }
}

Usage:
    python root_heading_catalog.py --metadata_dir <path_to_metadata_files> --output <output_catalog.json>

"""

# Standard Libraries
import json
import argparse
import unicodedata
from collections import defaultdict
from pathlib import Path
from typing import Dict, Set, Tuple
from dataclasses import dataclass, asdict

# Data class for catalog structure
@dataclass
class KBCatalog:
    """Knowledge Base catalog structure"""
    headings_by_page: Dict[str, list]
    all_headings: list
    page_h1_list: list
    metadata: dict
    
    def to_dict(self) -> dict:
        return asdict(self)

# Catalog builder class
class CatalogBuilder:
    """Build KB catalog from metadata files with validation and semantic grouping"""


# Canonical tool synonyms for query detection
    TOOL_SYNONYMS = {
        "Airflow": ["airflow", "dag", "workflow", "orchestration", "pipeline"],
        "Amazon Athena": ["athena", "amazon athena", "sql", "sql query"],
        "Control Panel": ["control panel", "admin panel", "administration"],
        "Data Uploader": ["data uploader", "uploader", "upload data", "ingest data"],
        "JupyterLab": ["jupyterlab", "jupyter", "jupyter lab", "python notebooks", "notebook"],
        "RStudio": ["rstudio", "r studio", "r environment"],
        "QuickSight": ["quicksight", "quick sight", "dashboard", "dashboards", "bi", "bi tool"],
        "GitHub": ["github", "git", "repository", "version control", "branch"],
        "Create a Derived Table (dbt)": ["dbt", "derived table", "create a derived table"],
        "MLFlow": ["mlflow", "ml flow", "model tracking", "experiment tracking"],
        "Bedrock": ["amazon bedrock", "bedrock", "generative ai", "llm"],
        "Visual Studio Code": ["visual studio code", "vscode", "vs code"],
    }

    # Rules to map arbitrary page_h1 strings to a canonical tool key
    # Order matters: first match wins.
    CANONICAL_RULES = [
        ("Airflow", ["airflow"]),
        ("Amazon Athena", ["athena"]),
        ("Control Panel", ["control panel"]),
        ("Data Uploader", ["data uploader"]),
        ("JupyterLab", ["jupyterlab", "jupyter lab", "jupyter"]),
        ("RStudio", ["rstudio", "r studio"]),
        ("QuickSight", ["quicksight", "quick sight"]),
        ("GitHub", ["github"]),
        ("Create a Derived Table (dbt)", ["create a derived table", "derived table", "dbt"]),
        ("MLFlow", ["mlflow", "ml flow"]),
        ("Bedrock", ["bedrock"]),
        ("Visual Studio Code", ["visual studio code", "vscode", "vs code"]),
    ]

    
    # Predefined semantic groups with keywords
    SEMANTIC_GROUPS = {
        "getting_started": ["install", "setup", "getting started", "prerequisites", "before you begin"],
        "troubleshooting": ["troubleshoot", "error", "failed", "not working", "issues", "monitoring"],
        "access_permissions": ["access", "permissions", "login", "authentication", "connect"],
        "usage": ["how to", "usage", "working with", "run", "execute"],
        "data_management": ["data management", "delete", "remove", "drop table", "governance"],
        "policies": ["policy", "governance", "acceptable use", "security", "responsibility"],
        "github": ["github", "git", "branch", "repository", "version control"],
        "database": ["sql", "database", "tables", "schema", "dbt"],
        "deployment": ["deploy", "publish", "release", "dev", "prod"],
        "pipelines": ["pipeline", "workflow", "dag", "airflow", "orchestration"],
        "tools": ["jupyter", "rstudio", "vscode", "ide", "editor"],
        "visualization": ["dashboard", "visualization", "quicksight", "charts"],
    }
    
    # Initialize with metadata directory
    def __init__(self, metadata_dir: str):
        self.metadata_dir = Path(metadata_dir)
        self.headings_by_page = defaultdict(set)
        self.all_headings = set()
        self.page_h1_list = set()
        self.stats = {
            "files_processed": 0,
            "files_without_heading": 0,
            "files_with_errors": 0,
            "total_files": 0
        }
    
    # Extract root headings and page H1 from metadata files
    def extract_from_metadata(self) -> Tuple[Dict, Set]:
        """Extract root_headings and page_h1 from all metadata files"""
        
        json_files = list(self.metadata_dir.glob("**/*.txt.metadata.json"))
        self.stats["total_files"] = len(json_files)
        
        if not json_files:
            raise FileNotFoundError(f"No metadata files found in {self.metadata_dir}")
        
        print(f"📂 Found {len(json_files)} metadata files\n")
        
        for json_file in json_files:
            self._process_file(json_file)
        
        self._print_stats()
        return self.headings_by_page, self.all_headings
    
    # Process a single metadata file
    def _process_file(self, json_file: Path) -> None:
        """Process a single metadata file"""
        try:
            with open(json_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            metadata = data.get("metadataAttributes", {})
            page_h1 = self._normalize(metadata.get("page_h1", ""))
            root_heading = self._normalize(metadata.get("root_heading", ""))
            
            if not root_heading:
                self.stats["files_without_heading"] += 1
                return
            
            # Track page_h1 and root_heading
            self.page_h1_list.add(page_h1)
            self.all_headings.add(root_heading)
            self.headings_by_page[page_h1].add(root_heading)
            
            self.stats["files_processed"] += 1
            
        except Exception as e:
            self.stats["files_with_errors"] += 1
            print(f" Error reading {json_file.name}: {e}")
    
    # Normalize strings
    def _normalize(self, value: str) -> str:
        """Normalize string: NFKC unicode + strip + handle empty"""
        if not value or not value.strip():
            return "Unknown"
        return unicodedata.normalize("NFKC", value.strip())
    
    # Print extraction statistics
    def _print_stats(self) -> None:
        """Print extraction statistics"""
        print("=" * 80)
        print("EXTRACTION STATISTICS")
        print("=" * 80)
        print(f"✅ Files with root_heading: {self.stats['files_processed']}")
        print(f"⚠️  Files without root_heading: {self.stats['files_without_heading']}")
        if self.stats['files_with_errors'] > 0:
            print(f" Files with errors: {self.stats['files_with_errors']}")
        print(f"\n Total unique root_headings: {len(self.all_headings)}")
        print(f" Total unique page_h1: {len(self.page_h1_list)}\n")
    

    def _to_canonical_tool(self, page_h1: str) -> str | None:
        """
        Resolve a page_h1 into a canonical tool name using CANONICAL_RULES.
        Returns the canonical tool name or None if no rule matches.
        """
        name = page_h1.lower()
        for canonical, triggers in self.CANONICAL_RULES:
            if any(t in name for t in triggers):
                return canonical
        return None

    def build_tool_mapping(self) -> dict:
        """
        Build a mapping:
        {
          <Canonical Tool>: {
            "match_keywords": [...],
            "page_h1_candidates": [exact titles from catalog]
          },
          ...
        }
        Only includes tools that actually exist in the current catalog.
        """
        mapping = {}
        # Prefer deterministic ordering
        for h1 in sorted(self.page_h1_list):
            canonical = self._to_canonical_tool(h1)
            if not canonical:
                continue
            if canonical not in mapping:
                # fall back to at least the canonical name if synonyms missing
                mapping[canonical] = {
                    "match_keywords": self.TOOL_SYNONYMS.get(canonical, [canonical.lower()]),
                    "page_h1_candidates": []
                }
            if h1 not in mapping[canonical]["page_h1_candidates"]:
                mapping[canonical]["page_h1_candidates"].append(h1)
        return mapping

    # Assign headings to semantic groups
    def assign_semantic_groups(self, max_per_group: int = 8) -> Dict[str, list]:
        """Assign headings to semantic groups with scoring"""
        
        scored = {g: [] for g in self.SEMANTIC_GROUPS}
        
        for heading in self.all_headings:
            h_lower = heading.lower()
            for group, keywords in self.SEMANTIC_GROUPS.items():
                hits = sum(1 for kw in keywords if kw in h_lower)
                if hits > 0:
                    scored[group].append((heading, hits))
        
        # Rank by hits, then alphabetically
        result = {}
        for group, items in scored.items():
            items.sort(key=lambda x: (-x[1], x[0]))
            
            # Deduplicate by lowercase form
            seen = set()
            compact = []
            for name, _ in items:
                if name.lower() not in seen:
                    seen.add(name.lower())
                    compact.append(name)
                if len(compact) >= max_per_group:
                    break
            
            if compact:
                result[group] = compact
        
        return result
    
    # Build the complete catalog
    def build_catalog(self) -> KBCatalog:
        """Build complete catalog"""
        
        headings_by_page, all_headings = self.extract_from_metadata()
        
        semantic_groups = self.assign_semantic_groups()
        tool_mapping = self.build_tool_mapping()
        
        catalog = KBCatalog(
            headings_by_page={k: sorted(v) for k, v in sorted(headings_by_page.items())},
            all_headings=sorted(all_headings),
            page_h1_list=sorted(self.page_h1_list),
            metadata={
                "total_headings": len(all_headings),
                "total_pages": len(headings_by_page),
                "semantic_groups": semantic_groups,
                "tool_mapping": tool_mapping,
                "extraction_stats": self.stats
            }
        )
        
        return catalog
    
    # Save catalog to JSON file
    def save_catalog(self, catalog: KBCatalog, output_path: str = "kb_catalog.json") -> Path:
        """Save catalog to JSON"""
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(catalog.to_dict(), f, ensure_ascii=False, indent=2)
        
        file_size = Path(output_path).stat().st_size / 1024  # KB
        print(f"✅ Catalog saved: {output_path} ({file_size:.1f} KB)")
        return Path(output_path)

# Main function to parse arguments and run the builder
def main():
    parser = argparse.ArgumentParser(
        description="Build KB catalog from metadata files"
    )
    
    parser.add_argument(
        "--metadata_dir",
        required=True,
        help="Path to directory containing metadata files (.txt.metadata.json)"
    )

    parser.add_argument(
        "--output",
        default="kb_catalog.json",
        help="Output catalog path"
    )

    parser.add_argument(
        "--max_samples",
        type=int,
        default=8,
        help="Max samples per semantic group"
    )

    
    args = parser.parse_args()
    
    # Build catalog
    builder = CatalogBuilder(args.metadata_dir)
    catalog = builder.build_catalog()
    builder.save_catalog(catalog, args.output)
    
    # Print summary
    print("\n" + "=" * 80)
    print("CATALOG SUMMARY")
    print("=" * 80)
    print(f"Page H1 categories: {len(catalog.page_h1_list)}")
    print(f"Root headings: {len(catalog.all_headings)}")
    print(f"Semantic groups: {len(catalog.metadata['semantic_groups'])}")
    print(f"\nOutput: {args.output}")

# Run main if executed as script
if __name__ == "__main__":
    main()
