import os
import shlex
import subprocess
import sys
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
from ffmpeg_aws_spot_cluster.libs.ec2 import cancel_spot_request
from ffmpeg_aws_spot_cluster.libs.s3 import S3, S3Object
from ffmpeg_aws_spot_cluster.libs.utils import remove_file, retry, Retry

WORKING_INPUT_DIR = "workingInput"
WORKING_OUTPUT_DIR = "workingOutput"
LOGS_DIR = "/tmp/logs"


def build_node_joblist(cluster_config: ClusterConfig, s3_client: S3) -> List[S3Object]:
    all_files = s3_client.ls_sorted(cluster_config.input_s3_path)
    this_node_files = all_files[cluster_config.node_num :: cluster_config.total_nodes]
    return this_node_files


@retry
def do_in_child_process(job: S3Object):
    child_num = os.getpid()
    cluster_config = load_cluster_config()
    encoder_config = load_encoder_config()

    job_path_without_prefix = job.path.key.replace(cluster_config.input_s3_path.key, "")
    input_file = Path(
        encoder_config.working_directory, WORKING_INPUT_DIR, job_path_without_prefix
    )
    output_file = Path(
        encoder_config.working_directory, WORKING_OUTPUT_DIR, job_path_without_prefix
    ).with_suffix(encoder_config.output_extension)
    log_file = Path(LOGS_DIR, job_path_without_prefix).with_suffix(".txt")

    output_s3_path = attr.evolve(
        cluster_config.output_s3_path,
        key=str(
            PurePath(
                cluster_config.output_s3_path.key, job_path_without_prefix
            ).with_suffix(encoder_config.output_extension)
        ),
    )
    output_s3_log = attr.evolve(
        output_s3_path, key=str(PurePath(output_s3_path.key).with_suffix(".txt"))
    )
    input_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    log_file.parent.mkdir(parents=True, exist_ok=True)
    s3 = S3()

    with log_file.open("a+") as log:
        sys.stdout = log
        sys.stderr = log
        try:
            print(
                f"{'='*15}Child {child_num}{'='*15}\n"
                f"Cluster Configuration: {cluster_config}\n"
                f"Encoder Configuration: {encoder_config}\n"
                f"Processing File: {job}\n"
                f"Will Download to: {os.fspath(input_file)}\n"
                f"Output File will be: {os.fspath(output_file)}\n"
                f"Will be on S3: {output_s3_path}\n"
                f"{'='*35}\n"
            )

            print(f"[{child_num}] Downloading")
            s3.download_file(job.path, input_file)

            cmd = (
                f"{cluster_config.ffmpeg_bin_path} "
                f"-y -nostdin "
                f"{encoder_config.ffmpeg_options if encoder_config.ffmpeg_options else ''} "
                f"{encoder_config.infile_options if encoder_config.infile_options else ''} "
                f"-i '{input_file}' "
                f"{encoder_config.video_options} "
                f"{encoder_config.audio_options} "
                f"{encoder_config.outfile_options if encoder_config.outfile_options else ''} "
                f"'{output_file}'"
            )
            args = shlex.split(cmd)
            print(f"[{child_num}] Encoding... invoking subprocess with args {args}\n\n")
            start_time = time.monotonic()
            sys.stdout.flush()
            sys.stderr.flush()
            subprocess.run(args, stdout=log, stderr=log)
            print(f"\n\nTook {time.monotonic()-start_time} seconds to encode\n\n")

            print(f"[{child_num}] Uploading")
            s3.upload_file(output_file, output_s3_path)

            print(
                f"[{child_num}] Deleting temporary working files:\n {input_file}\n {output_file}\n"
            )
            remove_file(input_file)
            remove_file(output_file)
        except Exception as e:
            log.write(f"Exception Happened: {e}\n\n")
            raise Retry()
    try:
        s3.upload_file(log_file, output_s3_log)
    except:
        pass


@click.command()
def main():
    print("Loading ClusterConfig")
    cluster_config = load_cluster_config()
    print(f"Cluster configuration: {cluster_config}")
    print("Loading EncoderConfig")
    encoder_config = load_encoder_config()
    print(f"Encoder configuration: {encoder_config}")
    print(f"Building Joblist...")
    s3 = S3()
    joblist = build_node_joblist(cluster_config, s3)
    print(f"This node joblist: {joblist}")
    print(f"Preparing working directories...")
    Path(encoder_config.working_directory, WORKING_INPUT_DIR).mkdir(
        parents=True, exist_ok=True
    )
    Path(encoder_config.working_directory, WORKING_OUTPUT_DIR).mkdir(
        parents=True, exist_ok=True
    )
    Path(LOGS_DIR).mkdir(parents=True, exist_ok=True)
    with Pool(processes=encoder_config.encoder_process) as pool:
        print(f"Started {encoder_config.encoder_process} Process as Pool")
        pool.map(do_in_child_process, joblist)

    cancel_spot_request()
    print("Done")


if __name__ == "__main__":
    main()
