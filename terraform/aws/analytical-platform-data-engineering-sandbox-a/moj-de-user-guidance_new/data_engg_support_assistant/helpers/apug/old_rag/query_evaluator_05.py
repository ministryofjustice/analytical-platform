import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from typing import Dict, Optional
from IPython.display import display, Markdown
load_dotenv()

# Add project root to Python path
sys.path.append(os.path.abspath(os.path.join(os.getcwd(), "..")))
from helpers.apug.old_rag.vector_search_05 import chat 

def demo_comparison(
        question: str,
        metadata_filters: Optional[Dict] = None,
        show_mode: str = "compact"
):
    """
    Compare answers with and without metadata filters.

    Args: 
    question: The question to ask
    metadata_filters: Dict of filters to apply (None = no filters)
    show_mode: Display format
        - "compact" (default): Answers + quick stats
        - "detailed": + full sources
        - "side-by-side": Table comparison

    """

    # Map show_mode to internal display options
    _display_config = {
        'compact': {
            'show_answers': True,
            'show_sources': False,
            'show_stats': True,
            'show_comparison': True,
            'format': 'standard'
        },
        'detailed': {
            'show_answers': True,
            'show_sources': True,
            'show_stats': True,
            'show_comparison': True,
            'format': 'standard'
        },
        'side-by-side': {
            'show_answers': True,
            'show_sources': True,
            'show_stats': True,
            'show_comparison': False,
            'format': 'table'
        }
    }
    config = _display_config.get(show_mode, _display_config['compact'])

    # Header with improved styling
    display(Markdown("---"))
    display(Markdown(f"###  Query Comparison Demo"))
    display(Markdown(f"#### Question:\n> {question}\n"))

    if metadata_filters:
        display(Markdown(f"###  Active Filters:"))
        display(Markdown(f"```python\n{metadata_filters}\n```\n"))
    
    # Execute queries with visual feedback
    display(Markdown("---"))
    display(Markdown(" *Executing queries...*"))
    
    answer_filtered, citations_filtered = chat(question, metadata_filters=metadata_filters)
    answer_all, citations_all = chat(question, metadata_filters=None)
    
    display(Markdown(" *Queries complete!*\n"))

    # Render based on config
    _render_results(
        question, answer_filtered, citations_filtered, answer_all, citations_all, metadata_filters, config
    )
    
    return {
        'filtered': (answer_filtered, citations_filtered),
        'unfiltered': (answer_all, citations_all)
    }


def _render_results(question, ans_f, cit_f, ans_a, cit_a, filters, config):
    """ 
    Private: handles all rendering logic
    """
    if config['format'] == 'table':
        _render_side_by_side(ans_f, cit_f, ans_a, cit_a, filters, config)
    else:
        _render_standard(ans_f, cit_f, ans_a, cit_a, filters, config)


def _render_standard(ans_f, cit_f, ans_a, cit_a, filters, config):
    """ 
    Standard vertical layout - single comparison at top (Option 3)
    """
    # With Filter section
    display(Markdown("---"))
    display(Markdown("## Answer WITH Filters"))
    
    if config['show_answers']:
        display(Markdown(f"> {ans_f}\n"))
    
    if config['show_sources'] and cit_f:
        display(Markdown("#### Sources:"))
        _display_sources(cit_f)

    # Without Filters Section
    display(Markdown("\n---"))
    display(Markdown("## Answer WITHOUT Filters"))
    
    if config['show_answers']:
        display(Markdown(f"> {ans_a}\n"))
    
    if config['show_sources'] and cit_a:
        display(Markdown("#### Sources:"))
        _display_sources(cit_a)
    
    # Single unified comparison at the top
    if config['show_stats'] or config['show_comparison']:
        display(Markdown("---"))
        display(Markdown("## Comparison Summary"))
        
        source_diff = len(cit_a) - len(cit_f)
        word_diff = len(ans_a.split()) - len(ans_f.split())
        char_diff = len(ans_a) - len(ans_f)
        
        # Compact table with difference column
        display(Markdown(f"""
| Metric | With Filters | Without Filters | Impact |
|--------|:---------------:|:------------------:|:--------:|
| **Sources** | {len(cit_f)} | {len(cit_a)} | {source_diff:+d} |
| **Words** | {len(ans_f.split())} | {len(ans_a.split())} | {word_diff:+d} |
| **Characters** | {len(ans_f)} | {len(ans_a)} | {char_diff:+d} |
"""))
        
        # Optional: Add single insight
        if filters and abs(source_diff) >= 1:
            if source_diff > 0:
                display(Markdown(f"\n *Filters narrowed results by {abs(source_diff)} source(s) - more targeted information*\n"))
            elif source_diff < 0:
                display(Markdown(f"\n *Filters may be too restrictive - excluding {abs(source_diff)} relevant source(s)*\n"))
        elif filters and source_diff == 0:
            display(Markdown(f"\n *Filters maintained same source count - well-calibrated filter criteria*\n"))
    
    
def _render_side_by_side(ans_f, cit_f, ans_a, cit_a, filters, config):
    """ 
    Table-based side-by-side comparison with enhanced visuals
    """

    display(Markdown("---"))
    display(Markdown("###  Side-by-Side Comparison"))

    # Enhanced stats table
    source_diff = len(cit_a) - len(cit_f)
    length_diff = len(ans_a) - len(ans_f)
    word_diff = len(ans_a.split()) - len(ans_f.split())
    
    # Visual indicators
    source_indicator = "🔴" if source_diff > 0 else "🟢" if source_diff < 0 else "⚪"
    
    display(Markdown(f""" 
#### Metrics Overview

| Metric | With Filters | Without Filters | Δ Difference |
|--------|:---------------:|:------------------:|:------------:|
| **Sources Used** | {len(cit_f)} | {len(cit_a)} | {source_diff:+d} {source_indicator} |
| **Answer Length** | {len(ans_f)} chars | {len(ans_a)} chars | {length_diff:+d} |
| **Word Count** | {len(ans_f.split())} words | {len(ans_a.split())} words | {word_diff:+d} |
"""))
    
    # Single insight
    if filters and abs(source_diff) >= 1:
        display(Markdown("### Key Insight"))
        if source_diff > 0:
            display(Markdown(f" Filters reduced results from **{len(cit_a)} → {len(cit_f)} sources** ({abs(source_diff)} filtered out)\n"))
        elif source_diff < 0:
            display(Markdown(f" Filters may be too restrictive - found **{len(cit_f)} sources** vs. {len(cit_a)} without filters\n"))
    
    if config['show_answers']:
        display(Markdown("\n---"))
        
        # Two-column layout simulation
        display(Markdown("### Answers"))
        
        display(Markdown("#### With Filters"))
        display(Markdown(f"> {ans_f}\n"))
        
        if config['show_sources'] and cit_f:
            display(Markdown("** Sources:**"))
            _display_sources(cit_f)

        display(Markdown("\n---"))
        
        display(Markdown("#### Without Filters"))
        display(Markdown(f"> {ans_a}\n"))
        
        if config['show_sources'] and cit_a:
            display(Markdown("** Sources:**"))
            _display_sources(cit_a)


def _display_sources(citations):
    """ 
    Display sources from citations with improved formatting
    """
    sources = []
    for citation in citations:
        retrieved_refs = citation.get('retrievedReferences', [])
        for ref in retrieved_refs:
            metadata = ref.get("metadata", {})
            page_title = metadata.get('page_h1', "Unknown Document")
            page_url = metadata.get('page_url', '')
            section = metadata.get('root_heading', '')

            if section and section != page_title:
                source_text = f"{page_title} → {section}"
            else:
                source_text = page_title

            if page_url:
                source_link = f" [{source_text}]({page_url})"
            else:
                source_link = f" {source_text}"
            
            sources.append(source_link)

    # Display unique sources with better numbering
    unique_sources = list(dict.fromkeys(sources))
    
    if not unique_sources:
        display(Markdown("*No sources available*"))
        return
    
    for idx, source in enumerate(unique_sources, 1):
        display(Markdown(f"{idx}. {source}"))
