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

rm -f inventory.json
rm -f ps.json

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

# install ivp app classes, if Containerless
if [ $isContainerless = "true" ]; then
  docker cp install-ivp.sh $icmname:/root
  docker cp icmcl-atelier-prj $icmname:/root
  docker exec $icmname /root/install-ivp.sh $icmdata
  ip=$(cat inventory.json | jq -r '.[] | select(.Role == "BH") | .DNSName')
  curl -H "Content-Type: application/json; charset=UTF-8" -H "Accept:application/json" "http://$ip:52774/csp/myapp/get" --user "SuperUser:sys"
fi

# Assuming no need to do this for container version because apps come along.
if [ -e install-apps-user.sh ]; then
  ./install-apps-user.sh $icmdata
fi
