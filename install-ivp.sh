#!/bin/sh
cd $1
targetmachine=$2

icm ssh -machine $targetmachine -command "mkdir -p /tmp/prj"
icm scp -machine $targetmachine -localPath /root/icmcl-atelier-prj/ -remotePath /tmp/prj
# following command start failing....since 2019.3?
# icm session -namespace USER -role DM -command 'D $SYSTEM.OBJ.Load("/tmp/prj/MyApps/Installer.cls","ck") D ##class(MyApps.Installer).setup()'
icm ssh -machine $targetmachine -command '/bin/echo -e "D ##class(%SYSTEM.OBJ).Load(\"/tmp/prj/MyApps/Installer.cls\",\"ck\") D ##class(MyApps.Installer).setup() Halt" | sudo iris session IRIS -U USER'
