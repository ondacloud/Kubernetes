### Setup EKS Cluster on Basic 
```shell
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_VERSION="1.34"
EKS_CLUSTER_NAME="demo-eks-cluster"
EKS_APP_NODE_GROUP_NAME="demo-app-node"
EKS_ADDON_NODE_GROUP_NAME="demo-addon-node"
EKS_APP_NODE_GROUP_INSTANCE_TYPE="c5.large"
EKS_ADDON_NODE_GROUP_INSTANCE_TYPE="c5.large"
```

```shell
sed -i "s|REGION_CODE|$REGION_CODE|g" cluster.yaml
sed -i "s|EKS_CLUSTER_VERSION|$EKS_CLUSTER_VERSION|g" cluster.yaml
sed -i "s|EKS_CLUSTER_NAME|$EKS_CLUSTER_NAME|g" cluster.yaml
sed -i "s|EKS_APP_NODE_GROUP_NAME|$EKS_APP_NODE_GROUP_NAME|g" cluster.yaml
sed -i "s|EKS_ADDON_NODE_GROUP_NAME|$EKS_ADDON_NODE_GROUP_NAME|g" cluster.yaml
sed -i "s|EKS_APP_NODE_GROUP_INSTANCE_TYPE|$EKS_APP_NODE_GROUP_INSTANCE_TYPE|g" cluster.yaml
sed -i "s|EKS_ADDON_NODE_GROUP_INSTANCE_TYPE|$EKS_ADDON_NODE_GROUP_INSTANCE_TYPE|g" cluster.yaml
```

```shell
#!/bin/bash
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
PUBLIC_A_SN_NAME="demo-public-a"
PUBLIC_B_SN_NAME="demo-public-b"
PUBLIC_C_SN_NAME="demo-public-c"
PRIVATE_A_SN_NAME="demo-private-a"
PRIVATE_B_SN_NAME="demo-private-b"
PRIVATE_C_SN_NAME="demo-private-c"

PUBLIC_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PUBLIC_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PUBLIC_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
CLUSTER_YAML_PATH=$(sudo find / -name "cluster.yaml" 2> /dev/null)

sed -i "s|PUBLIC_A|$PUBLIC_A_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PUBLIC_B|$PUBLIC_b_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PUBLIC_C|$PUBLIC_C_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PRIVATE_A|$PRIVATE_A_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PRIVATE_B|$PRIVATE_B_SN_ID|g" $CLUSTER_YAML_PATH
sed -i "s|PRIVATE_C|$PRIVATE_C_SN_ID|g" $CLUSTER_YAML_PATH

PUBLIC_SN_IDS=("$PUBLIC_A_SN_ID" "$PUBLIC_B_SN_ID" "$PUBLIC_C_SN_ID")
PRIVATE_SN_IDS=("$PRIVATE_A_SN_ID" "$PRIVATE_B_SN_ID" "$PRIVATE_C_SN_ID")

for name in "${PUBLIC_SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/cluster/$EKS_CLUSTER_NAME,Value=shared
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/elb,Value=1
done

for name in "${PRIVATE_SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/cluster/$EKS_CLUSTER_NAME,Value=shared
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/internal-elb,Value=1
done
```

```shell
eksctl create cluster -f cluster.yaml
```

```shell
aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CLUSTER_NAME
```