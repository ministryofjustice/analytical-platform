from pathlib import Path
from typing import Any, Dict

import pytest
from datahub.metadata.schema_classes import DomainPropertiesClass
from tests.test_helpers.graph_helpers import MockDataHubGraph
from tests.test_helpers.mce_helpers import check_golden_file

FROZEN_TIME = "2023-04-14 07:00:00"


@pytest.fixture
def base_entity_metadata():
    return {
        "urn:li:domain:12345": {
            "domainProperties": DomainPropertiesClass(
                name="Marketing", description="Marketing Domain"
            )
        }
    }


@pytest.fixture
def base_mock_graph(
    base_entity_metadata: Dict[str, Dict[str, Any]]
) -> MockDataHubGraph:
    return MockDataHubGraph(entity_graph=base_entity_metadata)


@pytest.fixture
def test_snapshots_dir(pytestconfig: pytest.Config) -> Path:
    return pytestconfig.rootpath / "tests/snapshots"


@pytest.fixture
def check_snapshot(test_snapshots_dir, pytestconfig):
    def _check_snapshot(name: str, output_file: Path):
        last_snapshot = Path(test_snapshots_dir / name)
        check_golden_file(pytestconfig, output_file, last_snapshot)

    return _check_snapshot


def pytest_addoption(parser):
    parser.addoption(
        "--update-golden-files",
        action="store_true",
        default=False,
    )
    parser.addoption("--copy-output-files", action="store_true", default=False)
