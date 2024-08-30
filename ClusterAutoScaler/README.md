<h1 align="center"> Cluster AutoScaler </h1>

# Create Cluster AutoScaler

```shell
CLUSTER_NAME="<EKS_CLUSTER_NAME>"
REGION_CODE=$(aws configure get region --output text)
```

```shell
NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name apdev-app-ng --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
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
aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name $NODE_GROUP_ROLE_NAME
```

```shell
curl -O https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

```shell
sed -i "s|<YOUR CLUSTER NAME>|$CLUSTER_NAME|g" ./cluster-autoscaler-autodiscover.yaml
sed -i 's|v1.26.2|v1.30.2|g' cluster-autoscaler-autodiscover.yaml
```

```yaml
annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8085'
        cluster-autoscaler.kubernetes.io/safe-to-evict: 'false'
```

```shell
- command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/apdev-eks-cluster
				- --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
        - --scale-down-unneeded-time=1m
        - --scale-down-utilization-threshold=0.5
        image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.30.2
```

```shell
kubectl apply -f cluster-autoscaler-autodiscover.yaml
```