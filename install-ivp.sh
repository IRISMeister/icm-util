#!/bin/sh
if [ $# -ne 1 ]; then
 cd /Production/AWS
else 
 cd $1
fi

icm ssh -role DM -command "mkdir -p /tmp/prj"
icm scp -role DM -localPath /root/icmcl-atelier-prj/ -remotePath /tmp/prj
# following command start failing....since 2019.3?
# icm session -namespace USER -role DM -command 'D $SYSTEM.OBJ.Load("/tmp/prj/MyApps/Installer.cls","ck") D ##class(MyApps.Installer).setup()'
icm ssh -role DM -command '/bin/echo -e "D ##class(%SYSTEM.OBJ).Load(\"/tmp/prj/MyApps/Installer.cls\",\"ck\") D ##class(MyApps.Installer).setup() Halt" | sudo iris session IRIS -U USER'