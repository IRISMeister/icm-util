#!/bin/sh
if [ $# -ne 1 ]; then
 cd /Samples/AWS
else 
 cd $1
fi

icm ssh -role DM -command "mkdir /tmp/prj"
icm scp -role DM -localPath /root/icmcl-atelier-prj/ -remotePath /tmp/prj
icm session -namespace USER -role DM -command 'D $SYSTEM.OBJ.Load("/tmp/prj/MyApps/Installer.cls","ck") D ##class(MyApps.Installer).setup()'