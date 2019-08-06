#!/bin/bash
export kitname=IRIS-2019.1.0.510.0-lnxubuntux64.tar.gz
export icmname=myicm
export icmimg=docker.iscinternal.com/intersystems/icm:2019.1.0.510.0-2

if [ ! -e $kitname ]; then
  echo "Kit $kitname doesn't exist."
  exit 1
fi
if [ ! -e iris.key ]; then
  echo "License key (iris.key) doesn't exist."
  exit 1
fi
if [ ! -e ~/.aws/credentials ]; then
  echo "AWS credential doesn't exist."
  exit 1
fi

# Don't re-use the container
docker stop $icmname
docker rm $icmname

docker run -d --name $icmname $icmimg tail -f /dev/null
docker exec $icmname sh -c "keygenTLS.sh; keygenSSH.sh"
docker exec $icmname mkdir -p /Samples/license/ubuntu/ShardMaster/

docker cp $kitname $icmname:/root
docker cp aws/ubuntu/defaults.json myicm:/Samples/AWS/
# pick a definitions.json to use here.
docker cp aws/ubuntu/definitions-shard.json myicm:/Samples/AWS/definitions.json

# need to aquire a valid aws credential beforehand
docker cp ~/.aws/credentials $icmname:/Samples/AWS/credentials
#; place your valid license key here
docker cp iris.key $icmname:/Samples/license/ubuntu/ShardMaster/

docker exec $icmname sh -c "cd /Samples/AWS; icm provision; icm scp -localPath /root/$kitname -remotePath /tmp; icm install"

# try to get private IPs
# ICM uses public ip for shard members. I want to avoid it.
docker exec $icmname sh -c "cd /Samples/AWS; icm ps -json > /dev/null; cat response.json" > res.json
docker exec $icmname sh -c "cd /Samples/AWS; icm ps -json > /dev/null; cat response.json" | python3 decode-pubip.py > pubip.txt

rm cmd.sh
while read line
do
    printf "docker exec myicm sh -c \"ssh -i /Samples/ssh/insecure -oStrictHostKeyChecking=no ubuntu@$line 'curl -s http://169.254.169.254/latest/meta-data/local-ipv4'; echo ''\"\n" >> cmd.sh
done < ./pubip.txt
./cmd.sh > privateip.txt

# copy ip infos to DM to run helper routine which deassigns/assigns shards.
docker cp pubip.txt $icmname:/root
docker cp privateip.txt $icmname:/root
docker cp helper.mac $icmname:/root
docker cp reassign-shard.sh $icmname:/root
docker exec $icmname /root/reassign-shard.sh

# install app classes
docker cp install-apps.sh $icmname:/root
docker cp icmcl-atelier-prj $icmname:/root
docker exec $icmname /root/install-apps.sh
# verification
ip=$(docker exec $icmname sh -c "cd /Samples/AWS; icm ps -json > /dev/null; cat response.json" | python3 decode-dmname.py)
curl -H "Content-Type: application/json; charset=UTF-8" -H "Accept:application/json" "http://$ip:52773/csp/myapp/get" --user "SuperUser:sys"