#!/bin/bash
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="wsi-eks-cluster"
PUBLIC_A_SN_NAME="wsi-public-a"
PUBLIC_B_SN_NAME="wsi-public-b"
PUBLIC_C_SN_NAME="wsi-public-c"
PRIVATE_A_SN_NAME="wsi-private-a"
PRIVATE_B_SN_NAME="wsi-private-b"
PRIVATE_C_SN_NAME="wsi-private-c"

PUBLIC_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PUBLIC_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PUBLIC_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)

sed -i "s|public_a|$PUBLIC_A_SN_ID|g" /home/ec2-user/eks/cluster.yaml
sed -i "s|public_b|$PUBLIC_b_SN_ID|g" /home/ec2-user/eks/cluster.yaml
sed -i "s|public_c|$PUBLIC_C_SN_ID|g" /home/ec2-user/eks/cluster.yaml
sed -i "s|private_a|$PRIVATE_A_SN_ID|g" /home/ec2-user/eks/cluster.yaml
sed -i "s|private_b|$PRIVATE_B_SN_ID|g" /home/ec2-user/eks/cluster.yaml
sed -i "s|private_c|$PRIVATE_C_SN_ID|g" /home/ec2-user/eks/cluster.yaml

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