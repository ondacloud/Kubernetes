<h1 align="center"> Create Container Insight </h1>

```shell
EKS_CLUSTER_NAME="<CLUSTER_NAME>"
EKS_NODE_GROUP_NAME="<NODE_GROUP_NAME>"
```

```shell
NODEGROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODE_GROUP_NAME --query "nodegroup.nodeRole" --output text | cut -d'/' -f2-)
```

```shell
aws iam attach-role-policy \
--role-name $NODEGROUP_ROLE_NAME \
--policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

```shell
aws iam attach-role-policy \
--role-name $NODEGROUP_ROLE_NAME \
--policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess
```

```shell
aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name amazon-cloudwatch-observability > /dev/null
```