#!/bin/bash

export icmimg=intersystems/icm:2020.1.0.215.0
#export icmimg=intersystems/icm:2019.4.0.383.0
#export icmimg=intersystems/icm:2019.3.0.311.0
#export icmimg=intersystems/icm:2019.2.0.109.0
#export icmimg=intersystems/icm:2019.1.1.612.0

export kitname=IRIS-2020.1.0.215.0-lnxubuntux64.tar.gz
#export kitname=IRIS-2019.4.0.382.0-lnxubuntux64.tar.gz
#export kitname=IRIS-2019.4.0.382.0-lnxrhx64.tar.gz
#export kitname=IRIS-2019.3.0.310.0-lnxrhx64.tar.gz
#export kitname=IRIS-2019.1.1.612.0-lnxrhx64.tar.gz

#export provider=azure
export provider=aws

#export targetos=centos
#export targetos=redhat
export targetos=ubuntu

export defaultsroot=defaults
#export defaultsroot=defaults-dont-upload

export defaults=defaults.json
#export defaults=defaults-container.json
#export defaults=defaults-mirror.json

export definitions=definitions.json
#export definitions=definitions-bh.json
#export definitions=definitions-mirror.json
#export definitions=definitions-shard.json
#export definitions=definitions-shard-node.json

#export cpffile=UserCPF/merge.cpf
export cpffile=UserCPF/merge-min.cpf

export restoreExistingEnv=true

# ------------------------------
# do not touch below lines
export icmdata=/Production/$provider

export defaultspath=$defaultsroot/$provider/$targetos
#use Label as a container name
export icmname=$(cat $defaultspath/$defaults | jq -r '.Label')
# Is this Containerless or not?
export isContainerless=$(cat $defaultspath/$defaults | jq -r '.Containerless')

