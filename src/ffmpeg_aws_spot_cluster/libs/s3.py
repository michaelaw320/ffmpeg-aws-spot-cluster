import os
from pathlib import Path
from urllib.parse import urlparse

import attr
import boto3


@attr.s(frozen=True, auto_attribs=True)
class S3Path:
    bucket: str
    key: str = ""


def parse_s3_path(s3_path: str) -> S3Path:
    """
    Parse s3 path s3://bucket/prefix/key
    :return: S3Path
    """
    if not s3_path.startswith("s3://"):
        raise ValueError("Not an S3 Path")
    parsed = urlparse(s3_path)
    bucket = parsed.netloc
    key = parsed.path[1:]
    return S3Path(bucket=bucket, key=key)


@attr.s(frozen=True, auto_attribs=True)
class S3Object:
    path: S3Path
    size: int


@attr.s(frozen=True)
class S3:
    client = boto3.client("s3")

    def ls(self, path: S3Path):
        kwargs = {"Bucket": path.bucket, "Prefix": path.key}
        while True:
            response = self.client.list_objects_v2(**kwargs)
            for content in response["Contents"]:
                o = S3Object(
                    path=S3Path(bucket=path.bucket, key=content["Key"]),
                    size=content["Size"],
                )
                if o.size:
                    # Include only non 0 files
                    yield o
            try:
                kwargs["ContinuationToken"] = response["NextContinuationToken"]
            except KeyError:
                break

    def ls_sorted(self, path: S3Path):
        """
        ls s3 sorted by size ascending
        """
        return sorted([obj for obj in self.ls(path)], key=lambda obj: obj.size)

    def download_file(self, s3_path: S3Path, fs_path: Path):
        fs_path.parent.mkdir(parents=True, exist_ok=True)
        with fs_path.open("wb+") as data:
            self.client.download_fileobj(s3_path.bucket, s3_path.key, data)

    def upload_file(self, fs_path: Path, s3_path: S3Path):
        with fs_path.open("rb") as data:
            self.client.upload_fileobj(data, s3_path.bucket, s3_path.key)
