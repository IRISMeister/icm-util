#!/bin/sh
if [ $# -ne 1 ]; then
 cd /Samples/AWS
else 
 cd $1
fi

icm scp -role DM -localPath /root/icmcl-atelier-prj/ -remotePath /tmp
icm session -namespace MYAPP -role DM -command 'D $SYSTEM.OBJ.Load("/tmp/MyApps/Installer.cls","ck") D ##class(MyApps.Installer).setup()'