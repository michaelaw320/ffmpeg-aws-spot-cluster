from functools import wraps
from pathlib import Path


class Retry(Exception):
    pass


def remove_file(fpath: Path):
    try:
        fpath.unlink()
    except FileNotFoundError:
        pass


def retry(f):
    @wraps(f)
    def wrapped(*args, **kwargs):
        for retcnt in range(0, 3):
            try:
                return f(*args, **kwargs)
            except Retry:
                pass

    return wrapped
