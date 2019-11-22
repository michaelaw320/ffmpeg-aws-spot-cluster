import json
import os
from json import JSONDecodeError

import attr
from ffmpeg_aws_spot_cluster.libs.s3 import S3Path, parse_s3_path


@attr.s(frozen=True, auto_attribs=True)
class ClusterConfig:
    node_num: int
    total_nodes: int
    input_s3_path: S3Path = attr.ib(converter=parse_s3_path)
    output_s3_path: S3Path = attr.ib(converter=parse_s3_path)


@attr.s(frozen=True, auto_attribs=True)
class EncoderConfig:
    video_options: str
    audio_options: str
    output_extension: str
    encoder_process: int = 1
    ffmpeg_options: str = ""
    infile_options: str = ""
    outfile_options: str = ""
    ffmpeg_bin_path: str = "ffmpeg"
    working_directory: str = "/root"


def load_cluster_config() -> ClusterConfig:
    """
    Reads configuration from predefined location `/root/cluster-config.json`
    or custom location defined by env var `CLUSTER_CONFIG_PATH`
    :return: ClusterConfig
    """
    if os.environ.get("CLUSTER_CONFIG_PATH"):
        fpath = os.environ["CLUSTER_CONFIG_PATH"]
    else:
        fpath = "/root/cluster-config.json"
    with open(fpath, "r") as f:
        try:
            content = json.loads(f.read())
            return ClusterConfig(**content)
        except JSONDecodeError:
            raise RuntimeError("Failed to load cluster config, check config file")


def load_encoder_config() -> EncoderConfig:
    """
    Reads configuration from predefined location `/root/encoder-config.json`
    or custom location defined by env var `ENCODER_CONFIG_PATH`
    :return: EncoderConfig
    """
    if os.environ.get("ENCODER_CONFIG_PATH"):
        fpath = os.environ["ENCODER_CONFIG_PATH"]
    else:
        fpath = "/root/encoder-config.json"
    with open(fpath, "r") as f:
        try:
            content = json.loads(f.read())
            return EncoderConfig(**content)
        except JSONDecodeError:
            raise RuntimeError("Failed to load encoder config, check config file")
