import inspect
import json
import logging
import os
import sys
import time
from datetime import datetime

import boto3

# aws lambda uses UTC so setting the timezone for correct time.
os.putenv("TZ", "Europe/London")
time.tzset()


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
    Logger for Data Platform applications.

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
        format: str = "%(levelname)-8s | %(asctime)s | %(message)s",
        extra: dict = {},
    ):
        self.extra = extra
        self.log_list_dict = []
        self.format = format
        self.logger = logging.getLogger()

        # if used in a lambda function we remove the preloaded handlers
        for h in self.logger.handlers:
            self.logger.removeHandler(h)

        handler = logging.StreamHandler(sys.stdout)

        handler.setFormatter(logging.Formatter(format, datefmt="%Y-%m-%d %H:%M:%S"))
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)

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

    def debug(self, msg, *args, **kwargs):
        """
        Method for logging message at the debug level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        log_dict = _make_log_dict("debug", msg, self.extra, inspect.stack()[1].function)
        self.log_list_dict.append(log_dict)
        self.logger.debug(msg, *args, extra=self.extra, **kwargs)

    def info(self, msg, *args, **kwargs):
        """
        Method for logging message at the info level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        log_dict = _make_log_dict("info", msg, self.extra, inspect.stack()[1].function)
        self.log_list_dict.append(log_dict)
        self.logger.info(msg, *args, extra=self.extra, **kwargs)

    def warning(self, msg, *args, **kwargs):
        """
        Method for logging message at the warning level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        log_dict = _make_log_dict(
            "wanring", msg, self.extra, inspect.stack()[1].function
        )
        self.log_list_dict.append(log_dict)
        self.logger.warning(msg, *args, extra=self.extra, **kwargs)

    def error(self, msg, *args, **kwargs):
        """
        Method for logging message at the error level. Displays in the standard output
        as per the set format.

        Also adds the displays log info plus everything contained in extra.

        """
        log_dict = _make_log_dict("error", msg, self.extra, inspect.stack()[1].function)
        self.log_list_dict.append(log_dict)
        self.logger.error(msg, *args, extra=self.extra, **kwargs)

    def write_log_dict_to_s3_json(self, bucket: str, **kwargs):
        """
        writes the list of log dicts to s3 as a json file in the correct
        format for an athena table
        """
        s3_client = boto3.client("s3")
        date = datetime.now().strftime("%Y-%m-%d")
        date_time = datetime.now().strftime("%Y-%m-%dT%H:%M:%S:%f")[:-3]
        if (
            "lambda_name" in self.extra.keys()
            and "data_product_name" in self.extra.keys()
        ):
            key = os.path.join(
                "logs",
                "json",
                f"lambda_name={self.extra['lambda_name']}",
                f"data_product_name={self.extra['data_product_name']}",
                f"date={date}",
                f"{date_time}_log.json",
            )
        else:
            key = os.path.join("logs", "json", f"date={date}", f"{date_time}_log.json")

        # make the json object into the correct format for athena
        jlines = ""
        for line in self.log_list_dict:
            jlines += json.dumps(line) + "\n"

        s3_client.put_object(Body=jlines, Bucket=bucket, Key=key, **kwargs)
