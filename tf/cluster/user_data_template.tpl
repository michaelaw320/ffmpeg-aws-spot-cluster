#!/bin/bash

/usr/bin/enable-ec2-spot-hibernation
yum update -y
yum install -y python3 git
curl -L https://bootstrap.pypa.io/get-pip.py | python3

mkdir -p /root/ffmpeg-bin
# If custom ffmpeg bin on s3 is specified use that else fetch latest from johnvansickle.com
if [ ! -z "${s3_ffmpeg_bin_path}" ]; then
  aws s3 cp ${s3_ffmpeg_bin_path} /root/ffmpeg-bin/ffmpeg
else
  curl "https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz" --output /root/ffmpeg-bin/ffmpeg.tar.xz
  tar -xvf /root/ffmpeg-bin/ffmpeg.tar.xz --strip-components=1 -C /root/ffmpeg-bin/
fi
chmod +x /root/ffmpeg-bin/ffmpeg

git clone -b ${source_code_branch} ${source_code_repository} /root/ffmpeg-aws
python3 -m venv /root/env
/root/env/bin/pip install -U pip setuptools wheel
/root/env/bin/pip install /root/ffmpeg-aws
/root/env/bin/python --version
cat > /root/cluster-config.json << EOF
{
    "node_num": ${node_num},
    "total_nodes": ${total_node},
    "input_s3_path": "${input_s3_path}",
    "output_s3_path": "${output_s3_path}",
    "ffmpeg_bin_path": "/root/ffmpeg-bin/ffmpeg"
}
EOF
aws s3 cp ${encoder_setting_s3_path} /root/encoder-config.json
nohup /root/env/bin/start-encode &
jobs
disown
