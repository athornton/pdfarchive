import shutil
from pathlib import Path

import pytest

_here = Path(__file__).parent


@pytest.fixture(scope="session")
def src_testdata() -> Path:
    return Path(_here / "testdata")


@pytest.fixture(scope="session")
def testdata(tmp_path_factory: pytest.TempPathFactory) -> Path:
    srcdir = Path(_here / "testdata" / "input")
    testdir = tmp_path_factory.mktemp("testdata")
    shutil.copytree(srcdir, testdir, dirs_exist_ok=True)
    return testdir
