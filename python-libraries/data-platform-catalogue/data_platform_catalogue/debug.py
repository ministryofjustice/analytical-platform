"""
Debug utilities
"""
import argparse
import json
import os
from importlib.resources import files
from textwrap import indent

from .client.datahub.datahub_client import DataHubCatalogueClient


def help(args):
    parser.print_help()
    parser.exit()


def search(args):
    try:
        jwt_token = os.environ["JWT_TOKEN"]
        api_url = os.environ["API_URL"]
    except KeyError:
        raise KeyError(
            "Please set JWT_TOKEN and API_URL environment variables to continue"
        )

    search_query = (
        files("data_platform_catalogue.client.datahub.graphql")
        .joinpath("search.graphql")
        .read_text()
    )

    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    if args.verbose:
        response = client.graph.execute_graphql(
            search_query,
            {
                "query": args.query,
                "count": args.count,
                "start": args.page,
                "types": ["DATASET", "DATA_PRODUCT"],
                "filters": [],
            },
        )
        print(json.dumps(response, indent=2))
    else:
        response = client.search(query=args.query, count=args.count, page=args.page)
        print(f"{response.total_results} results found:\n")
        for i, result in enumerate(response.page_results, start=1):
            print(f"{i}: {result.name}")
            if result.description:
                print()
                print(indent(result.description, prefix="\t"))
            if result.metadata:
                print()
                for k, v in result.metadata.items():
                    print(f"\t{k} = {v!r}")
            print()


parser = argparse.ArgumentParser(
    prog="data-platform", description="Tool for debugging the data-platform catalogue."
)
parser.set_defaults(func=help)
subparsers = parser.add_subparsers(help="sub-command help")

search_parser = subparsers.add_parser("search", help="search the catalogue")
search_parser.set_defaults(func=search)
search_parser.add_argument(
    "-n", "--count", help="Number of results to return", default=1, type=int
)
search_parser.add_argument("-p", "--page", help="Page identifier", default=0, type=int)
search_parser.add_argument(
    "-v",
    "--verbose",
    action="store_true",
    help="If true, return the raw GraphQL response",
)
search_parser.add_argument("query", default="*", nargs="?")


def run():
    args = parser.parse_args()
    args.func(args)
