from setuptools import setup, find_packages

setup(
    name="ffmpeg-aws-spot-cluster",
    version="0.0.1",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    entry_points={
        "console_scripts": [
            "hello-world = hello_world.cli:main",
        ],
    },
    install_requires=[
        "boto3",
    ],
)
