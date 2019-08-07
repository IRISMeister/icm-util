#!/bin/bash
export icmimg=docker.iscinternal.com/intersystems/icm:2019.1.0.510.0-2
export icmname=myicm
export kitname=IRIS-2019.1.0.510.0-lnxubuntux64.tar.gz
# aws, azure
export provider=azure
export icmdata=/Production/$provider
