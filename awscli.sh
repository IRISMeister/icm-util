label="MyIRIS"

aws ec2 describe-instances --filters "Name=tag-key,Values=Name" "Name=tag-value,Values=$label*" --query "Reservations[*].Instances[*].[InstanceId]"
aws ec2 describe-vpcs --filters "Name=tag-key,Values=Name" "Name=tag-value,Values=$label*" --query "Vpcs[*].[VpcId]"
aws ec2 describe-volumes --filters "Name=tag-key,Values=Name" "Name=tag-value,Values=$label*" --query "Volumes[*].[VolumeId]"
aws ec2 describe-security-groups --filters "Name=group-name,Values=$label*" --query "SecurityGroups[*].[GroupId]"
aws ec2 describe-key-pairs --filter "Name=key-name,Values=$label*" --query "KeyPairs[*].[KeyName]"
