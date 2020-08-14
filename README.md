# icm-util
This utility is to help depoy InterSystems IRIS cluster via ICM in container less mode.  
(Container mode will work, though)  

Tested on Ubuntu 18.04LTS  (may not work on Windows)  
Tested against IRIS V2020.1.

# Prerequisite
docker  
jq  
```
sudo apt install jq
```

# Before running
Acquire iris kit(tar.gz), icm docker image, iris license key.  
Edit params.sh to meet your purpose.
```
vi params.sh
```

If you are using AWS, prepare your aws credentials.
```
vi .aws/credentials
```

If you are using Azure, you need to performe the following. These file are subject to be mergerd with defaults.json file when run.
- Provide azure access keys.
```
cp secret/azure-secret.json.template secret/azure-secret.json
vi secret/azure-secret.json
```

If you are using container mode on any cloud, you need to performe the following. These file are subject to be mergerd with defaults.json file when run.

- Provide docker user/password and docker image info.  
If you do not want to override DockerImage in defaults.json file, remove it from docker-secret.json.
```
cp secret/docker-secret.json.template secret/docker-secret.json
vi secret/docker-secret.json
```
**Do not leave value of "ISCPassword" in defaults.json as is because it is too obvious!!!**  
defaults.json files are localted under provider/os/.  So If you are using ubuntu on aws, it will be defaults/aws/ubuntu/defaults.json . 
If you want to enable mirroring (by using definition-mirror.json for example), you need to edit defaults.json and change "Mirror" value from "false" to "true".  
```
vi which_ever_defaults_file_you_may_use.json
```
run.sh uses Label value from default.json file to uniquely identify your run. It is used as container name and as part of external volume path like below.
```
icmname=$(cat defaults/aws/ubuntu/defaults.json | jq -r '.Label')
docker run -d -v $(pwd)/icm_data/aws/$icmname:/Production ... --name $icmname
```



# How to Run
To run  
```
./run.sh  
```
Every icm related data will be stored under ./icm_data (for example, icm_data/aws/MyIRIS/).
This folder is mounted as external voulme by the icm container to /Production.  
If you run.sh when params.sh says restoreExistingEnv=true, run.sh will try to restore matching ICM environment from external volume mentioned above.  

To remove  
```
./rm.sh containerName
```

You can use awscli.sh for AWS to see if any resoures are remained unexpectedly.  

Disk size is defined by "DataVolumeSize": "1024" in defaults.json.  
Typically disk performance is constrained by Disk size + Disk type.  
see https://docs.microsoft.com/ja-jp/azure/virtual-machines/windows/disks-types#premium-ssd

typical things to do next.  
```
cat inventory.json (to see IP addresses)

cp Backup/ssh/insecure ~
cd ~
chmod 700 insecure
ssh -i insecure ubuntu@ipaddress
```
If BH is in place, you need to use following ssh syntax (ip/host are masked by 'x')
```
Machine                        IP Address       DNS Name                                 Provider Region     Zone
-------                        ----------       --------                                 -------- ------     ----
MyIRISCL-BH-TEST-0001         54.250.x.x   ec2-54-250-x-x.ap-northeast-1.comput AWS      ap-northeast-1 a
MyIRISCL-DM-TEST-0001         10.0.x.x     10.0.x.x                             AWS      ap-northeast-1 a
```
```
ssh -i insecure -oProxyCommand='ssh -i insecure -W %h:%p ubuntu@ec2-54-250-x-x.ap-northeast-1.compute.amazonaws.com' ubuntu@10.0.x.x
```
If you want to see which ports on BH will be forwarded to where, see configBastion.log on BH.
```
ssh -i insecure ubuntu@54.250.x.x cat configBastion.log

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