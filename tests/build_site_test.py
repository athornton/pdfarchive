import filecmp
from pathlib import Path

from pdfarchive.index import Indexer


def test_build_site(testdata: Path, src_testdata: Path) -> None:
    indexer = Indexer(
        base_dir=Path(testdata / "index"), base_url="file:///.", debug=True
    )
    filecmp.clear_cache()
    indexer.build_site()
    output_files = sorted(
        Path(src_testdata / "output" / "index").glob("**/index.html")
    )
    input_files = sorted(Path(testdata / "index").glob("**/index.html"))
    # If the lists are different sizes obviously we broke
    assert len(input_files) == len(output_files)
    # And now let's see if the files are identical
    for idx, input_item in enumerate(input_files):
        output_item = output_files[idx]
        ok = filecmp.cmp(input_item, output_item)
        if not ok:
            with open(input_item, "r") as f1:
                input_lines = f1.readlines()
            with open(output_item, "r") as f2:
                output_lines = f2.readlines()
            with open(f"/tmp/expected-{idx}.txt", "w") as f3:
                f3.writelines(output_lines)
            with open(f"/tmp/generated-{idx}.txt", "w") as f4:
                f4.writelines(input_lines)
        assert ok
