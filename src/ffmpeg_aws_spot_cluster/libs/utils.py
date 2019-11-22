from pathlib import Path


def remove_file(fpath: Path):
    try:
        fpath.unlink()
    except FileNotFoundError:
        pass
