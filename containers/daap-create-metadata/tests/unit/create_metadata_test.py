import create_metadata


def test_missing_metadata_name_fail(fake_context):
    response = create_metadata.handler(
        {"metadata": {"domain": "MoJ"}}, context=fake_context
    )
    assert response["statusCode"] == 400


def test_existing_metadata_definition_fail(fake_context, monkeypatch):
    monkeypatch.setattr("data_product_metadata.metadata_exists", True)
    response = create_metadata.handler(
        {"metadata": {"domain": "MoJ"}}, context=fake_context
    )
    assert response["statusCode"] == 400
    assert (
        response["body"]["message"]
        == "Your data product already has a version 1 registered metadata."
    )


def test_metadata_creation_pass(fake_context):
    response = create_metadata.handler(
        {
            "metadata": {
                "name": "test_product",
                "description": "just testing the metadata json validation/registration",
                "domain": "MoJ",
                "dataProductOwner": "matthew.laverty@justice.gov.uk",
                "dataProductOwnerDisplayName": "matt laverty",
                "email": "matthew.laverty@justice.gov.uk",
                "status": "draft",
                "dpiaRequired": False,
            }
        },
        context=fake_context,
    )
    assert response["statusCode"] == 200


def test_metadata_validation_fail(fake_context, monkeypatch):
    monkeypatch.setattr("data_product_metadata.metadata_exists", True)
    monkeypatch.setattr("data_product_metadata.validate", True)
    monkeypatch.setattr("data_product_metadata.valid_metadata", True)
    monkeypatch.setattr("data_product_metadata.write_json_to_s3", True)
    response = create_metadata.handler(
        {
            "metadata": {
                "name": "test_product",
                "description": "incorrect data types in this data product",
                "domain": 123,
                "dataProductOwner": "matthew.laverty@justice.gov.uk",
                "dataProductOwnerDisplayName": "matt laverty",
                "email": "matthew.laverty@justice.gov.uk",
                "status": "draft",
                "dpiaRequired": "False",
            }
        },
        context=fake_context,
    )
    assert response["statusCode"] == 400
    print(response["body"]["message"])
