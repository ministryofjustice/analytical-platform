import pytest
from reload_data_product import get_data_product_pages, handler, s3_recursive_delete


@pytest.fixture
def empty_curated_data_bucket(s3_client):
    bucket_name = "curated"
    s3_client.create_bucket(Bucket=bucket_name)
    return bucket_name


@pytest.fixture
def curated_data_bucket(s3_client, empty_curated_data_bucket, data_product):
    bucket_name = empty_curated_data_bucket
    s3_client.put_object(
        Bucket=bucket_name, Key=f"{data_product.curated_data_prefix.key}baz", Body=""
    )
    s3_client.put_object(
        Bucket=bucket_name,
        Key=f"{data_product.curated_data_prefix.key}abc",
        Body="",
    )
    s3_client.put_object(Bucket=bucket_name, Key="some-other", Body="")
    return bucket_name


@pytest.fixture
def empty_raw_data_bucket(s3_client):
    bucket_name = "raw"
    s3_client.create_bucket(Bucket=bucket_name)
    return bucket_name


@pytest.fixture
def raw_data_bucket(s3_client, empty_raw_data_bucket, data_product):
    bucket_name = empty_raw_data_bucket
    s3_client.put_object(
        Bucket=bucket_name, Key=data_product.raw_data_prefix.key + "abc", Body=""
    )
    s3_client.put_object(
        Bucket=bucket_name, Key=data_product.raw_data_prefix.key + "baz", Body=""
    )
    return bucket_name


def test_s3_recursive_delete(s3_client, curated_data_bucket, data_product):
    s3_recursive_delete(
        bucket=curated_data_bucket,
        s3_client=s3_client,
        prefix=data_product.curated_data_prefix.key,
    )

    keys = [
        i["Key"]
        for i in s3_client.list_objects_v2(Bucket=curated_data_bucket)["Contents"]
    ]
    assert keys == ["some-other"]


def test_get_data_product_pages(s3_client, raw_data_bucket, data_product):
    pages = list(
        get_data_product_pages(
            bucket=raw_data_bucket,
            data_product_prefix=data_product.raw_data_prefix.key,
            s3_client=s3_client,
        )
    )
    assert len(pages) == 1
    assert {i["Key"] for i in pages[0]["Contents"]} == {
        "raw_data/foo/bar/abc",
        "raw_data/foo/bar/baz",
    }


def test_get_empty_data_product_pages(s3_client, empty_raw_data_bucket):
    with pytest.raises(ValueError):
        get_data_product_pages(
            bucket=empty_raw_data_bucket,
            data_product_prefix="raw_data/foo",
            s3_client=s3_client,
        )


def test_handler_recursively_deletes_curated_data(
    s3_client,
    glue_client,
    do_nothing_lambda_client,
    data_product,
    curated_data_bucket,
    raw_data_bucket,
    fake_context,
):
    glue_client.create_database(
        DatabaseInput={"Name": data_product.curated_data_table.database}
    )

    handler(
        event={"data_product": data_product.name},
        context=fake_context,
        glue=glue_client,
        s3=s3_client,
        aws_lambda=do_nothing_lambda_client,
        athena_load_lambda="athena_load_lambda",
        raw_data_bucket=raw_data_bucket,
        curated_data_bucket=curated_data_bucket,
    )

    keys = [
        i["Key"]
        for i in s3_client.list_objects_v2(Bucket=curated_data_bucket)["Contents"]
    ]
    assert keys == ["some-other"]


def test_handler_invokes_lambda_for_each_raw_file(
    s3_client,
    glue_client,
    do_nothing_lambda_client,
    data_product,
    curated_data_bucket,
    raw_data_bucket,
    fake_context,
):
    glue_client.create_database(
        DatabaseInput={"Name": data_product.curated_data_table.database}
    )

    handler(
        event={"data_product": data_product.name},
        context=fake_context,
        glue=glue_client,
        s3=s3_client,
        aws_lambda=do_nothing_lambda_client,
        athena_load_lambda="athena_load_lambda",
        raw_data_bucket=raw_data_bucket,
        curated_data_bucket=curated_data_bucket,
    )

    do_nothing_lambda_client.invoke.assert_any_call(
        FunctionName="athena_load_lambda",
        InvocationType="Event",
        Payload=f'{{"detail":{{"bucket":{{"name":"{raw_data_bucket}"}}, "object":{{"key":"raw_data/foo/bar/abc"}}}}}}',
    )

    do_nothing_lambda_client.invoke.assert_any_call(
        FunctionName="athena_load_lambda",
        InvocationType="Event",
        Payload=f'{{"detail":{{"bucket":{{"name":"{raw_data_bucket}"}}, "object":{{"key":"raw_data/foo/bar/baz"}}}}}}',
    )


def test_handler_deletes_glue_table(
    s3_client,
    glue_client,
    do_nothing_lambda_client,
    data_product,
    curated_data_bucket,
    raw_data_bucket,
    fake_context,
):
    glue_client.create_database(
        DatabaseInput={"Name": data_product.curated_data_table.database}
    )
    glue_client.create_table(
        TableInput={"Name": "foo"},
        DatabaseName=data_product.curated_data_table.database,
    )

    handler(
        event={"data_product": data_product.name},
        context=fake_context,
        glue=glue_client,
        s3=s3_client,
        aws_lambda=do_nothing_lambda_client,
        athena_load_lambda="athena_load_lambda",
        raw_data_bucket=raw_data_bucket,
        curated_data_bucket=curated_data_bucket,
    )

    response = glue_client.get_tables(
        DatabaseName=data_product.curated_data_table.database
    )
    assert response["TableList"] == []
