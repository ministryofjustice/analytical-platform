import time
from http import HTTPStatus

import boto3
import botocore
from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductSchema

athena_client = boto3.client("athena")


def format_plain_text_response(body: str, status_code: HTTPStatus) -> dict:
    return {
        "body": body,
        "statusCode": status_code,
        "headers": {"Content-Type": "text/plain"},
    }


def start_query_execution_and_wait(
    athena_client, database_name: str, sql: str, logger: DataPlatformLogger
) -> str:
    """
    runs query for given sql and waits for completion
    """
    try:
        res = athena_client.start_query_execution(
            QueryString=sql,
            QueryExecutionContext={"Database": database_name},
            WorkGroup="data_product_workgroup",
        )
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "InvalidRequestException":
            raise ValueError(e)
        else:
            raise ValueError(e)

    query_id = res["QueryExecutionId"]
    while response := athena_client.get_query_execution(QueryExecutionId=query_id):
        state = response["QueryExecution"]["Status"]["State"]
        if state not in ["SUCCEEDED", "FAILED"]:
            time.sleep(0.1)
        else:
            break

    if not state == "SUCCEEDED":
        logger.error(
            "Query {}, failed with response: {}".format(
                sql,
                response["QueryExecution"]["Status"].get("StateChangeReason"),
            )
        )
        raise ValueError(response["QueryExecution"]["Status"].get("StateChangeReason"))

    return query_id


def format_athena_results_to_table(results):
    # Format the results into a table string
    if not results or len(results["ResultSet"]["Rows"]) <= 1:
        return "No data to display"

    table = ""

    # Data rows
    headers = [
        value
        for header_dict in results["ResultSet"]["Rows"][0]["Data"]
        for value in header_dict.values()
    ]
    column_widths = {header: len(header) for header in headers}

    # Data rows
    data_result = []
    for row in results["ResultSet"]["Rows"][1:]:
        data = [value for data_dict in row["Data"] for value in data_dict.values()]
        data_result.append({key: value for key, value in zip(headers, data)})

    # Calculate the maximum width for each column based on header and data values
    for row in data_result:
        for header in headers:
            value = row[header]
            column_widths[header] = max(column_widths[header], len(str(value)))

    # Build the table header
    table = "|"
    for header in headers:
        table += f" {header.ljust(column_widths[header])} |"
    table += "\n"

    # Add data rows
    for row in data_result:
        table += "|"
        for header in headers:
            value = row[header]
            table += f" {str(value).ljust(column_widths[header])} |"
        table += "\n"

    return table


def handler(event, context, athena_client=athena_client):
    data_product_name = event["pathParameters"]["data-product-name"]
    table_name = event["pathParameters"]["table-name"]

    logger = DataPlatformLogger(
        data_product_name=data_product_name,
        table_name=table_name,
    )

    schema = DataProductSchema(
        data_product_name=data_product_name,
        table_name=table_name,
        logger=logger,
        input_data=None,
    )

    if not schema.exists:
        logger.error("Data product does not exists.")
        return format_plain_text_response(
            "Data product does not exist", HTTPStatus.NOT_FOUND
        )

    database_name = schema.database_name
    query = f'SELECT * FROM "{database_name}"."{table_name}" LIMIT 10'

    logger.info(f"'{query}' execution in progress")

    query_id = start_query_execution_and_wait(
        athena_client=athena_client,
        database_name=database_name,
        sql=query,
        logger=logger,
    )

    athena_results = athena_client.get_query_results(QueryExecutionId=query_id)

    formated_result = format_athena_results_to_table(athena_results)

    if formated_result == "No data to display":
        logger.info(formated_result)
        return format_plain_text_response(formated_result, HTTPStatus.NOT_FOUND)

    logger.info("Results fetched successfully")

    return format_plain_text_response(formated_result, HTTPStatus.OK)
