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
from urllib.parse import ParseResult, quote, urlparse

from jinja2 import Environment, FileSystemLoader

_here = Path(__file__).parent


def _uplink(l_id: str) -> str:
    fragment = """
            <div id="containing_{containing_id}">
            <i data-feather="arrow-up-circle"></i>
            <a href="../index.html">
            Parent Folder
            </a>
            </div>
            <div style="clear: both"></div>
            <hr>
            """
    return fragment.format(containing_id=l_id)


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
        self.relative_path = self.current_dir.relative_to(self.base_dir)
        if not self.relative_path:
            raise RuntimeError(
                f"{self.base_dir} does not contain {self.current_dir}"
            )
        if self.relative_path == Path("."):
            self.is_root = True
            self.path_to_base = self.relative_path
        else:
            path_to_base = Path()
            walk_path = Path(self.current_dir)
            while walk_path and walk_path != self.base_dir:
                path_to_base = Path(".." / path_to_base)
                walk_path = walk_path.parent
            self.path_to_base = path_to_base
            self.is_root = False

        # Set cwd and umask
        os.chdir(self.current_dir)
        os.umask(0o022)

        if archive_title:
            self.archive_title = archive_title
        else:
            self.archive_title = self.base_dir.name

        # Set up logging
        self.logger = logging.getLogger(__name__)
        ch = logging.StreamHandler()
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        ch.setFormatter(formatter)
        self.logger.addHandler(ch)
        self.logger.setLevel("INFO")
        self.logger.info(f"Indexer created for {self.current_dir}")
        if self.debug:
            self.logger.setLevel("DEBUG")
            self.logger.debug(
                f"Debugging enabled for indexer at {self.current_dir}"
            )

        # Set up template environment
        self.jinja_environment = Environment(
            loader=FileSystemLoader(Path(_here / "templates"))
        )

    @property
    def path_to_base_str(self) -> str:
        return str(self.path_to_base)

    @property
    def relative_path_str(self) -> str:
        return str(self.relative_path)

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
                    # Skip the top-level scripts, css, Thumbs, and Text dirs
                    if self.is_root and child.name in (
                        "scripts",
                        "css",
                        "Thumbs",
                        "Text",
                    ):
                        continue
                    dirs.append(child)
                if child.is_file():
                    if child.suffix.lower() in (".pdf", ".jpg", ".png"):
                        files.append(child)
                    if child.suffix.lower() in (
                        ".zip",
                        ".gz",
                        ".tar",
                        ".xz",
                        ".7z",
                    ):
                        archives.append(child)
                    child.chmod(0o644)
            rescan = False  # When we do archive expansion we will set it to
            # true after expanding archives

        if self.current_dir == self.base_dir:
            self.copy_sitewide_files()
            enc_t = ""
            enc_b = ""
        else:
            enc_t = _uplink("top")
            enc_b = _uplink("bottom")

        file_content = self.generate_file_content(files)
        dir_content = self.generate_dir_content(dirs)
        archive_content = self.generate_archive_content(archives)

        page_content = (
            enc_t + file_content + dir_content + archive_content + enc_b
        )

        template = self.jinja_environment.get_template("index.template")
        if self.base_dir == self.current_dir:
            title = self.archive_title
        else:
            title = self.current_dir.name
        page = template.render(
            title=title,
            page_content=page_content,
            top_name=self.archive_title,
            top_dir=self.path_to_base_str,
        )
        return page

    def generate_dir_content(self, dirs: List[Path]) -> str:
        if not dirs:
            return ""
        tbl_template = self.jinja_environment.get_template("dirtable.template")
        dir_template = self.jinja_environment.get_template("dir.template")
        dir_string = ""
        for c, d in enumerate(dirs):
            dir_string += dir_template.render(
                dir_id=str(c), dir_name=quote(d.name)
            )
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
            fname = quote(a.name)
            basename = quote(a.stem)
            arc_string += arc_template.render(
                archive_id=str(c), archive_name=fname, base_name=basename
            )
        return tbl_template.render(archives=arc_string)

    def generate_file_content(self, files: List[Path]) -> str:
        if not files:
            return ""
        tbl_template = self.jinja_environment.get_template(
            "filetable.template"
        )
        file_template = self.jinja_environment.get_template("file.template")
        file_string = ""
        for c, f in enumerate(files):
            fname = quote(f.name)
            basename = quote(f.stem)
            file_string += file_template.render(
                file_id=str(c),
                file_name=fname,
                partial_path=self.relative_path_str,
                base_path=self.path_to_base_str,
                base_name=basename,
                thumb_name=f"{basename}_thumb.png",
                text_name=f"{basename}.txt",
            )
        return tbl_template.render(files=file_string)

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
        tgt_scriptdir = Path(self.path_to_base / "scripts")
        tgt_scriptdir.mkdir(exist_ok=True)
        src_scriptdir = Path(_here / "assets" / "scripts")
        for scriptfile in src_scriptdir.iterdir():
            shutil.copyfile(scriptfile, Path(tgt_scriptdir / scriptfile.name))
        tgt_cssdir = Path(self.path_to_base / "css")
        tgt_cssdir.mkdir(exist_ok=True)
        src_cssdir = Path(_here / "assets" / "css")
        for cssfile in src_cssdir.iterdir():
            shutil.copyfile(cssfile, Path(tgt_cssdir / cssfile.name))
        shutil.copyfile(
            _here / "assets" / "file-text.svg",
            Path(self.base_dir / "favicon.svg"),
        )

    def index_pages(self) -> None:
        # Generate our own index page first
        self.write_index_page()
        # Now recurse down the tree
        for child in self.current_dir.iterdir():
            if child.is_dir():
                # Skip the top-level scripts, css, Thumbs, and Text dirs
                if self.is_root and child.name in (
                    "scripts",
                    "css",
                    "Thumbs",
                    "Text",
                ):
                    continue
                child.chmod(0o755)
                childindexer = self.__class__(
                    base_url=self.base_url,
                    base_dir=self.base_dir,
                    current_dir=child,
                    resolve=self.resolve,
                    debug=self.debug,
                )
                childindexer.index_pages()
