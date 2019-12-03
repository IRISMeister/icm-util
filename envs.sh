#!/bin/bash
export icmimg=intersystems/icm:2019.4.0.379.0
#export icmimg=intersystems/icm:2019.3.0.309.0
#export icmimg=intersystems/icm:2019.1.0.510.4
#export icmimg=intersystems/icm:2019.2.0.109.0

export icmname=myicm
export iriskey=iris-normal.key

export kitname=IRIS-2019.4.0.379.0-lnxrhx64.tar.gz
#export kitname=IRIS-2019.3.0.309.0-lnxrhx64.tar.gz
#export kitname=IRIS-2019.1.0.510.4-lnxrhx64.tar.gz
#export kitname=IRIS-2019.1.0.510.4-lnxubuntux64.tar.gz

export defaults=defaults-dont-upload.json
#export defaults=defaults.json

export definitions=definitions-shard.json
#export definitions=definitions-standalone.json

# aws, azure
export provider=azure
# centos,ubuntu.redhat
export targetos=redhat
export icmdata=/Production/$provider
