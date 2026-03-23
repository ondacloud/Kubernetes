### Setup Cluster Autoscaler
[**Cluster Autoscaler Release**](https://github.com/kubernetes/autoscaler/releases)

```shell
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
EKS_APP_NODE_GROUP_NAME="demo-app-node"
EKS_ADDON_NODE_GROUP_NAME="demo-addon-node"
APP_NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_APP_NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
ADDON_NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_ADDON_NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
```

```shell
cat <<EOF> ClusterAutoScaler-Policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
```

```shell
POLICY_ARN=$(aws --region $REGION_CODE --query Policy.Arn --output text iam create-policy --policy-name AmazonEKSClusterAutoscalerPolicy --policy-document file://ClusterAutoScaler-Policy.json)
```

```shell
aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name $APP_NODE_GROUP_ROLE_NAME
aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name $ADDON_NODE_GROUP_ROLE_NAME
```

```shell
curl -O https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

```shell
sed -i "s|<YOUR CLUSTER NAME>|$EKS_CLUSTER_NAME|g" ./cluster-autoscaler-autodiscover.yaml
sed -i 's|v1.32.1|v1.35.0|g' cluster-autoscaler-autodiscover.yaml
sed -i '/prometheus.io\/port/a\        cluster-autoscaler.kubernetes.io/safe-to-evict: "false"' your-file.yaml
sed -i "/prometheus.io\/port/a\        cluster-autoscaler.kubernetes.io/safe-to-evict: 'false'" cluster-autoscaler-autodiscover.yaml
sed -i '/node-group-auto-discovery/a\            - --balance-similar-node-groups\n            - --skip-nodes-with-system-pods=false\n            - --scale-down-unneeded-time=1m\n            - --scale-down-utilization-threshold=0.5' cluster-autoscaler-autodiscover.yaml
```

```shell
kubectl apply -f cluster-autoscaler-autodiscover.yaml
```

```shell
kubectl patch deployment cluster-autoscaler -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/nodeSelector", "value":{"type":"addon"}}]'
```