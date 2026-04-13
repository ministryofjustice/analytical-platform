region         = "eu-west-2"
project_name   = "moj-de-user-guidance"
environment    = "dev"
s3_bucket_name = "moj-de-user-guidance-kb-dev"
skip_kb_creation = true
skip_index_creation = true   # flip to false once SCP is fixed

# For existing bucket
create_s3_bucket = false

# For new bucket
#create_s3_bucket = true