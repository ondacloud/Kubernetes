### Setup Karpenter

```shell
kubectl patch deployment karpenter -n karpenter --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/nodeSelector", "value":{"type":"addon"}}]'
```

```shell
#!/bin/bash
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
EKS_APP_NODE_GROUP_NAME="demo-app-node"
EKS_ADDON_NODE_GROUP_NAME="demo-addon-node"
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
EKS_APP_NODE_GROUP_SECURITY_GROUP_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$EKS_APP_NODE_GROUP_NAME" --query "Reservations[0].Instances[0].SecurityGroups[].GroupId" --output text --region $REGION_CODE)
EKS_ADDON_NODE_GROUP_SECURITY_GROUP_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$EKS_ADDON_NODE_GROUP_NAME" --query "Reservations[0].Instances[0].SecurityGroups[].GroupId" --output text --region $REGION_CODE)

aws ec2 create-tags --resources $EKS_APP_NODE_GROUP_SECURITY_GROUP_ID --tags Key=karpenter.sh/discovery,Value=$EKS_APP_NODE_GROUP_NAME
aws ec2 create-tags --resources $EKS_ADDON_NODE_GROUP_SECURITY_GROUP_ID --tags Key=karpenter.sh/discovery,Value=$EKS_ADDON_NODE_GROUP_NAME

SN_IDS=("$PUBLIC_A_SN_ID" "$PUBLIC_B_SN_ID" "$PUBLIC_C_SN_ID" "$PRIVATE_A_SN_ID" "$PRIVATE_B_SN_ID" "$PRIVATE_C_SN_ID")

for name in "${SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=karpenter.sh/discovery,Value=$EKS_APP_NODE_GROUP_NAME
    aws ec2 create-tags --resources $name --tags Key=karpenter.sh/discovery,Value=$EKS_ADDON_NODE_GROUP_NAME
done
```

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["c5.large"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      expireAfter: 30m 
  limits:
    cpu: "1000"
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 5m
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  tags:
    Name: EKS_NODE_GROUP_NAME
  role: "KarpenterNodeRole-EKS_CLUSTER_NAME"
  amiSelectorTerms:
    - alias: "al2023@latest"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "EKS_NODE_GROUP_NAME"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "EKS_NODE_GROUP_NAME"
```

```shell
sed -i "s|EKS_CLUSTER_NAME|$EKS_CLUSTER_NAME|g" karpenter.yaml

# 2개 중 1개 사용
# sed -i "s|EKS_NODE_GROUP_NAME|$EKS_APP_NODE_GROUP_NAME|g" karpenter.yaml
# sed -i "s|EKS_NODE_GROUP_NAME|$EKS_ADDON_NODE_GROUP_NAME|g" karpenter.yaml
```

```shell
kubectl apply -f karpenter.yaml
```