<h1 align="center"> Create NTH </h1>

```shell
EKS_CLUSTER_NAME="<CLUSTER_NAME>"
STACK_NAME="<STACK_NAME>"
```

```shell
curl -LO https://raw.githubusercontent.com/aws/aws-node-termination-handler/main/docs/cfn-template.yaml
```

```shell
aws cloudformation deploy \
    --template-file ./cfn-template.yaml \
    --stack-name $STACK_NAME
```

```shell
aws autoscaling put-lifecycle-hook \
  --lifecycle-hook-name=k8s-hook \
  --auto-scaling-group-name=$AUTO_SCALING_GROUP_NAME \
  --lifecycle-transition=autoscaling:EC2_INSTANCE_TERMINATING \
  --default-result=CONTINUE \
  --heartbeat-timeout=300
```

```shell
aws autoscaling create-or-update-tags \
  --tags ResourceId=$AUTO_SCALING_GROUP_NAME,ResourceType=auto-scaling-group,Key=aws-node-termination-handler/managed,Value=,PropagateAtLaunch=true
```

```shell
cat <<\EOF> nth-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeTags",
                "ec2:DescribeInstances",
                "sqs:DeleteMessage",
                "sqs:ReceiveMessage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
```

```shell
POLICY_ARN=$(aws iam create-policy --policy-name nth-policy --policy-document file://nth-policy.json --query 'Policy.Arn' --output text)
```

```shell
eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --approve
```

```shell
eksctl create iamserviceaccount \
    --cluster $EKS_CLUSTER_NAME \
    --name aws-node-termination-handler \
    --namespace kube-system \
    --attach-policy-arn $POLICY_ARN \
    --role-name AWS_NTH_Role \
    --approve
```

```shell
QUEUE_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='QueueURL'].OutputValue" --output text)
```

```shell
helm repo add eks https://aws.github.io/eks-charts
helm install aws-node-termination-handler eks/aws-node-termination-handler \
    --namespace kube-system \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-node-termination-handler \
    --set enableSqsTerminationDraining=true \
    --set queueURL=$QUEUE_URL
```