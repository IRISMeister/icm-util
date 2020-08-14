#!/bin/bash -e
if [ $# -ne 1 ]; then
  echo "rm.sh containerName"
  exit 1
fi

icmname=$1

# cleanup cloud resources
docker exec $icmname sh -c 'cd $(cat dir.txt); icm unprovision -cleanUp -force; rm *.log'
docker stop $icmname
docker rm $icmname

# remove external data
echo "Removing ./icm_data/$provider/$icmname"
sudo rm -fR icm_data/$provider/$icmname
