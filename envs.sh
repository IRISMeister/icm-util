#!/bin/bash
export icmimg=intersystems/icm:2019.1.0.510.4
export icmname=myicm
export kitname=IRIS-2019.1.0.510.4-lnxrhx64.tar.gz
#export kitname=IRIS-2019.1.0.510.4-lnxubuntux64.tar.gz
export defaults=defaults-container-dont-upload.json
# aws, azure
export provider=azure
# centos,ubuntu.redhat
export targetos=ubuntu
export icmdata=/Production/$provider
