<h1 align="center"> Create Fargate Log Router </h1>

# ENV
```shell
EKS_CLUISTER_NAME="<CLUSTER_NAME>"
EKS_NODE_GROUP_NAME="<NODE_GROUP_NAME>"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE=$(aws configure get default.region --output text)
```


# Create Fargate Log Router

```yaml
kind: Namespace
apiVersion: v1
metadata:
  name: aws-observability
  labels:
    aws-observability: enabled
```

```shell
kubectl apply -f ns.yaml
```

```shell
eksctl utils associate-iam-oidc-provider --region=$REGION_CODE --cluster=$EKS_CLUISTER_NAME --approve
```

```shell
curl -o permissions.json https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json
```

```shell
FARGATE_POLICY_ARN=$(aws --region "$REGION_CODE" --query Policy.Arn --output text iam create-policy --policy-name fargate-policy --policy-document file://permissions.json)
FARGATE_ROLE_NAME=$(aws iam list-roles --query "Roles[?contains(RoleName, 'eksctl-$CLUSTER_NAME-clus-FargatePodExecutionRole')].RoleName" --output text)
NODE_GROUP=$(aws iam get-role --role-name $FARGATE_ROLE_NAME --query "Role.RoleName" --output text)
NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUISTER_NAME --nodegroup-name $NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
```

```shell
aws iam attach-role-policy --policy-arn $FARGATE_POLICY_ARN --role-name $NODE_GROUP
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name $NODE_GROUP_ROLE_NAME
```

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: aws-logging
  namespace: aws-observability
data:
  output.conf: |
    [OUTPUT]
        Name cloudwatch_logs
        Match   *
        region ap-northeast-2
        log_group_name fluent-bit-cloudwatch
        log_stream_prefix from-fluent-bit-
        auto_create_group true
        log_key log

  parsers.conf: |
    [PARSER]
        Name crio
        Format Regex
        Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>P|F) (?<log>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
  
  filters.conf: |
     [FILTER]
        Name parser
        Match *
        Key_name log
        Parser crio
```

```shell
kubectl apply -f aws-logging-cloudwatch-configmap.yaml
```