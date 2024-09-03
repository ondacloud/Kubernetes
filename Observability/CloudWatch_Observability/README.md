<h1 align="center"> Create CloudWatch Observability </h1>


```shell
EKS_CLUSTER_NAME="<CLUSTER_NAME>"
EKS_NODE_GROUP_NAME="<NODE_GROUP_NAME>"
NODE_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name $EKS_NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
```

```shell
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name $NODE_ROLE_NAME
```

```shell
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml
```

```shell
aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name amazon-cloudwatch-observability > /dev/null
```