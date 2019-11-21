from typing import List

import click
from ffmpeg_aws_spot_cluster.libs.config import ClusterConfig, load_cluster_config
from ffmpeg_aws_spot_cluster.libs.s3 import S3, S3Object


def build_node_joblist(cluster_config: ClusterConfig, s3_client: S3) -> List[S3Object]:
    all_files = s3_client.ls_sorted(cluster_config.input_s3_path)
    this_node_files = all_files[cluster_config.node_num :: cluster_config.total_nodes]
    return this_node_files


@click.command()
def main():
    print("Loading ClusterConfig")
    cluster_config = load_cluster_config()
    s3 = S3()
    print(f"Cluster configuration: {cluster_config}")
    joblist = build_node_joblist(cluster_config, s3)
    print(f"This node joblist: {joblist}")


if __name__ == "__main__":
    main()
