import requests
from zipfile import ZipFile
from sqlalchemy import create_engine
import pandas as pd
from io import BytesIO
import os

# get data
offender_management_stats_url = (
    "https://assets.publishing.service.gov.uk/government/uploads"
    + "/system/uploads/attachment_data/file/1131470/CSV.zip"
)
offender_management_stats = requests.get(offender_management_stats_url)

# unzip data and find relevant file
data_directory = os.path.join(os.getcwd(), "data")
if os.path.exists(data_directory) is False:
    os.mkdir(data_directory)
with ZipFile(BytesIO(offender_management_stats.content)) as zipfile:
    zipfile.extractall(data_directory)
    adjudications_file = [
        file for file in zipfile.namelist() if "Adjudications" in file
    ][0]

# push to postgres
DB_ENDPOINT = os.environ.get("DB_ENDPOINT")
DB_USERNAME = os.environ.get("DB_USERNAME")
DB_PASSWORD = os.environ.get("DB_PASSWORD")
DB_NAME = os.environ.get("DB_NAME")

engine = create_engine(
    f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_ENDPOINT}:5432/{DB_NAME}"
)
df = pd.read_csv(os.path.join("data", adjudications_file))
df.to_sql("adjudications", engine, if_exists="replace")
