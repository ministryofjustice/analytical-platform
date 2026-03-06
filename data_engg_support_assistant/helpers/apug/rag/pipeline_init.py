"""
RAG Pipeline Initialization Module
===================================

PURPOSE:
    Centralized initialization of the SmartRAG pipeline.
    Loads knowledge base catalog and initializes all pipeline components.
    
USED BY:
    - lambda_handler.py (AWS Lambda)
    - app.py (Flask development server)
    
EXPORTS:
    - ask_smart_pipeline: Initialized AskSmart instance
    - kb_catalog: Loaded knowledge base catalog
    
DESIGN:
    - Initialize once at module import (singleton pattern)
    - Reused across Lambda container warm starts
    - Fails fast if initialization errors occur

pipeline_init.py haves the following responsibilities:
Loads kb_catalog
Initializes all RAG components
Creates singleton ask_smart_pipeline instance
Exports: ask_smart_pipeline, kb_catalog
"""
# pipeline_init.py# pipeline_init.py
import os
import json
import time
import traceback
from pathlib import Path
from threading import Lock
from typing import Tuple, Optional

# Import configuration
from config import MODEL_ID, REGION, KB_ID, MAX_CONTEXT_TOKENS, CATALOG_PATH

# Import RAG components
from helpers.apug.rag.query_analyser_07_01 import QueryAnalyser
from helpers.apug.rag.retrieval_planner_07_02 import RetrievalPlanner
from helpers.apug.rag.filter_generator_07_03 import FilterGenerator
from helpers.apug.rag.ask_smart_07_04 import AskSmart


# ==================== CONFIGURATION ====================

# Retry configuration
RETRY_AFTER_SECONDS = 300  # Wait 5 minutes before retrying failed initialization
MAX_INIT_FAILURES = 5      # After 5 failures, require manual intervention


# ==================== MODULE-LEVEL STATE ====================

# Pipeline state (protected by lock)
_pipeline: Optional[AskSmart] = None
_catalog: dict = {}
_init_lock = Lock()
_last_init_attempt: float = 0
_init_failures: int = 0


# ==================== KNOWLEDGE BASE CATALOG ====================

def load_kb_catalog() -> dict:
    """
    Load knowledge base catalog from JSON file.
    
    Returns:
        dict: Knowledge base catalog mapping
    
    Raises:
        FileNotFoundError: If kb_catalog.json not found
        json.JSONDecodeError: If JSON is malformed
    """
    try:
        with open(CATALOG_PATH, "r") as f:  # ✅ Use config path
            catalog = json.load(f)
        print(f"[PIPELINE_INIT] Loaded kb_catalog with {len(catalog)} entries")
        return catalog
    except FileNotFoundError:
        print(f"[PIPELINE_INIT ERROR] kb_catalog.json not found at {CATALOG_PATH}")
        print(f"[PIPELINE_INIT ERROR] Current directory: {os.getcwd()}")
        raise
    except json.JSONDecodeError as e:
        print(f"[PIPELINE_INIT ERROR] Invalid JSON in kb_catalog.json: {e}")
        raise


# ==================== PIPELINE INITIALIZATION ====================

def initialize_pipeline() -> Tuple[Optional[AskSmart], dict]:
    """
    Initialize the complete SmartRAG pipeline.
    
    Steps:
        1. Load knowledge base catalog
        2. Initialize query analyser (intent detection)
        3. Initialize retrieval planner (strategy selection)
        4. Initialize filter generator (metadata filtering)
        5. Create AskSmart pipeline (orchestrator)
    
    Returns:
        tuple: (ask_smart_pipeline, kb_catalog)
            - ask_smart_pipeline: Initialized AskSmart instance or None if failed
            - kb_catalog: Loaded catalog dict
    
    Design:
        - Returns None for pipeline if initialization fails
        - Logs detailed error information
        - Does not raise exceptions (allows graceful degradation)
    """
    print("[PIPELINE_INIT] Starting SmartRAG pipeline initialization...")
    
    try:
        # Step 1: Load catalog
        kb_catalog = load_kb_catalog()
        
        # Step 2: Initialize components
        print("[PIPELINE_INIT] Initializing RAG components...")
        
        query_analyser = QueryAnalyser(
            model_id=MODEL_ID, 
            region=REGION
        )
        print("[PIPELINE_INIT]   ✓ QueryAnalyser initialized")
        
        retrieval_planner = RetrievalPlanner(
            min_results=3
        )
        print("[PIPELINE_INIT]   ✓ RetrievalPlanner initialized")
        
        filter_generator = FilterGenerator(
            kb_id=KB_ID, 
            region=REGION, 
            llm_model_id=MODEL_ID
        )
        print("[PIPELINE_INIT]   ✓ FilterGenerator initialized")
        
        # Step 3: Create pipeline
        ask_smart_pipeline = AskSmart(
            analyser=query_analyser,
            planner=retrieval_planner,
            filter_gen=filter_generator,
            kb_id=KB_ID,
            kb_catalog=kb_catalog,
            answer_model_id=MODEL_ID,
            region=REGION,
            max_context_tokens=MAX_CONTEXT_TOKENS
        )
        print("[PIPELINE_INIT]   ✓ AskSmart pipeline initialized")
        
        print("[PIPELINE_INIT]  Pipeline initialization complete")
        return ask_smart_pipeline, kb_catalog
        
    except Exception as e:
        print(f"[PIPELINE_INIT ERROR]  Failed to initialize pipeline: {e}")
        traceback.print_exc()
        return None, {}


# ==================== LAZY INITIALIZATION WITH RETRY ====================

def get_pipeline() -> Tuple[Optional[AskSmart], dict]:
    """
    Get pipeline with lazy initialization and retry logic.
    
    Features:
        - Thread-safe initialization (uses lock)
        - Automatic retry after failure (with backoff)
        - Circuit breaker (stops after MAX_INIT_FAILURES)
    
    Returns:
        tuple: (pipeline, catalog)
            - pipeline: AskSmart instance or None if unavailable
            - catalog: KB catalog dict (empty if pipeline failed)
    
    Usage:
        pipeline, catalog = get_pipeline()
        if pipeline is None:
            raise RuntimeError("RAG service unavailable")
        result = pipeline.ask(query)
    
    Design:
        - Fast path: Returns cached pipeline if already initialized
        - Slow path: Attempts initialization with retry logic
        - Circuit breaker: Stops retrying after repeated failures
    """
    global _pipeline, _catalog, _last_init_attempt, _init_failures
    
    # ==================== FAST PATH: Already Initialized ====================
    if _pipeline is not None:
        return _pipeline, _catalog
    
    # ==================== CHECK RETRY BACKOFF ====================
    current_time = time.time()
    time_since_last_attempt = current_time - _last_init_attempt
    
    # Circuit breaker: Stop retrying after too many failures
    if _init_failures >= MAX_INIT_FAILURES:
        print(f"[PIPELINE]  Circuit breaker active: {_init_failures} failures")
        print(f"[PIPELINE] Manual intervention required - check Bedrock connectivity")
        return None, {}
    
    # Backoff: Don't retry too soon after failure
    if _init_failures > 0 and time_since_last_attempt < RETRY_AFTER_SECONDS:
        remaining = int(RETRY_AFTER_SECONDS - time_since_last_attempt)
        print(f"[PIPELINE]  Retry backoff: {remaining}s remaining (attempt {_init_failures}/{MAX_INIT_FAILURES})")
        return None, {}
    
    # ==================== THREAD-SAFE INITIALIZATION ====================
    with _init_lock:
        # Double-check after acquiring lock (another thread may have initialized)
        if _pipeline is not None:
            return _pipeline, _catalog
        
        # Attempt initialization
        print(f"[PIPELINE]  Attempting initialization (failure count: {_init_failures})")
        _last_init_attempt = current_time
        
        try:
            temp_pipeline, temp_catalog = initialize_pipeline()
            
            if temp_pipeline is not None:
                # Success - cache the pipeline
                _pipeline = temp_pipeline
                _catalog = temp_catalog
                _init_failures = 0  # Reset failure counter
                
                print("[PIPELINE] ✅ Initialization successful - pipeline ready")
                return _pipeline, _catalog
            else:
                # Initialization returned None
                _init_failures += 1
                print(f"[PIPELINE]  Initialization returned None (failure #{_init_failures})")
                return None, {}
                
        except Exception as e:
            # Initialization raised exception
            _init_failures += 1
            print(f"[PIPELINE]  Initialization exception (failure #{_init_failures}): {e}")
            traceback.print_exc()
            return None, {}


# ==================== HEALTH CHECK ====================

def check_pipeline_health() -> dict:
    """
    Check pipeline health status.
    
    Returns:
        dict: Health status information
            {
                'healthy': bool,
                'pipeline_initialized': bool,
                'init_failures': int,
                'last_attempt': float,
                'retry_available': bool,
                'message': str
            }
    """
    global _pipeline, _init_failures, _last_init_attempt
    
    if _pipeline is not None:
        return {
            'healthy': True,
            'pipeline_initialized': True,
            'init_failures': _init_failures,
            'last_attempt': _last_init_attempt,
            'retry_available': False,
            'message': 'Pipeline operational'
        }
    
    current_time = time.time()
    time_since_last = current_time - _last_init_attempt if _last_init_attempt > 0 else 0
    can_retry = time_since_last >= RETRY_AFTER_SECONDS or _last_init_attempt == 0
    
    if _init_failures >= MAX_INIT_FAILURES:
        message = f'Circuit breaker active - {_init_failures} failures. Manual intervention required.'
    elif _init_failures > 0 and not can_retry:
        remaining = int(RETRY_AFTER_SECONDS - time_since_last)
        message = f'Retry backoff active - {remaining}s remaining'
    else:
        message = 'Pipeline not initialized - will retry on next request'
    
    return {
        'healthy': False,
        'pipeline_initialized': False,
        'init_failures': _init_failures,
        'last_attempt': _last_init_attempt,
        'retry_available': can_retry,
        'message': message
    }


# ==================== FORCE REINIT (for debugging) ====================

def force_reinitialize() -> Tuple[Optional[AskSmart], dict]:
    """
    Force pipeline reinitialization (ignores backoff).
    
    Use case: Manual retry after fixing configuration issues.
    
    Returns:
        tuple: (pipeline, catalog) - same as get_pipeline()
    """
    global _pipeline, _catalog, _init_failures, _last_init_attempt
    
    print("[PIPELINE] Forcing reinitialization...")
    
    with _init_lock:
        _pipeline = None
        _catalog = {}
        _init_failures = 0
        _last_init_attempt = 0
    
    return get_pipeline()


# ==================== BACKWARD COMPATIBILITY ====================

# Legacy module-level variables (deprecated - use get_pipeline() instead)
ask_smart_pipeline: Optional[AskSmart] = None
kb_catalog: dict = {}

ask_smart_pipeline = None
kb_catalog = {}



# ==================== EXPORTS ====================

__all__ = [
    'get_pipeline',           # ✅ Recommended: Use this in all code
    'check_pipeline_health',  # For health checks
    'force_reinitialize',     # For debugging
    'ask_smart_pipeline',     # ⚠️ Deprecated: Use get_pipeline() instead
    'kb_catalog'              # ⚠️ Deprecated: Use get_pipeline() instead
]