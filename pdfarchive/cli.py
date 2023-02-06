#!/usr/bin/env python3
"""
This is the CLI for the PDF Archiver
"""
import argparse

from .index import Indexer


def main() -> None:
    """
    Create an argument parser, get our arguments, create an instance of the
    Indexer class with those arguments, and start it.
    """
    parser = argparse.ArgumentParser(description="Rebuild a PDF archive")
    parser.add_argument(
        "-f", "--base-dir", "--directory", help="Archive root directory"
    )
    parser.add_argument(
        "-u",
        "--base-url",
        "--url",
        "--base-uri",
        "--uri",
        help="URL/URI for the archive root",
    )
    parser.add_argument(
        "-t", "--archive-title", "--title", help="Title of root archive"
    )
    parser.add_argument(
        "-d",
        "--debug",
        "--verbose",
        help="enable debug logging",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "-r",
        "--resolve",
        "--resolve_paths",
        help=(
            "Resolve directory paths -- you must set to false if your"
            " archive has symlinked portions"
        ),
        action="store_true",
        default=True,
    )
    parser.add_argument(
        "-i",
        "--indexer_config_dir",
        help="Destination location of text indexer configuration",
    )
    args = parser.parse_args()
    index = Indexer(
        base_dir=args.base_dir,
        base_url=args.base_url,
        archive_title=args.archive_title,
        debug=args.debug,
        resolve=args.resolve,
        indexer_config_dir=args.indexer_config_dir,
    )
    index.build_site()
