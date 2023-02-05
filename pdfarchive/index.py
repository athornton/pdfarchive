"""
RecursiveIndexer class: create an index page for a directory containing PDF
files and JPGs and subdirectories of PDF files and JPGs.  Skip any directory
named "Text" or "Thumbs" since those contain extracted text and preview images.
"""
import logging
import os
import shutil
from pathlib import Path
from typing import List, Union
from urllib.parse import ParseResult, urlparse

from jinja2 import Environment, FileSystemLoader


class RecursiveIndexer:
    def __init__(
        self,
        base_url: Union[str, ParseResult],
        base_dir: Union[str, Path],
        archive_title: str = "",
        current_dir: Union[str, Path, None] = None,
        resolve: bool = True,
        debug: bool = False,
    ) -> None:
        """We presume that the document tree is writeable all the way up to
        the base_dir.  Assets will be copied to it, and the Thumbs and Text
        directories (and their subdirectories) will be created as needed.

        Things will end messily if the indexer cannot write to a destination.
        """

        # Put everything into canonically-typed form  (Path can accept a
        # Path as input)
        if type(base_url) is str:
            self.base_url = urlparse(base_url)
        elif type(base_url) is ParseResult:
            self.base_url = base_url
        else:
            # Shouldn't be able to happen, but mypy wasn't smart enough to
            # realize that type(base_url) is either str or ParseResult
            raise RuntimeError("base_url is neither str nor ParseResult")
        self.base_dir = Path(base_dir)
        if current_dir:
            self.current_dir = Path(current_dir)
        else:
            self.current_dir = self.base_dir
        self.resolve = resolve
        self.debug = debug

        # Do path resolution (if required) and sanity checks.
        # Resolution is turned on by default, but if you have part of your
        # tree symlinked from somewhere else, it will break.
        if resolve:
            self.base_dir = self.base_dir.resolve()
            self.current_dir = self.current_dir.resolve()
        if not self.base_dir.is_relative_to(self.current_dir):
            raise RuntimeError(
                f"{self.base_dir} is not contained by {self.current_dir}"
            )
        self.relative_path = self.base_dir.relative_to(self.current_dir)
        # Set cwd and umask
        os.chdir(self.current_dir)
        os.umask(0o022)

        if archive_title:
            self.archive_title = archive_title
        else:
            self.archive_title = self.base_dir.name

        # Set up logging
        self.logger = logging.getLogger()
        self.logger.setLevel("INFO")
        self.logger.info(f"Indexer created for {self.current_dir}")
        if self.debug:
            self.logger.setLevel("DEBUG")
            self.logger.debug(
                f"Debugging enabled for indexer at {self.current_dir}"
            )

        # Set up template environment
        self.jinja_environment = Environment(
            autoescape=True, loader=FileSystemLoader("./templates")
        )

    def generate_index_page(self) -> str:
        dirs: List[Path] = list()
        files: List[Path] = list()
        archives: List[Path] = list()

        # Categorize contents and incidentally
        # set file mode appropriately
        # TODO: add archive expansion
        rescan = True
        while rescan:
            dirs = list()
            files = list()
            archives = list()
            for child in self.current_dir.iterdir():
                if child.is_dir():
                    dirs.append(child)
                if child.is_file():
                    if child.suffix.lower() in ("pdf", "jpg", "png"):
                        files.append(child)
                    if child.suffix.lower() in ("zip", "gz", "tar", "xz"):
                        archives.append(child)
                    child.chmod(0o644)
            rescan = False  # When we do archive expansion we will set it to
            # true after expanding archives

        if self.current_dir == self.base_dir:
            self.copy_sitewide_files()
        else:
            # Links to containing directory only make sense *not* at the
            # archive root.
            upper_enc = self.generate_containing("top")
            lower_enc = self.generate_containing("bottom")

        file_content = self.generate_file_content(files)
        dir_content = self.generate_dir_content(dirs)
        archive_content = self.generate_archive_content(archives)

        page_content = (
            upper_enc
            + file_content
            + dir_content
            + archive_content
            + lower_enc
        )

        template = self.jinja_environment.get_template("index.template")
        if self.base_dir == self.current_dir:
            title = self.archive_title
        else:
            title = self.current_dir.name
        page = template.render(title=title, page_content=page_content)
        self.logger.debug(f"Index for {self.current_dir}:\n{page}")
        return page

    def generate_containing(self, c_id: str) -> str:
        template = self.jinja_environment.get_template(
            "containing_dir.template"
        )
        containing_dir = str(self.current_dir.parent)

        return template.render(
            containing_id=c_id, containing_dir=containing_dir
        )

    def generate_dir_content(self, dirs: List[Path]) -> str:
        if not dirs:
            return ""
        tbl_template = self.jinja_environment.get_template("dirtable.template")
        dir_template = self.jinja_environment.get_template("dir.template")
        dir_string = ""
        for c, d in enumerate(dirs):
            dir_string += dir_template.render(dir_id=str(c), dir_name=str(d))
        return tbl_template.render(dirs=dir_string)

    def generate_archive_content(self, archives: List[Path]) -> str:
        if not archives:
            return ""
        tbl_template = self.jinja_environment.get_template(
            "archivetable.template"
        )
        arc_template = self.jinja_environment.get_template("archive.template")
        arc_string = ""
        for c, a in enumerate(archives):
            arc_string += arc_template.render(
                archive_id=str(c), archive_name=str(a)
            )
        return tbl_template.render(archives=arc_string)

    def generate_file_content(self, files: List[Path]) -> str:
        if not files:
            return ""
        tbl_template = self.jinja_environment.get_template(
            "filetable.template"
        )
        arc_template = self.jinja_environment.get_template("file.template")
        arc_string = ""
        for c, f in enumerate(files):
            arc_string += arc_template.render(file_id=str(c), file_name=str(f))
        return tbl_template.render(files=arc_string)

    def write_index_page(self) -> None:
        with open("index.html", "w") as f:
            page = self.generate_index_page()
            f.write(page)

    def copy_sitewide_files(self) -> None:
        if self.current_dir != self.base_dir:
            self.logger.error(
                "Cannot copy sitewide files since cwd "
                + f"{self.current_dir} != base directory "
                + f"{self.base_dir}"
            )
            return
        tgt_scriptdir = Path(self.base_dir / "scripts")
        here = Path(__file__).parent
        src_scriptdir = Path(here / "assets" / "scripts")
        for scriptfile in src_scriptdir.iterdir():
            shutil.copyfile(scriptfile, Path(tgt_scriptdir / scriptfile.name))
            self.logger.debug("Copied {scriptfile} to {tgt_scriptdir}")
        shutil.copyfile(
            self.base_dir / "assets" / "file-text.svg",
            Path(self.base_dir / "favicon.svg"),
        )

    def index_pages(self) -> None:
        # Generate our own index page first
        self.write_index_page()
        # Now recurse down the tree
        for child in self.current_dir.iterdir():
            if child.is_dir():
                child.chmod(0o755)
                childindexer = self.__class__(
                    base_url=self.base_url,
                    base_dir=self.base_dir,
                    current_dir=child,
                    resolve=self.resolve,
                    debug=self.debug,
                )
                childindexer.index_pages()
