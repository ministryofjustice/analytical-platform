### AI-Powered Data Engineering Support Assistant
Status: Stage 1 Complete (APUG Documentation) | Satge 2 to be Started
Last Updated: January 5, 2025
Owner: 

---------------------
#### Overview

The AI-Powered Data Engineering Support Assistant automates routine tier-1 support tasks, PR validation, and knowledge retrieval for data engineers using Generative AI. It leverages AWS Bedrock, Airflow, and Slack to provide intelligent responses, validate PRs, summarize documentation, and route issues to the right support members.

Key Goals

- Reduce manual workload for data engineering teams
- Improve operational efficiency across the Analytical Platform
- Enable context-aware support through LLM-powered chat integrated with Slack

Current Scope

- Stage 1 (Complete): Extract and index Analytical Platform User Guidance (APUG) documentation
- Stage 2 (In Progress): Integrate Slack conversations for multi-source knowledge base

---

### Features

**Data Extraction**
- **Hierarchical extraction:** Pre‑H2 intro (level 1) + H2‑guided sections (level 2), capturing nested content with a recursive walker.
- Rich metadata: Each chunk includes heading, level, page URL, links, images, and timestamps. Each section saved as .txt + .metadata.json.
- Image handling: Optional download with lazy‑load support (src, data-src, srcset) and debug prints.
- Deduplication: SHA-256 hash-based duplicate removal (text + metadata pairs)
- Crawl safety: Respects a configurable delay and avoids revisiting URLs.
- Ready for RAG: Clean chunk granularity, metadata, and consistent paths for indexing

**Vector Search & Chat**

- Semantic search: Query vector database with metadata filters
- Source citations: Every answer includes page URLs and section references
- Query evaluation: Side-by-side comparison of retrieval strategies
- Conversation memory: Multi-turn chat with context retention

**Quality Assurance**

- Metadata validation: Automated schema checks for all extracted chunks
- Integration tests: End-to-end pipeline validation
- Prompt variations: A/B testing for query rephrasing strategies

Repository Structure
```
DATA_EXTRACTION/
├── .vscode/
│   └── settings.json
├── data/
│   ├── images/                          # Downloaded images (gitignored)
│   └── text_chunks/                     # Extracted chunks + metadata (gitignored)
├── helpers/
│   ├── apug/
│   │   ├── __init__.py
│   │   ├── extraction.py                # Web scraping & content parsing
│   │   ├── metadata_validator.py        # Schema validation for chunks
│   │   ├── query_evaluator.py           # Query comparison & evaluation
│   │   └── vector_search.py             # Vector DB queries & chat interface
│   └── __init__.py
├── notebooks/
│   ├── 01_web_scrape_apug_site.ipynb    # Initial data extraction
│   ├── 02_remove_duplicate_chunks.ipynb # Deduplication pipeline
│   ├── 03_validate_metadata.ipynb       # Metadata quality checks
│   ├── 04_upload_chunks_to_s3.ipynb     # Cloud storage upload
│   └── 05_demo_apug_kb.ipynb            # Interactive Q&A demo
├── src/
│   └── (future: production scripts)
├── tests/
│   ├── test_edge_cases.ipynb
│   ├── test_integration_extraction.py
│   ├── test_metadata_filters.ipynb
│   ├── test_prompt_variations.ipynb
│   ├── test_retrieval_quality.ipynb
│   └── test_run_validation.py
├── .env                                 # API keys & config (gitignored)
├── .gitignore
├── config.py
└── README.md
```
#### Installation

##### Prerequisites
- Python 3.9+
- AWS account (for Bedrock Knowledge Base and S3 storage)
- Amazon OpenSearch Serverless (for vector search, Used for vector indexing and semantic search)

# Clone
- git clone https://github.com/your-org/website-chatbot-rag.git
- cd website-chatbot-rag

# Python env (recommended)
- python3 -m venv .venv
- source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Dependencies
- pip install -r requirements.txt

### Usage

1. Extract Website Data
    - Run the extraction notebook:
    jupyter notebook notebooks/01_web_scrape_apug_site.ipynb

    What it does:

    - Crawls target website recursively
    - Extracts hierarchical content (H2/H3 sections)
    - Saves chunks as .txt + .metadata.json pairs
    - Downloads images to images

2. Remove Duplicates

    - from helpers.apug.extraction import remove_duplicates

    deleted = remove_duplicates("data/text_chunks")
    print(f"Removed {len(deleted)} duplicate files")

3. Validate Metadata
    from helpers.apug.metadata_validator import validate_metadata_file
    import glob

    for file in glob.glob("data/text_chunks/**/*.metadata.json", recursive=True):
        issues = validate_metadata_file(file)
        if issues:
            print(f"{file}: {issues}")

4. Upload to S3
    import boto3
    from helpers.apug.extraction import upload_folder_to_s3

    s3 = boto3.client("s3", region_name=AWS_REGION)
    upload_folder_to_s3("data/text_chunks", BUCKET_NAME)

5. Query Knowledge Base
    from helpers.apug.vector_search import ask, display_citations_table

    response = ask(
        "How do I request table deletion in Data Uploader?",
        metadata_filters={'page_h1': {'equals': "Data Uploader - Analytical Platform User Guidance"}}
    )
    display_citations_table(response)

6. Evaluate Retrieval Quality
    from helpers.apug.query_evaluator import demo_comparison

    demo_comparison(
        question="On the topic of the data uploader...",
        metadata_filters={'page_h1': {'equals': "Data Uploader - ..."}},
        show_mode="detailed"
    )

####  Testing

# Run unit tests
pytest tests/test_integration_extraction.py
pytest tests/test_run_validation.py

# Run quality tests (notebooks)
jupyter notebook tests/test_retrieval_quality.ipynb
jupyter notebook tests/test_prompt_variations.ipynb

####  Key Helper Functions
extraction.py
    remove_duplicates(folder_path)  # SHA-256 deduplication
    upload_folder_to_s3(local_path, bucket)  # Batch S3 upload

vector_search.py
    ask(question, metadata_filters)  # Single query
    chat(messages, metadata_filters)  # Conversation
    display_citations_table(response)  # Show sources
    export_qa_to_markdown(qa_pairs, output_file)  # Save results

query_evaluator.py
    demo_comparison(question, filters, show_mode)  # Compare strategies

helpers/apug/metadata_validator.py
    validate_metadata_file(file_path)  # Schema validation

#### Example Query

question = """
On the topic of the data uploader: Is there a process to request 
removal of an existing table? I have 2 tables with ingested data 
in Athena, but they're now obsolete after design review. 
How can I get them deleted? The data is replaceable.
"""

response = ask(question, metadata_filters={
    'page_h1': {'equals': "Data Uploader - Analytical Platform User Guidance"}
})

print(response['answer'])
display_citations_table(response)

Output:

To request table deletion, submit a support ticket via the self-service portal...

Sources:

Data Uploader Guide > Table Management (Section 3.2)
https://docs.example.com/data-uploader#deletion-process

#### Roadmap
 Add Slack data extraction pipeline
 Implement multi-source search (APUG + Slack)
 Add real-time crawl scheduling
 Build REST API for production deployment
 Add LLM response caching

#### Contact
For questions or support, contact: [your-email@example.com]
