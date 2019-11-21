import os
import time
from multiprocessing import Pool
from pathlib import PurePath, Path
from typing import List

import attr
import click
from ffmpeg_aws_spot_cluster.libs.config import (
    ClusterConfig,
    load_cluster_config,
    load_encoder_config,
)
from ffmpeg_aws_spot_cluster.libs.s3 import S3, S3Object, S3Path


WORKING_INPUT_DIR = "workingInput"
WORKING_OUTPUT_DIR = "workingOutput"


def build_node_joblist(cluster_config: ClusterConfig, s3_client: S3) -> List[S3Object]:
    all_files = s3_client.ls_sorted(cluster_config.input_s3_path)
    this_node_files = all_files[cluster_config.node_num :: cluster_config.total_nodes]
    return this_node_files


def do_in_child_process(job: S3Object):
    cluster_config = load_cluster_config()
    encoder_config = load_encoder_config()
    job_path_without_prefix = job.path.key.replace(cluster_config.input_s3_path.key, "")
    input_file = Path(
        cluster_config.workdir, WORKING_INPUT_DIR, job_path_without_prefix
    )
    output_file = Path(
        cluster_config.workdir, WORKING_OUTPUT_DIR, job_path_without_prefix
    ).with_suffix(encoder_config.output_container)
    output_s3_path = attr.evolve(
        cluster_config.output_s3_path,
        key=str(
            PurePath(
                cluster_config.output_s3_path.key, job_path_without_prefix
            ).with_suffix(encoder_config.output_container)
        ),
    )
    print(
        f"{'='*15}Child{'='*15}\n"
        f"Cluster Configuration: {cluster_config}\n"
        f"Encoder Configuration: {encoder_config}\n"
        f"Processing File: {job}\n"
        f"Will Download to: {os.fspath(input_file)}\n"
        f"Output File will be: {os.fspath(output_file)}\n"
        f"Will be on S3: {output_s3_path}\n"
        f"{'='*35}\n"
    )
    s3 = S3()
    input_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    print("Downloading")
    s3.download_file(job.path, input_file)
    print("Copying")
    from shutil import copyfile

    copyfile(os.fspath(input_file), os.fspath(output_file))
    print("Uploading")
    s3.upload_file(output_file, output_s3_path)


@click.command()
def main():
    print("Loading ClusterConfig")
    cluster_config = load_cluster_config()
    print(f"Cluster configuration: {cluster_config}")
    print(f"Building Joblist...")
    s3 = S3()
    joblist = build_node_joblist(cluster_config, s3)
    print(f"This node joblist: {joblist}")
    print(f"Preparing working directories...")
    Path(cluster_config.workdir, WORKING_INPUT_DIR).mkdir(parents=True, exist_ok=True)
    Path(cluster_config.workdir, WORKING_OUTPUT_DIR).mkdir(parents=True, exist_ok=True)
    with Pool(processes=cluster_config.process_pool) as pool:
        pool.map(do_in_child_process, joblist)
    print("Done")


if __name__ == "__main__":
    main()
