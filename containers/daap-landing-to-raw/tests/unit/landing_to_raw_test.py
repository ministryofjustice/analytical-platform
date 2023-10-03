from unittest.mock import patch

from landing_to_raw import handler


def test_handler(s3_client, fake_context):
    test_event = {
        "detail": {
            "bucket": {"name": "landing"},
            "object": {
                "key": "landing/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv"
            },
        }
    }
    destination_bucket = "test"

    with patch("landing_to_raw.s3", s3_client):
        s3_client.create_bucket(Bucket=test_event["detail"]["bucket"]["name"])
        s3_client.create_bucket(Bucket=destination_bucket)
        s3_client.put_object(
            Key=test_event["detail"]["object"]["key"],
            Bucket=test_event["detail"]["bucket"]["name"],
            Body="a,b,c\n1,2,3\n4,5,6",
        )
        handler(test_event, fake_context)

        assert s3_client.get_object(
            Key="raw/data-product/v1.0/table/load_timestamp=20150210T130000Z/data.csv",
            Bucket=destination_bucket,
        )
