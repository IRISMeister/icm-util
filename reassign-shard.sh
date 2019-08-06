#!/bin/sh
cd /Samples/AWS
icm scp -role DM -localPath /root/pubip.txt -remotePath /tmp
icm scp -role DM -localPath /root/privateip.txt -remotePath /tmp
icm scp -role DM -localPath /root/helper.mac -remotePath /tmp
icm session -namespace MYAPP -role DM -command 'D $SYSTEM.OBJ.Load("/tmp/helper.mac","ck")'
icm session -namespace MYAPP -role DM -command 'D ^helper'
