from setuptools import setup, find_packages

setup(
    name="ffmpeg-aws-spot-cluster",
    version="0.0.1",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    entry_points={
        "console_scripts": [
            "start-encode = ffmpeg_aws_spot_cluster.cmds.main:main",
        ],
    },
    install_requires=[
        "boto3",
        "click",
        "attrs",
    ],
)
