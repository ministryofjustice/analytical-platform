import os
from io import BytesIO
from zipfile import ZipFile
import pandas as pd
import requests
from sqlalchemy import create_engine

# get data
offender_management_stats_urls = [
    "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1094647/CSV.zip",
    "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1113618/CSV.zip",
]
offender_management_stats_requests = [
    requests.get(url) for url in offender_management_stats_urls
]

# unzip data and find relevant file
data_directory = os.path.join(os.getcwd(), "data")
if os.path.exists(data_directory) is False:
    os.mkdir(data_directory)

all_csv_filenames = []
for quarterly_report in offender_management_stats_requests:
    with ZipFile(BytesIO(quarterly_report.content)) as zipfile:
        zipfile.extractall(data_directory)
        all_csv_filenames += [
            file for file in zipfile.namelist() if file.endswith(".csv")
        ]

# push to postgres
DB_ENDPOINT = "localhost"  # os.environ.get("DB_ENDPOINT")
DB_USERNAME = "postgres"  # os.environ.get("DB_USERNAME")
DB_PASSWORD = "4y7sV96vA9wv46VR"  # os.environ.get("DB_PASSWORD")
DB_NAME = "my_database"  # os.environ.get("DB_NAME")
engine = create_engine(
    f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_ENDPOINT}:5432/{DB_NAME}"
)

for csv_file in all_csv_filenames:
    tablename = csv_file.split("Q")[0].split("/")[1]
    df = pd.read_csv(os.path.join("data", csv_file))
    df.to_sql(tablename, engine, if_exists="append")
