#!/bin/bash
export icm=myicm

# cleanup cloud resources
docker exec $icm sh -c "cd /Samples/AWS; icm unprovision -cleanUp -force; rm *.log"
docker stop $icm
docker rm $icm