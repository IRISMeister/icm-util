#!/bin/bash -e
if [ $# -ne 1 ]; then
  echo "rm.sh containerName"
  exit 1
fi

containerName=$1

# cleanup cloud resources
docker exec $containerName sh -c 'cd $(cat dir.txt); icm unprovision -cleanUp -force; rm *.log'
docker stop $containerName
docker rm $containerName

# remove backup files
defaultspath=$defaultsroot/$provider/$targetos
icmname=$(cat $defaultspath/$defaults | jq -r '.Label')
rm -fR ./Backup/$icmname

# remove a ssh key file
rm -f ~/insecure_$icmname

