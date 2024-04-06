<h1 align="center"> Create Fargate Log Router </h1>

# ENV
```shell
ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
ROLE_ARN=$(aws eks describe-fargate-profile --cluster-name wsi-eks-cluster --fargate-profile-name wsi-app-fg --query "fargateProfile.podExecutionRoleArn" --output text)
ROLE_NAME=$(echo $ROLE_ARN | cut -d'/' -f2)
```


# Create Fargate Log Router

```shell
kubectl create ns aws-observability
```

```shell
kubectl edit ns aws-observability
```

```shell
labels:
    kubernetes.io/metadata.name: aws-observability
    aws-observability: enabled
```

```shell
curl -o permissions.json https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json
```

```shell
aws iam create-policy --policy-name eks-fargate-logging-policy --policy-document file://permissions.json
```

```shell
aws iam attach-role-policy \
--policy-arn arn:aws:iam::$ACCOUNT:policy/eks-fargate-logging-policy \
--role-name $ROLE_NAME
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