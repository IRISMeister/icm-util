#!/bin/bash -e
source envs.sh

if [ ! -e license/$iriskey ]; then
  echo "License key (iris.key) doesn't exist."
  exit 1
fi

if [ $provider = "aws" ]; then
  if [ ! -e ~/.aws/credentials ]; then
    echo "AWS credential doesn't exist."
    exit 1
  fi
fi

if [ ! -d $provider/$targetos ]; then
    echo "json files directory doesn't exist."
    exit 1
fi

# Is this Containerless or not?
isContainerless=$(cat $provider/$targetos/$defaults | python3 -c 'import json,sys; print (json.load(sys.stdin)["Containerless"])')
if [ $isContainerless = "true" ]; then
  if [ ! -e kits/$kitname ]; then
    echo "Kit $kitname doesn't exist."
    exit 1
  fi
fi

rm -f privateip-ds.txt 
rm -f pubip-ds.txt
rm -f privateip-all.txt
rm -f pubip-all.txt
rm -f inventory.json
rm -f ps.json
rm -f cmd-ds.sh

# Don't re-use the container
docker stop $icmname | true
docker rm $icmname | true

docker run -d --name $icmname $icmimg tail -f /dev/null
docker exec $icmname sh -c "keygenTLS.sh; keygenSSH.sh"
docker exec $icmname mkdir -p /Production/license

docker cp kits/$kitname $icmname:/root
docker exec $icmname mkdir -p $icmdata

# replacing kitname 
if [ $isContainerless = "true" ]; then
  cat $provider/$targetos/$defaults | jq '.KitURL = "file://tmp/'$kitname'"' > real-$defaults
  docker cp real-$defaults $icmname:$icmdata/defaults.json
else
  docker cp $provider/$targetos/$defaults $icmname:$icmdata/defaults.json
fi
# pick a definitions.json to use here.
docker cp definitions/$definitions $icmname:$icmdata/definitions.json

# need to aquire a valid aws credential beforehand
if [ $provider = "aws" ]; then
  docker cp ~/.aws/credentials $icmname:$icmdata/credentials
fi
#; place your valid license key here
docker cp license/$iriskey $icmname:/Production/license/iris.key

if [ $isContainerless = "true" ]; then
  docker exec $icmname sh -c "cd $icmdata; icm provision; icm scp -localPath /root/$kitname -remotePath /tmp; icm install"
else
  docker exec $icmname sh -c "cd $icmdata; icm provision; icm run"
fi

rm -fR ./Backup/*
# save ssh/tls folder(s) to local, just in case.
docker cp $icmname:/Samples/ssh/ ./Backup/ssh
docker cp $icmname:/Samples/tls/ ./Backup/tls
# save Production folder(s) to local, just in case.
docker cp $icmname:/$icmdata/ ./Backup/

# private key causes protection issue on windows filesystem via wsl. So copy it to ~/.
cp ./Backup/ssh/insecure ~/

docker exec $icmname sh -c "cd $icmdata; icm inventory -json > /dev/null; cat response.json" > inventory.json
docker exec $icmname sh -c "cd $icmdata; icm ps -json > /dev/null; cat response.json" > ps.json
# ++ containerless ICM uses public ip for shard members. I want to avoid it. ++
# Since 2019.4, it uses internal IPs.
# try to get private IPs
if [ $forceinternalip = "1" ]; then
  docker exec $icmname sh -c "cd $icmdata; icm ps -json > /dev/null; cat response.json" | python3 decode-pubip-ds.py > pubip-ds.txt
  # get SSHUser
  sshusername=$(cat $provider/$targetos/$defaults | python3 -c 'import json,sys; print (json.load(sys.stdin)["SSHUser"])')
  if [ $targetos = "ubuntu" ]; then
    ip=ip
  fi
  if [ $targetos = "centos" ]; then
    ip=/usr/sbin/ip
  fi
  if [ $targetos = "redhat" ]; then
    ip=/usr/sbin/ip
  fi

  if [ -e cmd-ds.sh ]; then
    rm cmd-ds.sh
  fi
  while read hostipaddress
  do
    if [ $provider = "aws" ]; then
      printf "docker exec $icmname sh -c \"ssh -i /Samples/ssh/insecure -oStrictHostKeyChecking=no $sshusername@$hostipaddress 'curl -s http://169.254.169.254/latest/meta-data/local-ipv4'; echo ''\"\n" >> cmd-ds.sh
    fi
    if [ $provider = "azure" ]; then
      printf "docker exec myicm sh -c \"ssh -i /Samples/ssh/insecure -oStrictHostKeyChecking=no $sshusername@$hostipaddress $ip -4 -br a show dev eth0 | awk '{ print \\\$3}' | awk -F'/' '{ print \\\$1 }'\"\n" >> cmd-ds.sh
    fi
  done < ./pubip-ds.txt
  if [ -e cmd-ds.sh ]; then
    chmod +x cmd-ds.sh
    ./cmd-ds.sh > privateip-ds.txt
    # copy ip infos to DM to run helper routine which deassigns/assigns shards.
    docker cp pubip-ds.txt $icmname:/root
    docker cp privateip-ds.txt $icmname:/root
    docker cp helper.mac $icmname:/root
    docker cp reassign-shard.sh $icmname:/root
    docker exec $icmname /root/reassign-shard.sh $icmdata
  fi
fi
# -- containerless ICM uses public ip for shard members. I want to avoid it. --

# install ivp app classes, if Containerless
if [ $isContainerless = "true" ]; then
  docker cp install-ivp.sh $icmname:/root
  docker cp icmcl-atelier-prj $icmname:/root
  docker exec $icmname /root/install-ivp.sh $icmdata
  ip=$(docker exec $icmname sh -c "cd $icmdata; icm ps -json > /dev/null; cat response.json" | python3 decode-dmname.py)
  curl -H "Content-Type: application/json; charset=UTF-8" -H "Accept:application/json" "http://$ip:52773/csp/myapp/get" --user "SuperUser:sys"
fi

# Assuming no need to do this for container version because apps come along.
if [ -e install-apps-user.sh ]; then
  ./install-apps-user.sh $icmdata
fi
