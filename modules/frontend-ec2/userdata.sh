#!/bin/bash

exec > /var/log/userdata.log 2>&1

echo "Starting Frontend Setup"

apt update -y

apt install docker.io git -y

systemctl start docker
systemctl enable docker

cd /home/ubuntu

git clone https://github.com/abhaysahu403/talentforge-frontend.git

cd talentforge-frontend

docker build -t talentforge-frontend .

docker run -d \
--name talentforge-frontend \
-p 3000:3000 \
--restart always \
talentforge-frontend

echo "Frontend Setup Complete"