# Change to Subnet ID on cluster.yaml
```sh
#!/bin/bash
public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-a" --query "Subnets[].SubnetId[]" --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-b" --query "Subnets[].SubnetId[]" --output text)
public_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-c" --query "Subnets[].SubnetId[]" --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-b" --query "Subnets[].SubnetId[]" --output text)
private_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-c" --query "Subnets[].SubnetId[]" --output text)

sed -i "s|public_a|$public_a|g" cluster.yaml
sed -i "s|public_b|$public_b|g" cluster.yaml
sed -i "s|public_c|$public_c|g" cluster.yaml
sed -i "s|private_a|$private_a|g" cluster.yaml
sed -i "s|private_b|$private_b|g" cluster.yaml
sed -i "s|private_c|$private_c|g" cluster.yaml
```

<br>

# Add Subnet Tag on Ingress ALB Controller
```sh
#!/bin/bash
public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-public-a" --query "Subnets[].SubnetId[]" --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-public-b" --query "Subnets[].SubnetId[]" --output text)
public_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-public-c" --query "Subnets[].SubnetId[]" --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-private-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-private-b" --query "Subnets[].SubnetId[]" --output text)
private_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-private-c" --query "Subnets[].SubnetId[]" --output text)

public_subnet_name=("$public_a" "$public_b" "$public_c")
private_subnet_name=("$private_a" "$private_b" "$private_c")

for name in "${public_subnet_name[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/elb,Value=1
done

for name in "${private_subnet_name[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/internal-elb,Value=1
done

```

<br>

# Add Subnet Tag on Karpenter
```sh
#!/bin/bash
ClusterName=<env>-eks-cluster
public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-a" --query "Subnets[].SubnetId[]" --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-b" --query "Subnets[].SubnetId[]" --output text)
public_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-c" --query "Subnets[].SubnetId[]" --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-b" --query "Subnets[].SubnetId[]" --output text)
private_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-c" --query "Subnets[].SubnetId[]" --output text)

NODEGROUP=$(aws eks list-nodegroups --cluster-name ${ClusterName} \
    --query 'nodegroups[0]' --output text)
 
LAUNCH_TEMPLATE=$(aws eks describe-nodegroup --cluster-name ${ClusterName} \
    --nodegroup-name ${NODEGROUP} --query 'nodegroup.launchTemplate.{id:id,version:version}' \
    --output text | tr -s "\t" ",")
 
 
SECURITY_GROUPS=$(aws eks describe-cluster \
    --name ${ClusterName} --query cluster.resourcesVpcConfig.clusterSecurityGroupId | tr -d '"')
 
SECURITY_GROUPS=$(aws ec2 describe-launch-template-versions \
    --launch-template-id ${LAUNCH_TEMPLATE%,*} --versions ${LAUNCH_TEMPLATE#*,} \
    --query 'LaunchTemplateVersions[0].LaunchTemplateData.[NetworkInterfaces[0].Groups||SecurityGroupIds]' \
    --output text)
    
list=("$public_a" "$public_b" "$public_c" "$private_a" "$private_b" "$private_c")

for name in "${list[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=karpenter.sh/discovery,Value=$ClusterName
done

 
aws ec2 create-tags \
    --tags "Key=karpenter.sh/discovery,Value=${ClusterName}" \
    --resources ${SECURITY_GROUPS}
```