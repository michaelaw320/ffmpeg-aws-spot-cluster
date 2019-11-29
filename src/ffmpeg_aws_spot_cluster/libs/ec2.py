import boto3
import requests

INSTANCE_ID_ENDPOINT = "http://169.254.169.254/latest/meta-data/instance-id"
REGION_ENDPOINT = "http://169.254.169.254/latest/dynamic/instance-identity/document"


def cancel_spot_request():
    region = requests.get(REGION_ENDPOINT).json()["region"]
    instance_id = requests.get(INSTANCE_ID_ENDPOINT).text
    client = boto3.client("ec2", region_name=region)
    instance = boto3.resource("ec2", region_name=region).Instance(instance_id)
    spot_request_id = instance.spot_instance_request_id
    client.cancel_spot_instance_requests(
        DryRun=False, SpotInstanceRequestIds=[spot_request_id,]
    )
    instance.terminate()
