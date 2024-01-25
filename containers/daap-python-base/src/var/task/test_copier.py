import logging
import sys
from os.path import dirname, join


sys.path.append("src/var/task/curated_data")
from data_platform_paths import DataProductElement
from versioning import VersionManager
# export AWS_DEFAULT_REGION="eu-west-2"
version_manager = VersionManager("court_timeliness", logging.getLogger())

result = version_manager.update_metadata_remove_schemas(
    ["civil_court_timeliness"]
)
print(result)
