import json


def format_response_json(status_code, json_body) -> dict:
    formatted_response_json = {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json_body,
    }

    return formatted_response_json


def response_status_400(error) -> dict:
    response_body = json.dumps({"error": {"message": error}})
    formatted_response = format_response_json(400, response_body)

    return formatted_response


def response_status_404(error) -> dict:
    response_body = json.dumps({"error": {"message": error}})
    formatted_response = format_response_json(404, response_body)

    return formatted_response


def response_status_200(message) -> dict:
    response_body = json.dumps({"message": message})
    formatted_response = format_response_json(200, response_body)

    return formatted_response
