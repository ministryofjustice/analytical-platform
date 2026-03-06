"""
Mock responses for pipeline and Bedrock
"""
from typing import Dict, Any, List


def mock_successful_query_result(
    answer: str = "RAG stands for Retrieval-Augmented Generation.",
    confidence: float = 0.92,
    num_sources: int = 3
) -> Dict[str, Any]:
    """Mock successful query processing result"""
    sources = [
        {
            'title': f'Document {i+1}',
            'score': 0.9 - (i * 0.05),
            'url': f'https://example.com/doc{i+1}',
            'excerpt': f'This is excerpt from document {i+1}...'
        }
        for i in range(num_sources)
    ]
    
    return {
        'answer': answer,
        'confidence': confidence,
        'sources': sources,
        'request_id': 'mock-req-123',
        'validation_issues': []
    }


def mock_pipeline_result():
    """Mock AskSmart pipeline result object"""
    from unittest.mock import Mock
    
    result = Mock()
    result.answer = "RAG stands for Retrieval-Augmented Generation."
    result.confidence = 0.92
    result.sources = [
        {'title': 'RAG Paper', 'score': 0.95, 'url': 'https://arxiv.org/abs/2005.11401'}
    ]
    result.validation_issues = []
    
    return result


def mock_bedrock_throttling_error():
    """Mock Bedrock ThrottlingException"""
    from botocore.exceptions import ClientError
    
    return ClientError(
        {
            'Error': {
                'Code': 'ThrottlingException',
                'Message': 'Rate exceeded'
            },
            'ResponseMetadata': {
                'RequestId': 'bedrock-req-456',
                'HTTPStatusCode': 429
            }
        },
        'InvokeModel'
    )


def mock_bedrock_service_error():
    """Mock Bedrock ServiceUnavailableException"""
    from botocore.exceptions import ClientError
    
    return ClientError(
        {
            'Error': {
                'Code': 'ServiceUnavailableException',
                'Message': 'Service temporarily unavailable'
            },
            'ResponseMetadata': {
                'RequestId': 'bedrock-req-789',
                'HTTPStatusCode': 503
            }
        },
        'InvokeModel'
    )


def mock_bedrock_validation_error():
    """Mock Bedrock ValidationException"""
    from botocore.exceptions import ClientError
    
    return ClientError(
        {
            'Error': {
                'Code': 'ValidationException',
                'Message': 'Invalid request format'
            },
            'ResponseMetadata': {
                'RequestId': 'bedrock-req-101',
                'HTTPStatusCode': 400
            }
        },
        'InvokeModel'
    )


# Export all
__all__ = [
    'mock_successful_query_result',
    'mock_pipeline_result',
    'mock_bedrock_throttling_error',
    'mock_bedrock_service_error',
    'mock_bedrock_validation_error'
]
