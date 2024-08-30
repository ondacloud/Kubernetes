<h1 align="center"> Create External-DNS </h1>

# Install External-DNS

```shell
export CLUSTER_NAME=<Cluster Name>
export REGION_CODE=$(aws configure get region)
export vpc_id=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId[]" --output text)
```

```shell
cat <<EOF> external-dns-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets",
        "route53:ListTagsForResource"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
```

```shell
aws iam create-policy --policy-name "AllowExternalDNSUpdates" --policy-document file://./external-dns-policy.json
```

```shell
eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --name "external-dns" \
    --namespace default \
    --attach-policy-arn arn:aws:iam::250328188836:policy/AllowExternalDNSUpdates \ --approve
```

```shell
aws route53 create-hosted-zone \
    --name "infra.local." \
    --caller-reference "external-dns-test-$(date +%s)" \
    --vpc "VPCREGION_CODE=$REGION_CODE,VPCId=$vpc_id" \
    --hosted-zone-config PrivateZone=true
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
  labels:
    app.kubernetes.io/name: external-dns
rules:
  - apiGroups: [""]
    resources: ["services","endpoints","pods","nodes"]
    verbs: ["get","watch","list"]
  - apiGroups: ["extensions","networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get","watch","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
  labels:
    app.kubernetes.io/name: external-dns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
  - kind: ServiceAccount
    name: external-dns
    namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  labels:
    app.kubernetes.io/name: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app.kubernetes.io/name: external-dns
  template:
    metadata:
      labels:
        app.kubernetes.io/name: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
        - name: external-dns
          image: registry.k8s.io/external-dns/external-dns:v0.13.5
          args:
            - --source=service
            - --source=ingress
            - --domain-filter=infra.local
            - --provider=aws
            - --policy=upsert-only
            - --aws-zone-type=private 
            - --registry=txt
            - --txt-owner-id=external-dns
            # - --namespace=skills #해당 secsion 추가 시 해당 namespace에서만 external-dns를 사용할 수 있음
          env:
            - name: AWS_DEFAULT_REGION_CODE
              value: ap-northeast-2
```

```shell
kubectl apply -f external-dns.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <Ingress Name>
  namespace: <Namespace>
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/load-balancer-name: <ALB Name>
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    external-dns.alpha.kubernetes.io/hostname: web.dev.local #생성 할 Rout53 HostName을 정의합니다.
    external-dns.alpha.kubernetes.io/aws-weight: "100"
    external-dns.alpha.kubernetes.io/set-identifier: "3"
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: <Service Name>
            port:
              number: 80
```

```shell
kubectl apply -f ingress.yaml
```

```shell
ZONE_ID=$(aws route53 list-hosted-zones-by-name --output json --dns-name "infra.local." --query HostedZones[0].Id --out text)
```

```shell
aws route53 list-resource-record-sets --output text --hosted-zone-id $ZONE_ID --query "ResourceRecordSets[?Type == 'NS'].ResourceRecords[*].Value | []" | tr '\\t' '\\n'
```

```shell
aws route53 list-resource-record-sets --output json --hosted-zone-id $ZONE_ID   --query "ResourceRecordSets[?Name == 'web.infra.local.']|[?Type == 'A']"
```

```shell
dig +short web.infra.local
```

```shell
curl web.infra.local/healthz
curl web.infra.local/v1/infra
```