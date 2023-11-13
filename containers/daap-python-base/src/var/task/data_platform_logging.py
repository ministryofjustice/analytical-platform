import json
import logging
import os
import time
from typing import List

import boto3
import structlog
from botocore.exceptions import ClientError
from data_platform_paths import data_product_log_bucket_and_key

# aws lambda uses UTC so setting the timezone for correct time.
os.putenv("TZ", "Europe/London")
time.tzset()

# additional arguments relating to data bucket security of data platform
s3_security_opts = {
    "ACL": "bucket-owner-full-control",
    "ServerSideEncryption": "AES256",
}

logging_levels = {
    "INFO": logging.INFO,
    "DEBUG": logging.DEBUG,
    "WARNING": logging.WARNING,
    "ERROR": logging.ERROR,
}


class DataPlatformLogger:
    """
    Logger for Data Platform Lambda python applications.

    Provides some flexibility regarding extra information to be logged.

    Any extra information can be passed on instantiation of class as a
    dict object.

    Extras can also be added to the class after instantiation using the
    add_data_product() or add_extras() methods.
    """

    def __init__(
        self,
        data_product_name: str | None = None,
        table_name: str | None = None,
        format: str = "%(levelname)-8s | %(asctime)s | %(message)s",
        extra: dict | None = None,
        level: str = "INFO",
    ):
        if extra is None:
            extra = {}

        self.extra = {
            "lambda_name": os.getenv("AWS_LAMBDA_FUNCTION_NAME", None),
            "data_product_name": data_product_name,
            "table_name": table_name,
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
        }

        self.extra.update(extra)

        self.log_list_dict: List[dict] = []
        self.format = format
        structlog.configure(
            wrapper_class=structlog.make_filtering_bound_logger(logging_levels[level]),
            processors=[
                structlog.processors.EventRenamer(to="message"),
                structlog.processors.TimeStamper(
                    fmt="%Y-%m-%d %H:%M:%S", key="date_time"
                ),
                structlog.processors.add_log_level,
                structlog.processors.dict_tracebacks,
                structlog.processors.CallsiteParameterAdder(
                    parameters={structlog.processors.CallsiteParameter.FUNC_NAME},
                    additional_ignores=["data_platform_logging"],
                ),
                self.write_log_dict_to_s3_json,
                structlog.processors.JSONRenderer(),
            ],
        )
        self.logger = structlog.get_logger(**self.extra)

        self.log_bucket_path = data_product_log_bucket_and_key(
            lambda_name=self.extra["lambda_name"], data_product_name=data_product_name
        )

    def add_data_product(self, data_product_name: str, table_name: str | None = None):
        """
        This method can be used to add data product information to a logger
        object after it has been instantiated.
        """
        return self.add_extras(
            {"data_product_name": data_product_name, "table_name": table_name}
        )

    def add_extras(self, other_extras: dict):
        """
        This method can be used to add additional information to a logger
        object after it has been instantiated.
        """
        self.extra.update(other_extras)
        self.logger = self.logger.bind(**other_extras)
        return self

    def debug(self, msg: str, *args, **kwargs):
        """
        Method for logging message at the debug level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        self.logger.debug(msg, *args, **kwargs)

    def info(self, msg: str, *args, **kwargs):
        """
        Method for logging message at the info level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        self.logger.info(msg, *args, **kwargs)

    def warning(self, msg: str, *args, **kwargs):
        """
        Method for logging message at the warning level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        self.logger.warning(msg, *args, **kwargs)

    def error(self, msg: str, *args, **kwargs):
        """
        Method for logging message at the error level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        self.logger.error(msg, *args, **kwargs)

    def write_log_dict_to_s3_json(self, _logger, _method_name, event_dict) -> dict:
        """
        writes the list of log dicts to s3 as a json file in the correct
        format for an athena table
        """
        event_dict["function_name"] = event_dict.pop("func_name")
        s3_client = boto3.client("s3")

        try:
            response = s3_client.get_object(
                Bucket=self.log_bucket_path.bucket, Key=self.log_bucket_path.key
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "NoSuchKey":
                jlines = ""
            else:
                # if an unexpected error we want to exit the method
                # to avoid creating a log file with 1 line of last log
                # but not raise an error, disrupting the application
                return event_dict
        else:
            data = response.get("Body").read().decode("utf-8")
            jlines = data

        jlines += json.dumps(event_dict) + "\n"

        s3_client.put_object(
            Body=jlines,
            Bucket=self.log_bucket_path.bucket,
            Key=self.log_bucket_path.key,
            **s3_security_opts
        )

        return event_dict
