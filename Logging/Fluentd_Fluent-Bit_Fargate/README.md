<h1 align="center"> Create Fluentd to Fluent-Bit </h1>

```shell
EKS_CLUSTER_NAME="<CLUSTER_NAME>"
EKS_NODE_GROUP_NAME="<NODE_GROUP_NAME>"
REGION_CODE=$(aws configure get region --output text)
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fluentd
  labels:
    name: amazon-cloudwatch
```

```shell
kubectl apply -f ns.yaml
```

```shell
eksctl create iamserviceaccount \
    --name fluentd \
    --region=$REGION_CODE \
    --cluster $EKS_CLUSTER_NAME \
    --namespace=fluentd \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess \
    --override-existing-serviceaccounts \
    --approve 
```

```shell
kubectl create configmap cluster-info \
    --from-literal=cluster.name=$EKS_CLUSTER_NAME \
    --from-literal=logs.region=$REGION_CODE -n fluentd
```

```shell
curl -o permissions.json https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json
```

```shell
FARGATE_POLICY_ARN=$(aws --region "$REGION_CODE" --query Policy.Arn --output text iam create-policy --policy-name fargate-policy --policy-document file://permissions.json)
FARGATE_ROLE_NAME=$(aws iam list-roles --query "Roles[?contains(RoleName, 'eksctl-$EKS_CLUSTER_NAME-clus-FargatePodExecutionRole')].RoleName" --output text)
NODE_GROUP=$(aws iam get-role --role-name $FARGATE_ROLE_NAME --query "Role.RoleName" --output text)
```

```shell
aws iam attach-role-policy --policy-arn $FARGATE_POLICY_ARN --role-name $NODE_GROUP
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd-role
rules:
  - apiGroups: [""]
    resources:
      - namespaces
      - pods
      - pods/logs
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluentd-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluentd-role
subjects:
  - kind: ServiceAccount
    name: fluentd
    namespace: fluentd
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: fluentd
  labels:
    k8s-app: fluentd-cloudwatch
data:
  kubernetes.conf: |
    kubernetes.conf
  fluent.conf: |
    @include app.conf
    <match fluent.**>
      @type null
    </match>
  app.conf: |
    <source>
      @type forward
      bind 0.0.0.0
      port 24224
      tag cloudwatch_logs.fluent-bit-a.access
    </source>
    <match cloudwatch_logs.fluent-bit-a.*>
      @type cloudwatch_logs
      log_group_name <CloudWatch_Log_Group_Name>
      log_stream_name app
      auto_create_stream true
      <buffer tag>
        flush_mode immediate
      </buffer>
    </match>
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: fluentd
spec:
  selector:
    matchLabels:
      k8s-app: fluentd-cloudwatch
  template:
    metadata:
      labels:
        k8s-app: fluentd-cloudwatch
      annotations:
        configHash: 8915de4cf9c3551a8dc74c0137a3e83569d28c71044b0359c2578d2e0461825
    spec:
      serviceAccountName: fluentd
      terminationGracePeriodSeconds: 30
      initContainers:
        - name: copy-fluentd-config
          image: busybox
          command: ['sh', '-c', 'cp /config-volume/..data/* /fluentd/etc']
          volumeMounts:
            - name: config-volume
              mountPath: /config-volume
            - name: fluentdconf
              mountPath: /fluentd/etc
        - name: update-log-driver
          image: busybox
          command: ['sh','-c','']
      containers:
        - name: fluentd-cloudwatch
          image: fluent/fluentd-kubernetes-daemonset:v1.10.3-debian-cloudwatch-1.0
          env:
            - name: AWS_REGION
              valueFrom:
                configMapKeyRef:
                  name: cluster-info
                  key: logs.region
            - name: CLUSTER_NAME
              valueFrom:
                configMapKeyRef:
                  name: cluster-info
                  key: cluster.name
            - name: CI_VERSION
              value: "k8s/1.3.24"
            - name: FLUENT_CONTAINER_TAIL_PARSER_TYPE
              value: /^(?<time>.+) (?<stream>stdout|stderr) (?<logtag>[FP]) (?<log>.*)$/
          resources:
            limits:
              memory: 400Mi
            requests:
              cpu: 100m
              memory: 200Mi
          volumeMounts:
            - name: config-volume
              mountPath: /config-volume
            - name: fluentdconf
              mountPath: /fluentd/etc
            - name: fluentd-config
              mountPath: /fluentd/etc/kubernetes.conf
              subPath: kubernetes.conf
            - name: varlog
              mountPath: /var/log
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true
            - name: runlogjournal
              mountPath: /run/log/journal
              readOnly: true
            - name: dmesg
              mountPath: /var/log/dmesg
              readOnly: true
      volumes:
        - name: config-volume
          configMap:
            name: fluentd-config
        - name: fluentdconf
          emptyDir: {}
        - name: fluentd-config
          configMap:
            name: fluentd-config
            items:
            - key: kubernetes.conf
              path: kubernetes.conf
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
        - name: runlogjournal
          hostPath:
            path: /run/log/journal
        - name: dmesg
          hostPath:
            path: /var/log/dmesg
```

```shell
kubectl apply -f fluentd.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: fluentd-svc
  namespace: fluentd
spec:
  selector:
    k8s-app: fluentd-cloudwatch
  type: ClusterIP
  ports:
    - name : app
      protocol: TCP
      port: 24224
      targetPort: 24224
```

```shell
kubectl apply -f service.yaml
```

```shell
SVC_CLUSTER_IP=$(kubectl get svc -n fluentd -o json | jq -r '.items[].spec.clusterIP')
```

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: app
  namespace: default
data:
  flb_log_cw: "false"
  fluent-bit.conf: |
    [SERVICE]
        Flush               1
        Log_Level           info
        Daemon              off

    [INPUT]
        Name                tail
        Path                /log/*.log
        Tag                 <Deployment Name>
        Refresh_Interval    10
        Mem_Buf_Limit       50MB
        Skip_Long_Lines     On

    [FILTER]
        Name                grep
        Match               *<Deployment Name>*
        Exclude             log /.*healthcheck.*/
        Exclude             log /.*healthcheck.*/
        Exclude             log .*healthcheck.*

    [OUTPUT]
        Name                forward
        Match               *
        Host                SVC_IP
        Port                24224
        Retry_Limit         False
```

```shell
sed -i "s|SVC_IP|$SVC_CLUSTER_IP|g" app.yaml
```

```shell
kubectl apply -f app.yaml
```