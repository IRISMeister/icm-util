# icm-util
Tested under V2019.4.0.379.0
To run  
./run.sh  
To remove  
./rm.sh containerName

You can use awscli.sh for AWS to see if any resoures are remained unexpectedly.  

**Do not leave value of "ISCPassword" in defaults.json as is !!!**

Disk size is defined by "DataVolumeSize": "1024" in defaults.json
Disk performance is constrained by Disk size + Disk type. See
https://docs.microsoft.com/ja-jp/azure/virtual-machines/windows/disks-types#premium-ssd

typical things to do next.  
```
cat inventory.json (to see IP addresses)

cp Backup/ssh/insecure ~
cd ~
chmod 700 insecure
ssh -i insecure ubuntu@ipaddress

```
(copy something from local PC)  
```
scp -r -i ~/insecure /mnt/c/temp/SpeedTestDemo ubuntu@ipaddress:/tmp
```
(copy something from remote)  
```
scp -i ~/insecure ubuntu@ipaddress:/irissys/data/IRIS/mgr/MyIRIS-DM-PROD-0001_IRIS_20190904_0558.mgst .
```
Useful commands  

Monitor database files I/O
```
iostat 1 -m -d -p /dev/sdd | grep sdd
```
Monitor WIJ I/O
```
iostat 1 -m -d -p /dev/sde | grep sde
```
Monitor database activity
```
%SYS>D ^mgstat(1)
```
Results will be stored at /irissys/data/IRIS/mgr/*.mgst

```
%SYS>D ^SystemPerformance
%SYS>D Stop^SystemPerformance("20111220_1327_12hours",0)
```
Results will be stored at /irissys/data/IRIS/mgr/*.htm

```
tail -f /irissys/data/IRIS/mgr/messages.log
```