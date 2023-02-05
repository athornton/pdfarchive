"""
RecursiveIndexer class: create an index page for a directory containing PDF
files and JPGs and subdirectories of PDF files and JPGs.  Skip any directory
named "Text" or "Thumbs" since those contain extracted text and preview images.
"""
import logging
import os
from pathlib import Path
from typing import List, Optional

"""The original version assumed three top-level directories, "Mags", "Other",
and "TSR", each with its own Text and Thumbs directories.  We're going to
change that and combine the indexes."""


class RecursiveIndexer:
    def __init__(
        self,
        base_url: Path,
        base_dir: Path,
        start_dir: Optional[Path] = None,
        resolve: bool = True,
        debug: bool = False,
    ) -> None:
        # Canonicalize base URL
        if not base_url.endswith("/"):
            base_url = base_url + "/"
        self.base_url = base_url

        # Do path resolution (if required) and sanity checks.
        self.base_dir = base_dir.resolve()
        self.debug = debug
        if start_dir is None:
            self.start_dir = self.base_dir
        else:
            self.start_dir = start_dir
        if resolve:
            self.base_dir = self.base_dir.resolve()
            self.start_dir = self.start_dir.resolve()
        if not self.base_dir.is_relative_to(self.start_dir):
            raise RuntimeError(
                f"{self.base_dir} is not contained by {self.start_dir}"
            )
        self.relative_path = self.base_dir.relative_to(self.start_dir)
        # Set cwd
        os.chdir(self.start_dir)

        # Set up logging
        self.logger = logging.getLogger()
        self.logger.setLevel("INFO")
        self.logger.info(f"Indexer created for {self.start_dir}")
        if debug:
            self.logger.setLevel("DEBUG")
            self.logger.debug(
                f"Debugging enabled for indexer at {self.start_dir}"
            )

    def generate_index_page(self) -> str:
        dirs: List[Path] = list()
        files: List[Path] = list()
        archives: List[Path] = list()

        # Categorize contents
        for child in self.start_dir:
            if child.is_dir:
                dirs.append(child)
            if child.is_file:
                if child.suffix.lower() in ("pdf", "jpg", "png"):
                    files.append(child)
                if child.suffix.lower() in ("zip", "gz", "tar", "xz"):
                    archives.append(child)
