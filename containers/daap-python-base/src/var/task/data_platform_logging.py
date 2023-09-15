import inspect
import json
import logging
import os
import sys
import time
from datetime import datetime
from typing import List

import boto3
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


def _make_log_dict(level: str, msg: str, extra: dict, func: str) -> dict:
    """
    creates a dict with all the standard logging items plus a key
    and value for any of the extra information passed to the logger
    class.
    """
    msg_dict = {}
    msg_dict["level"] = level
    msg_dict["date_time"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    msg_dict["message"] = msg
    msg_dict["function_name"] = func

    for k, v in extra.items():
        msg_dict[k] = v
    return msg_dict


class DataPlatformLogger:
    """
    Logger for Data Platform Lambda python applications.

    Provides some flexibility regarding extra information to be logged.

    Any extra information can be passed on instantiation of class as a
    dict object.

    Extras can also be added to the class after instantiation using the
    add_extras() method. With this you can also choose whether to add them
    into the standard output log line or just collect in the json object.

    E.g. a lambda container function executing a data product load could contain:
        logger = DataPlatformLogger({
            "lambda_function_name": context.function_name,
            "image_version": "1.0.0"),
            "data_product_name": "great_data_product",
            "table_name": "useful_table"
        })
    """

    def __init__(
        self,
        data_product_name: str | None = None,
        format: str = "%(levelname)-8s | %(asctime)s | %(message)s",
        extra: dict | None = None,
        level: str = "INFO",
    ):
        if extra is None:
            extra = {}
        self.extra = {}
        self.extra["lambda_name"] = os.getenv("AWS_LAMBDA_FUNCTION_NAME", None)
        self.extra["data_product_name"] = data_product_name

        for k, v in extra.items():
            self.extra[k] = v
        self.log_list_dict: List[dict] = []
        self.format = format
        self.logger = logging.getLogger()

        self.log_bucket_path = data_product_log_bucket_and_key(
            lambda_name=self.extra["lambda_name"], data_product_name=data_product_name
        )

        # if used in a lambda function we remove the preloaded handlers
        for h in self.logger.handlers:
            self.logger.removeHandler(h)

        handler = logging.StreamHandler(sys.stdout)

        handler.setFormatter(logging.Formatter(format, datefmt="%Y-%m-%d %H:%M:%S"))
        self.logger.addHandler(handler)
        self.logger.setLevel(logging_levels[level])

    def add_extras(self, other_extras: dict, format=None):
        """
        This method can be used to add additional information to a logger
        object after it has been instantiated.

        If given a format the new information will be added to the log
        line in the standard output too. Other wise the extra information
        will be collected in log_list_dict and can be written out as a json.
        """
        for k, v in other_extras.items():
            self.extra[k] = v
        if format is not None:
            self.logger.removeHandler(self.logger.handlers[0])
            handler = logging.StreamHandler(sys.stdout)

            handler.setFormatter(logging.Formatter(format, datefmt="%Y-%m-%d %H:%M:%S"))
            self.logger.addHandler(handler)

        return self

    def debug(self, msg: str, *args, **kwargs):
        """
        Method for logging message at the debug level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        log_dict = _make_log_dict("debug", msg, self.extra, inspect.stack()[1].function)
        self._write_log_dict_to_s3_json(log_dict)
        self.logger.debug(msg, *args, extra=self.extra, **kwargs)

    def info(self, msg: str, *args, **kwargs):
        """
        Method for logging message at the info level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        log_dict = _make_log_dict("info", msg, self.extra, inspect.stack()[1].function)
        self._write_log_dict_to_s3_json(log_dict)
        self.logger.info(msg, *args, extra=self.extra, **kwargs)

    def warning(self, msg: str, *args, **kwargs):
        """
        Method for logging message at the warning level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        log_dict = _make_log_dict(
            "warning", msg, self.extra, inspect.stack()[1].function
        )
        self._write_log_dict_to_s3_json(log_dict)
        self.logger.warning(msg, *args, extra=self.extra, **kwargs)

    def error(self, msg: str, *args, **kwargs):
        """
        Method for logging message at the error level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        log_dict = _make_log_dict("error", msg, self.extra, inspect.stack()[1].function)
        self._write_log_dict_to_s3_json(log_dict)
        self.logger.error(msg, *args, extra=self.extra, **kwargs)

    def _write_log_dict_to_s3_json(
        self, log_line: dict, additional_args: dict = s3_security_opts
    ) -> None:
        """
        writes the list of log dicts to s3 as a json file in the correct
        format for an athena table
        """
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
                print(e)
                return None
        else:
            data = response.get("Body").read().decode("utf-8")
            jlines = data

        jlines += json.dumps(log_line) + "\n"

        s3_client.put_object(
            Body=jlines,
            Bucket=self.log_bucket_path.bucket,
            Key=self.log_bucket_path.key,
            **additional_args
        )
