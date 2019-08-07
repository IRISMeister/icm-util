#!/bin/bash
source envs.sh

# cleanup cloud resources
docker exec $icmname sh -c "cd $icmdata; icm unprovision -cleanUp -force; rm *.log"
docker stop $icmname
docker rm $icmname