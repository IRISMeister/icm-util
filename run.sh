#!/bin/bash -e
source envs.sh

defaultspath=$defaultsroot/$provider/$targetos
#use Label as a container name
icmname=$(cat $defaultspath/$defaults | jq -r '.Label')

# Is this Containerless or not?
isContainerless=$(cat $defaultspath/$defaults | jq -r '.Containerless')

if [ $isContainerless = "true" ]; then
  if [ ! -e kits/$kitname ]; then
    echo "Kit $kitname doesn't exist."
    exit 1
  fi
fi

if [ $provider = "aws" ]; then
  if [ ! -e ~/.aws/credentials ]; then
    echo "AWS credential doesn't exist."
    exit 1
  fi
fi

if [ ! -e $defaultspath/$defaults ]; then
    echo "Requested defaults.json files doesn't exist."
    exit 1
fi

if [ ! -e definitions/$definitions ]; then
    echo "Requested definitions.json files doesn't exist."
    exit 1
fi

if [ $isContainerless = "true" ]; then
  iriskey=iris.key
else
  iriskey=iris-container.key
fi

if [ ! -e license/$iriskey ]; then
  echo "License key (iris.key) doesn't exist."
  exit 1
fi

# Don't re-use the container
docker stop $icmname | true
docker rm $icmname | true

docker run -d --name $icmname $icmimg tail -f /dev/null
docker exec $icmname sh -c "keygenTLS.sh; keygenSSH.sh"
docker exec $icmname mkdir -p /Production/license

if [ $isContainerless = "true" ]; then
  docker cp kits/$kitname $icmname:/root
fi
docker exec $icmname mkdir -p $icmdata
docker exec $icmname sh -c "echo $icmdata > dir.txt"

# replacing kitname if Containerless
if [ $isContainerless = "true" ]; then
  cat $defaultspath/$defaults | jq '.KitURL = "file://tmp/'$kitname'"' > actual-$defaults
  docker cp actual-$defaults $icmname:$icmdata/defaults.json
  rm -f actual-$defaults
else
  docker cp $defaultspath/$defaults $icmname:$icmdata/defaults.json
fi
# pick a definitions.json to use here.
docker cp definitions/$definitions $icmname:$icmdata/definitions.json

# pick a merge-cpf file to use here.
docker exec $icmname mkdir -p /Production/mergefiles
docker cp $cpffile $icmname:/Production/mergefiles/merge.cpf

# need to aquire a valid aws credential beforehand
if [ $provider = "aws" ]; then
  docker cp ~/.aws/credentials $icmname:$icmdata/credentials
fi
#; copy a license key here
docker cp license/$iriskey $icmname:/Production/license/iris.key

if [ $isContainerless = "true" ]; then
  docker exec $icmname sh -c "cd $icmdata; icm provision; icm scp -localPath /root/$kitname -remotePath /tmp; icm install"
else
  docker exec $icmname sh -c "cd $icmdata; icm provision; icm run"
  #docker exec $icmname sh -c "cd $icmdata; icm provision --verbose -force; icm run --verbose -force"
fi

rm -fR ./Backup/$icmname/*
mkdir ./Backup/$icmname
# save ssh/tls folder(s) to local, just in case.
docker cp $icmname:/Samples/ssh/ ./Backup/$icmname/ssh
docker cp $icmname:/Samples/tls/ ./Backup/$icmname/tls
# save Production folder(s) to local, just in case.
docker cp $icmname:/$icmdata/ ./Backup/$icmname/

# ssh private key causes protection issue on windows filesystem via wsl. So copy it to ~/.
cp ./Backup/$icmname/ssh/insecure ~/insecure_$icmname
chmod 600 ~/insecure_$icmname

inventory=Backup/$icmname/inventory.json
ps=Backup/$icmname/ps.json

docker exec $icmname sh -c "cd $icmdata; icm inventory -json > /dev/null; cat response.json" > $inventory
docker exec $icmname sh -c "cd $icmdata; icm ps -json > /dev/null; cat response.json" > $ps

# install ivp app classes, if Containerless
if [ $isContainerless = "true" ]; then
  ip=$(cat $inventory | jq -r '.[] | select(.Role == "BH") | .DNSName')
  targetmachine=$(cat $inventory | jq -r '.[] | select(.Role == "BH") | .MachineName')
  if [ -z "$ip" ]; then
    ip=$(cat $inventory | jq -r '.[] | select(.Role == "DM") | .DNSName')
    targetmachine=$(cat $inventory | jq -r '.[] | select(.Role == "DM") | .MachineName')
  fi
  if [ -z "$ip" ]; then
    ip=$(cat $inventory | jq -r '.[0] | select(.Role == "DATA") | .DNSName')
    targetmachine=$(cat $inventory | jq -r '.[0] | select(.Role == "DATA") | .MachineName')
  fi

  docker cp install-ivp.sh $icmname:/root
  docker cp icmcl-atelier-prj $icmname:/root
  docker exec $icmname /root/install-ivp.sh $icmdata $targetmachine

  echo "Accessing "$ip
  curl -H "Content-Type: application/json; charset=UTF-8" -H "Accept:application/json" "http://$ip:52773/csp/myapp/get" --user "SuperUser:sys"
fi

# Run user script if exists.
if [ -e install-apps-user.sh ]; then
  ./install-apps-user.sh $icmname $icmdata $targetmachine $ip
fi

echo "Container ["$icmname"] has been created. To unprovision all resources, execute ./rm.sh "$icmname
docker exec $icmname sh -c "cd $icmdata; icm inventory"
docker exec $icmname sh -c "cd $icmdata; icm ps"
