### smart_rag_logger.py
""" 
- Implements a request‑scoped, domain‑level logger for the RAG pipeline.
- Generates a unique request ID and records start timestamp, query, confidence, answer, and all logs.
- Captures logs for:
    - request start
    - component timings
    - successful completion
    - errors with stack traces
- Buffers per‑request logs and emits:
    - individual log entries
    - a final conversation summary to all configured backends
- Handles backend failures gracefully so logging never breaks the pipeline.
- Ensures conversation finalization occurs exactly once.

"""
import uuid
import traceback
from datetime import datetime, timezone
from helpers.apug.logging_observability.log_backends import LogBackend, CloudWatchBackend
from typing import List, Dict, Any, Optional

# Domain-level Logger
class SmartRAGLogger:
    """ 
    Smart RAG pipeline logger with pluggable storage backends. 

    Collects logs throughout request lifecycle and writes to configured backends.
    Ensures ask_smart.py remains AWS-agnostic by handling all infrastructure concerns.
    """
    
    def __init__(self, query: str, backends: Optional[List[LogBackend]] = None):
        """ 
        Initialize logger for a request.

        Args:
            query: User's question
            backends: List of storage backends (defaults to CloudWatch only)
        """
        # Generate unique request ID
        self.request_id = str(uuid.uuid4())
        
        # Store query
        self.query = query
        
        # Initialize backends
        self.backends = backends or [CloudWatchBackend()]
        
        # Store all logs for conversation record
        self.log_buffer = []
        
        # Track request lifecycle
        self.start_timestamp = self._get_timestamp()
        self.final_answer = None
        self.final_confidence = None
        self.error_occurred = False
        self.finalized = False  # Prevent double-finalization
        
        # Log request start
        self._log({
            "request_id": self.request_id,
            "timestamp": self.start_timestamp,
            "level": "INFO",
            "log_type": "request_start",
            "query": query,
            "query_length_chars": len(query)
        })
    
    def log_component(self, component_name: str, duration_ms: float, metadata: Dict[str, Any] = None):
        """
        Log component execution with timing and custom metadata.
        
        Args:
            component_name: Name of component (e.g., 'query_analyser', 'retrieval_planner')
            duration_ms: Execution time in milliseconds
            metadata: Additional component-specific data
        """
        log_data = {
            "request_id": self.request_id,
            "timestamp": self._get_timestamp(),
            "level": "INFO",
            "log_type": "component",
            "component_name": component_name,
            "duration_ms": round(duration_ms, 2),
            "metadata": metadata or {}
        }
        self._log(log_data)
    
    def log_success(self, total_duration_ms: float, metrics: Dict[str, Any]):
        """
        Log successful completion with final metrics.
        
        Args:
            total_duration_ms: Total request duration
            metrics: Final metrics (answer, confidence, sources, etc.)
        """
        log_data = {
            "request_id": self.request_id,
            "timestamp": self._get_timestamp(),
            "level": "INFO",
            "log_type": "request_success",
            "total_duration_ms": round(total_duration_ms, 2),
            "query": self.query,
            "query_length_chars": len(self.query),
            "metrics": metrics  # Explicitly nest metrics
        }
        
        # Store for conversation record
        self.final_answer = metrics.get("answer", "")
        self.final_confidence = metrics.get("confidence", 0.0)
        self.success_metrics = metrics
        
        self._log(log_data)
        
        # Write conversation record to backends that support it
        #self._finalize_conversation(success=True, metrics=metrics)
    
    def log_error(self, error: Exception, failed_component: str = None):
        """
        Log error with full debugging details.
        
        Args:
            error: Exception that occurred
            failed_component: Name of component that failed (if known)
        """
        log_data = {
            "request_id": self.request_id,
            "timestamp": self._get_timestamp(),
            "level": "ERROR",
            "log_type": "request_error",
            "failed_component": failed_component or "unknown",
            "error_type": type(error).__name__,
            "error_message": str(error),
            "full_query": self.query,
            "stacktrace": traceback.format_exc()
        }
        
        self.error_occurred = True
        self._log(log_data)
        
    def finalize(self):
        """
        Finalize logging and flush all backends.
        
        Should be called from Lambda's finally block to ensure:
        - Conversation record is written
        - All backend buffers are flushed
        - No duplicate finalization occurs
        
        Safe to call multiple times (no-op after first call).
        """
        if self.finalized:
            return  # Already finalized, skip
        
        self.finalized = True
        
        # Determine success based on whether error occurred
        success = not self.error_occurred
        
        # Write conversation record
        self._write_conversation_record(
            success=success,
            metrics=self.success_metrics if success else None
        )
        
        # Flush all backends
        for backend in self.backends:
            try:
                backend.flush()
            except Exception as e:
                print(f"[LOGGER ERROR] Flush failed for {type(backend).__name__}: {e}")
    
    # ----------------------------- Private Methods ---------------------------- #
    
    def _log(self, log_data: Dict[str, Any]):
        """
        Write log to all backends and buffer it.
        
        Args:
            log_data: Log entry to write
        """
        # Store in memory
        self.log_buffer.append(log_data)
        
        # Write to all backends
        for backend in self.backends:
            try:
                backend.write_log(log_data)
            except Exception as e:
                # Don't fail pipeline if logging fails
                print(f"[LOGGER ERROR] Backend {type(backend).__name__} failed: {e}")
    
    def _write_conversation_record(self, success: bool, metrics: Dict = None):
        """
        Write complete conversation record to backends.
        
        Args:
            success: Whether request succeeded
            metrics: Success metrics (if applicable)
    
        """
        
        # Build conversation record
        conversation_data = {
            "request_id": self.request_id,
            "timestamp": self.start_timestamp,
            "query": self.query,
            "query_length_chars": len(self.query),
            "success": success,
            "total_logs": len(self.log_buffer),
            "logs": self.log_buffer,
        }
        # for successful requests:
        if success and hasattr(self, 'success_metrics'):
            conversation_data["metrics"] = self.success_metrics
            conversation_data["answer"] = self.final_answer
            conversation_data["confidence"] = self.final_confidence
        
        # Add error-specific fields
        if not success and self.error_occurred:
            # Find error details from log buffer
            error_log = next(
                (log for log in self.log_buffer if log.get("log_type") == "request_error"),
                None
            )
            if error_log:
                conversation_data["error"] = error_log.get("error_message")
                conversation_data["error_type"] = error_log.get("error_type")
        
        # Write to backends that support conversation records
        for backend in self.backends:
            try:
                backend.write_conversation(conversation_data)
            except Exception as e:
                print(f"[LOGGER ERROR] Conversation write failed for {type(backend).__name__}: {e}")
    
    def _get_timestamp(self) -> str:
        """
        Return ISO format timestamp in UTC.
        
        Returns:
            ISO 8601 timestamp string (e.g., '2024-01-15T10:30:45.123Z')
        """
        return datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')

    