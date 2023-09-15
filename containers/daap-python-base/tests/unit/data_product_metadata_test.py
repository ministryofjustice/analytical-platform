import data_product_metadata


def test_get_latest_metadata_spec_path(monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)
    monkeypatch.setattr(
        data_product_metadata,
        "get_filepaths_from_s3_folder",
        lambda _name: ["v1/foo/bar", "v2/foo/bar"],
    )

    path = data_product_metadata.get_data_product_metadata_spec_path()
    assert (
        path
        == "s3://bucket/data_product_metadata_spec/v2/moj_data_product_metadata_spec.json"
    )


def test_get_specific_metadata_spec_path(monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)
    monkeypatch.setattr(
        data_product_metadata,
        "get_filepaths_from_s3_folder",
        lambda _name: ["v1/foo/bar", "v2/foo/bar"],
    )

    path = data_product_metadata.get_data_product_metadata_spec_path("v1")
    assert (
        path
        == "s3://bucket/data_product_metadata_spec/v1/moj_data_product_metadata_spec.json"
    )
