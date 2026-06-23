# Database Module

Creates DynamoDB table for RAG conversation logging.

## Resources Created

- **DynamoDB Table** - Stores conversation logs with TTL
- **GSIs** - UserTimeIndex, SessionIndex for querying
- **Streams** - For future real-time analytics/triggers

## Schema

| Attribute | Type | Key |
|-----------|------|-----|
| `request_id` | String | Partition Key |
| `timestamp` | String | Sort Key |
| `user_id` | String | GSI (UserTimeIndex) |
| `session_id` | String | GSI (SessionIndex) |
| `ttl` | Number | TTL attribute (90 days) |

## Usage

```hcl
module "database" {
  source = "../../modules/database"

  project_name = "genai-data-eng"
  environment  = "dev"

  tags = local.common_tags
}