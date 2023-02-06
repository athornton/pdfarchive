from pathlib import Path

from pdfarchive.index import Indexer

root_path = Path("/")
base_dir = Path(root_path / "tmp" / "index")
base_url = base_dir.as_uri()
i = Indexer(base_dir=base_dir, base_url=base_url, debug=True)
