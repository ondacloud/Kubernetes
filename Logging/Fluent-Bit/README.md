<h1 align="center"> Create Fluent-Bit </h1>

```shell
EKS_CLUSTER_NAME="<CLUSTER_NAME>"
EKS_NODE_GROUP_NAME="<NODE_GROUP_NAME>"
REGION_CODE=$(aws configure get region --output text)
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fluent-bit
  labels:
    name: amazon-cloudwatch
```

```shell
kubectl apply -f ns.yaml
```

```shell
eksctl utils associate-iam-oidc-provider --region=$REGION_CODE --cluster=$EKS_CLUSTER_NAME --approve
```

```shell
curl -o permissions.json https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json
```

```shell
FARGATE_POLICY_ARN=$(aws --region "$REGION_CODE" --query Policy.Arn --output text iam create-policy --policy-name fargate-policy --policy-document file://permissions.json)
FARGATE_ROLE_NAME=$(aws iam list-roles --query "Roles[?contains(RoleName, 'eksctl-$EKS_CLUSTER_NAME-clus-FargatePodExecutionRole')].RoleName" --output text)
NODE_GROUP=$(aws iam get-role --role-name $FARGATE_ROLE_NAME --query "Role.RoleName" --output text)
NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUISTER_NAME --nodegroup-name $EKS_NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
```

```shell
aws iam attach-role-policy --policy-arn $FARGATE_POLICY_ARN --role-name $NODE_GROUP
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name $NODE_GROUP_ROLE_NAME
```

```shell
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
kubectl create configmap fluent-bit-cluster-info-app \
--from-literal=cluster.name=${EKS_CLUISTER_NAME} \
--from-literal=http.server=${FluentBitHttpServer} \
--from-literal=http.port=${FluentBitHttpPort} \
--from-literal=read.head=${FluentBitReadFromHead} \
--from-literal=read.tail=${FluentBitReadFromTail} \
--from-literal=logs.region=${REGION_CODE} -n fluent-bit
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluent-bit-app
  namespace: fluent-bit
```

```shell
kubectl apply -f sa.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluent-bit-app-role
rules:
  - nonResourceURLs:
      - /metrics
    verbs:
      - get
  - apiGroups: [""]
    resources:
      - namespaces
      - pods
      - pods/logs
      - nodes
      - nodes/proxy
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluent-bit-app-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluent-bit-app-role
subjects:
  - kind: ServiceAccount
    name: fluent-bit-app
    namespace: fluent-bit
```

```shell
kubectl apply -f rbac.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-app-config
  namespace: fluent-bit
  labels:
    k8s-app: fluent-bit
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush                     5
        Grace                     30
        Log_Level                 info
        Daemon                    off
        HTTP_Server               ${HTTP_SERVER}
        HTTP_Listen               0.0.0.0
        HTTP_Port                 ${HTTP_PORT}
        storage.path              /var/fluent-bit/state/flb-storage/
        storage.sync              normal
        storage.checksum          off
        storage.backlog.mem_limit 5M
    @INCLUDE host-log.conf

  host-log.conf: |
    [INPUT]
        Name                tail
        Tag                 host.<Deployment Name>.dmesg
        Path                /var/log/containers/*<Deployment Name>-deployment-*

    [OUTPUT]
        Name                cloudwatch_logs
        Match               host.<Deployment Name>.*
        region              ap-northeast-2
        log_group_name      <CloudWatch_Log_Group_Name>
        log_stream_prefix   from-fluent-bit-
        auto_create_group   true
```

```shell
kubectl apply -f cm.yaml
```

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: fluent-bit
  labels:
    k8s-app: fluent-bit
    version: v1
    kubernetes.io/cluster-service: "true"
spec:
  selector:
    matchLabels:
      k8s-app: fluent-bit
  template:
    metadata:
      labels:
        k8s-app: fluent-bit
        version: v1
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: fluent-bit
        image: public.ecr.aws/aws-observability/aws-for-fluent-bit:stable
        imagePullPolicy: Always
        env:
            - name: AWS_REGION
              valueFrom:
                configMapKeyRef:
                  name: fluent-bit-cluster-info-app
                  key: logs.region
            - name: CLUSTER_NAME
              valueFrom:
                configMapKeyRef:
                  name: fluent-bit-cluster-info-app
                  key: cluster.name
            - name: HTTP_SERVER
              valueFrom:
                configMapKeyRef:
                  name: fluent-bit-cluster-info-app
                  key: http.server
            - name: HTTP_PORT
              valueFrom:
                configMapKeyRef:
                  name: fluent-bit-cluster-info-app
                  key: http.port
            - name: READ_FROM_HEAD
              valueFrom:
                configMapKeyRef:
                  name: fluent-bit-cluster-info-app
                  key: read.head
            - name: READ_FROM_TAIL
              valueFrom:
                configMapKeyRef:
                  name: fluent-bit-cluster-info-app
                  key: read.tail
            - name: HOST_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: HOSTNAME
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.name
            - name: CI_VERSION
              value: "k8s/1.3.23"
        resources:
            limits:
              memory: 200Mi
            requests:
              cpu: 500m
              memory: 100Mi
        volumeMounts:
        - name: fluentbitstate
          mountPath: /var/fluent-bit/state
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluent-bit-app-config
          mountPath: /fluent-bit/etc/
        - name: runlogjournal
          mountPath: /run/log/journal
          readOnly: true
        - name: dmesg
          mountPath: /var/log/dmesg
          readOnly: true
      terminationGracePeriodSeconds: 10
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      volumes:
      - name: fluentbitstate
        hostPath:
          path: /var/fluent-bit/state
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluent-bit-app-config
        configMap:
          name: fluent-bit-app-config
      - name: runlogjournal
        hostPath:
          path: /run/log/journal
      - name: dmesg
        hostPath:
          path: /var/log/dmesg
      serviceAccountName: fluent-bit-app
      nodeSelector:
        kubernetes.io/os: linux
```

```shell
kubectl apply -f ds.yaml
```