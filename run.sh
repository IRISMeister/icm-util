#!/bin/bash -e
source params.sh

################################################################################
# if there is a container by the same name, try to restore it and exit.
################################################################################
if [ $restoreExistingEnv = "true" ]; then
  containerid=$(docker ps -q -f "name=$icmname" -f "status=running")
  #; if there is a 'Up' container.
  if [ -n "$containerid" ]; then
    echo "Container $icmname is already running. Nothing to do."
    exit 0
  fi
  containerid=$(docker ps -a -q -f "name=$icmname" -f "status=exited")
  #; if there is a 'Exited' container.
  if [ -n "$containerid" ]; then
    echo "Restaring container $icmname."
    docker start $icmname
    exit 0
  #; if there is no container.
  else
    #; if external data is left, use it.
    if [ -e icm_data/$provider/$icmname/$provider ]; then
      echo "Recreating container $icmname from existing folder icm_data/$provider/$icmname/$provider"
      echo "If this is not what you want, sudo rm -fR icm_data/$provider/$icmname, before calling run.sh."
      docker run -d -v $(pwd -P)/icm_data/$provider/$icmname:/Production --name $icmname $icmimg tail -f /dev/null
      # restore ssh/tls files as well.
      docker cp icm_data/$provider/$icmname/ssh $icmname:/Samples 
      docker cp icm_data/$provider/$icmname/tls $icmname:/Samples
 
      # restore informative files. We use them in rm.sh.
      docker exec $icmname sh -c "echo $icmdata > folder.txt"
      docker exec $icmname sh -c "echo $provider > provider.txt"

      exit 0
    fi
  fi
  # At this point, there is no way left to restore.
fi

################################################################################
# tests if all required files are ready
################################################################################
if [ $isContainerless = "true" ]; then
  if [ ! -e kits/$kitname ]; then
    echo "Kit $kitname doesn't exist."
    exit 1
  fi
fi

if [ ! -e $defaultspath/$defaults ]; then
    echo "Requested defaults.json files doesn't exist."
    exit 1
fi

if [ ! -e definitions/$definitions ]; then
    echo "Requested definitions.json files doesn't exist."
    exit 1
fi

if [ $isContainerless = "true" ]; then
  iriskey=iris.key
else
  iriskey=iris-container.key
fi

if [ ! -e irislicense/$iriskey ]; then
  echo "License key (iris.key) doesn't exist."
  exit 1
fi

if [ $provider = "aws" ]; then
  if [ ! -e ~/.aws/credentials ]; then
    echo "AWS credential doesn't exist."
    exit 1
  fi
fi

echo "Provider:"$provider" os:"$targetos" isContainerless:"$isContainerless" container name:"$icmname

# Need sudo because some files may owned by root (bacause they are created by docker-daemon)
sudo rm -fR icm_data/$provider/$icmname
# don't let docker make it beacuse it will be owned by root
mkdir -p icm_data/$provider/$icmname
# preserve current params.sh so that I can run multiple icm instances concurrently.
cp ./params.sh icm_data/$provider/$icmname/params.sh

docker stop $icmname | true
docker rm $icmname | true
docker run -d -v $(pwd -P)/icm_data/$provider/$icmname:/Production --name $icmname $icmimg tail -f /dev/null

# I didn't want to rewrite every defaults.json files about location of ssh/tls.
# On Windows, do not place ssh/tls files under /Production where is extenally mounted. 
# (if you do, ssh will fail with bad permissions)
docker exec $icmname sh -c "keygenTLS.sh /Samples/tls; keygenSSH.sh /Samples/ssh"
docker exec $icmname mkdir -p /Production/license

# If I externally mounted those folders, on docker Windows, icm provision fails because of its limited support for file protections.
# So I have to copy ssh/tls files to outside of the container to preserve them.
docker cp $icmname:/Samples/ssh icm_data/$provider/$icmname/
docker cp $icmname:/Samples/tls icm_data/$provider/$icmname/


if [ $isContainerless = "true" ]; then
  docker cp kits/$kitname $icmname:/root
fi
docker exec $icmname mkdir -p $icmdata
docker exec $icmname sh -c "echo $icmdata > folder.txt"
docker exec $icmname sh -c "echo $provider > provider.txt"

################################################################################
# apply changes to a defaults.json template.
# copy definitions.json, license key, cpf merge file, and aws credentials.
# copy them into running container.
################################################################################
# modify defaults.json if azure
cp $defaultspath/$defaults tmp-$defaults
if [ $provider = "azure" ]; then
  if [ -e secret/azure-secret.json ]; then
    jq -s '.[0]*.[1]' $defaultspath/$defaults secret/azure-secret.json > tmp-$defaults
  fi
fi

# replacing kitname if Containerless, replacing DockerUsername,DockerPassword if Container.
if [ $isContainerless = "true" ]; then
  cat tmp-$defaults | jq '.KitURL = "file://tmp/'$kitname'"' > actual-$defaults
  docker cp actual-$defaults $icmname:$icmdata/defaults.json
else
  if [ -e secret/docker-secret.json ]; then
    jq -s '.[0]*.[1]' tmp-$defaults secret/docker-secret.json > actual-$defaults
    docker cp actual-$defaults $icmname:$icmdata/defaults.json
  else
    docker cp tmp-$defaults $icmname:$icmdata/defaults.json
  fi
fi

rm -f tmp-$defaults
rm -f actual-$defaults

# copy a definitions.json to use
docker cp definitions/$definitions $icmname:$icmdata/definitions.json

# copy a merge-cpf file to use
docker exec $icmname mkdir -p /Production/mergefiles
docker cp $cpffile $icmname:/Production/mergefiles/merge.cpf

# need to aquire a valid aws credential beforehand
if [ $provider = "aws" ]; then
  docker cp ~/.aws/credentials $icmname:$icmdata/credentials
fi
# copy a license key
docker cp irislicense/$iriskey $icmname:/Production/license/iris.key

################################################################################
# provision, copy iris kit (if containerless), install/run
################################################################################
docker exec $icmname sh -c "cd $icmdata; icm provision"
if [ $isContainerless = "true" ]; then
  # If you have any faster way(s3, azure blob, ftp, whatever) to upload a kit, use it.
  if [ -e fast_kit_uploader.sh ]; then
    ./fast_kit_uploader.sh $icmname $icmdata $kitname
  else
    docker exec $icmname sh -c "cd $icmdata; icm scp -localPath /root/$kitname -remotePath /tmp"
  fi
  docker exec $icmname sh -c "cd $icmdata; icm install"
else
  docker exec $icmname sh -c "cd $icmdata; icm run"
fi

################################################################################
# saves vital information into files for later use
################################################################################
inventory=icm_data/$provider/$icmname/inventory.json
ps=icm_data/$provider/$icmname/ps.json

docker exec $icmname sh -c "cd $icmdata; icm inventory -json > /dev/null; cat response.json" > $inventory
docker exec $icmname sh -c "cd $icmdata; icm ps -json > /dev/null; cat response.json" > $ps

########################################################################################
# looking for 
#    an appropriate IRIS MachineName to install IVP. Could be DM(mirrot primary), DATA(any).
#    DNSName of its endpoint. Could be BH,DM(mirror primary),DATA.
#    I wonder if there is any better way...?
########################################################################################
# Does BH exist?
bastionip=$(cat $inventory | jq -r '.[] | select(.Role == "BH") | .DNSName')
bastiontargetmachine=$(cat $inventory | jq -r '.[] | select(.Role == "BH") | .MachineName')

isMirror=$(cat icm_data/$provider/$icmname/$provider/defaults.json | jq -r '.Mirror')
if [ $isMirror="true" ]; then
  ip=$(cat $ps | jq -r '.[] | select(.Role == "DM" and .MirrorStatus=="PRIMARY") | .DNSName')
  targetmachine=$(cat $ps | jq -r '.[] | select(.Role == "DM" and .MirrorStatus=="PRIMARY") | .MachineName')
fi
# picks up the first DM
if [ -z "$ip" ]; then
  ip=$(cat $ps | jq -r '.[] | select(.Role == "DM") | .DNSName')
  targetmachine=$(cat $ps | jq -r '.[] | select(.Role == "DM") | .MachineName')
  iparr=($ip)
  if [ -n "${iparr[0]}" ]; then
    ip=${iparr[0]}
    tgtarr=($targetmachine)
    targetmachine=${tgtarr[0]}
  fi
fi
# if there is no DM, use the first DATA node found.
if [ -z "$ip" ]; then
  ip=$(cat $ps | jq -r '.[] | select(.Role == "DATA") | .DNSName')
  targetmachine=$(cat $ps | jq -r '.[] | select(.Role == "DATA") | .MachineName')
  iparr=($ip)
  if [ -n "${iparr[0]}" ]; then
    ip=${iparr[0]}
    tgtarr=($targetmachine)
    targetmachine=${tgtarr[0]}
  fi
fi

echo '$icmname': $icmname >> icm_data/$provider/$icmname/params
echo '$icmdata': $icmdata >> icm_data/$provider/$icmname/params
echo 'endpoint $ip': $ip >> icm_data/$provider/$icmname/params
echo '$targetmachine': $targetmachine >> icm_data/$provider/$icmname/params

########################################################################################
# install ivp app classes, if Containerless
########################################################################################
if [ $isContainerless = "true" ]; then
  echo "Installing IVP into "$targetmachine
  docker cp install-ivp.sh $icmname:/root
  docker cp icmcl-atelier-prj $icmname:/root
  docker exec $icmname /root/install-ivp.sh $icmdata $targetmachine

  if [ -n "$bastionip" ]; then
    echo "Accessing "$bastionip
    curl -H "Content-Type: application/json; charset=UTF-8" -H "Accept:application/json" "http://$bastionip:52774/csp/myapp/get" --user "SuperUser:sys"
  else
    echo "Accessing "$ip
    curl -H "Content-Type: application/json; charset=UTF-8" -H "Accept:application/json" "http://$ip:52773/csp/myapp/get" --user "SuperUser:sys"
  fi
fi

########################################################################################
# Run user supplied script if exists.
########################################################################################
if [ -e app/install-apps-user.sh ]; then
  app/install-apps-user.sh $icmname $icmdata $targetmachine $ip
fi

########################################################################################
# dump informations because they are probably off the screen and hard to find
########################################################################################
echo "==================================================="
echo "Container ["$icmname"] has been created. To unprovision all resources, execute ./rm.sh "$icmname
echo "==================================================="
echo "icm inventory"
docker exec $icmname sh -c "cd $icmdata; icm inventory"
echo "==================================================="
echo "icm ps"
docker exec $icmname sh -c "cd $icmdata; icm ps"
grep "Management Portal available at" icm_data/$provider/$icmname/$provider/icm.log

sshuser=$(cat icm_data/$provider/$icmname/$provider/defaults.json | jq -r '.SSHUser')
echo "==================================================="
echo "how to login"
echo " ssh -i icm_data/$provider/$icmname/ssh/insecure -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $sshuser@$ip"
