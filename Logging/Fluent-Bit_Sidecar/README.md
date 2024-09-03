<h1 align="center"> Create Fluent-Bit Sidecar </h1>

```shell
EKS_CLUSTER_NAME="<CLUSTER_NAME>"
```

```shell
cat <<EOF> cw-log-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
```

```shell
aws iam create-policy --policy-name fluent-bit-policy --policy-document file://cw-log-policy.json > /dev/null
```

```shell
kubectl create ns fluent-bit
```

```shell
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='fluent-bit-policy'].Arn" --output text)
```

```shell
eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --approve
```

```shell
eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --namespace=default \
  --name=aws-for-fluent-bit \
  --role-name FluentBitIAMRole \
  --attach-policy-arn=$POLICY_ARN \
  --approve
```

```shell

```shell
cat <<EOF> values.yaml
serviceAccount:
  create: false
  name: fluent-bit

cloudWatchLogs:
  enabled: true
  region: "ap-northeast-2"
  logGroupName: "<CloudWatch_Log_Group_Name>"
  logStreamPrefix: "log-"
  autoCreateGroup: true
EOF
```

```shell
helm repo add eks https://aws.github.io/eks-charts
helm upgrade --install aws-for-fluent-bit --namespace fluent-bit eks/aws-for-fluent-bit -f values.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-sidecar
  namespace: wsi-ns
  labels:
    app.kubernetes.io/name: fluent-bit-sidecar
    helm.sh/chart: default-0.1.0
    app.kubernetes.io/instance: flb-sidecar
    app.kubernetes.io/version: "1.0"
    app.kubernetes.io/managed-by: Tiller
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         1
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf

    [INPUT]
        Name          tail
        Path          /logs/app.log
        Parser        custom_log
        Tag           app.log
  
    [OUTPUT]
        Name          stdout
        Match         *

    [OUTPUT]
        Name          cloudwatch
        Match         *
        endpoint      https://logs.ap-northeast-2.amazonaws.com
        region        ap-northeast-2
        log_group_name <CloudWatch_Log_Group_Name>
        log_stream_name log-${HOSTNAME}
        auto_create_group true

  parsers.conf: |
    [PARSER]
        Name           custom_log
        Format         regex
        Regex          ^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})\s(?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2}),\d+ - - (?<ip>\d+\.\d+\.\d+\.\d+) (?<port>\d+) (?<method>\S+) (?<path>\S+) (?<statuscode>\d+)$
        Time_Key       time
        Time_Format    %Y-%m-%d %H:%M:%S
        Time_Keep      On
```

```shell
kubectl apply -f fluent-bit-cm.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment
  namespace: default
  labels:
    app: worker
spec:
  replicas: 2
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      serviceAccountName: aws-for-fluent-bit
      containers:
      - name: cnt
        image: IMAGE
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
        volumeMounts:
        - name: log-volume
          mountPath: /logs
      - name: fluent-bit-cnt
        image: amazon/aws-for-fluent-bit:1.2.2
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 2020
          name: metrics
          protocol: TCP
        volumeMounts:
        - name: config-volume
          mountPath: /fluent-bit/etc/
        - name: log-volume
          mountPath: /logs
      volumes:
      - name: log-volume
        emptyDir: {}
      - name: config-volume
        configMap:
          name: fluent-bit-sidecar
```

```shell
kubectl apply -f deployment.yaml
```