### Setup External DNS
```shell
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
ROOT_DOMAIN="demo.local"
SUB_DOMAIN="web.demo.local"
VPC_NAME="demo-vpc"
VPC_ID=$(aws ec2 describe-vpcs --filter Name=tag:Name,Values=$VPC_NAME --query "Vpcs[].VpcId" --output text)
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
POLICY_ARN=$(aws --region $REGION_CODE --query Policy.Arn --output text iam create-policy --policy-name AllowExternalDNSUpdates --policy-document file://external-dns-policy.json)
```

```shell
eksctl create iamserviceaccount \
    --cluster $EKS_CLUSTER_NAME \
    --name "external-dns" \
    --namespace default \
    --attach-policy-arn $POLICY_ARN$ \
    --approve
```

```shell
aws route53 create-hosted-zone \
    --name "$ROOT_DOMAIN." \
    --caller-reference "external-dns-test-$(date +%s)" \
    --vpc "VPCRegion=$REGION_CODE,VPCId=$VPC_ID" \
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
            - --domain-filter=ROOT_DOMAIN
            - --provider=aws
            - --policy=upsert-only
            - --aws-zone-type=private 
            - --registry=txt
            - --txt-owner-id=external-dns
            # - --namespace=demo #해당 secsion 추가 시 해당 namespace에서만 external-dns를 사용할 수 있음
          env:
            - name: AWS_DEFAULT_REGION
              value: REGION_CODE
```

```shell
sed -i "s|ROOT_DOMAIN|$ROOT_DOMAIN|g" external-dns.yaml
sed -i "s|REGION_CODE|$REGION_CODE|g" external-dns.yaml
```

```shell
kubectl apply -f external-dns.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ing
  namespace: demo
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: demo-alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    # alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/healthcheck-path: /healthcheck
    external-dns.alpha.kubernetes.io/hostname: SUB_DOMAIN_NAME
    # external-dns.alpha.kubernetes.io/target: demo.example.com # CNAME
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '5'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '3'
    alb.ingress.kubernetes.io/healthy-threshold-count: '3'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    alb.ingress.kubernetes.io/target-group-attributes: deregistration_delay.timeout_seconds=30
    alb.ingress.kubernetes.io/actions.response-404: >
      {"type":"fixed-response","fixedResponseConfig":{"contentType":"text/plain","statusCode":"404","messageBody":"404 Not Found"}}
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /demo
        pathType: Prefix
        backend:
          service:
            name: demo-svc
            port:
              number: 8080
      - path: /healthcheck
        pathType: ImplementationSpecific
        backend:
          service:
            name: targets
            port:
              name: use-annotation
  defaultBackend:
      service:
        name: response-404
        port:
          name: use-annotation
```

```shell
sed -i "S|SUB_DOMAIN|$SUB_DOMAIN|g" ingress.yaml
```

```shell
kubectl apply -f ingress.yaml
```

```shell
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$ROOT_DOMAIN." --query HostedZones[0].Id --out text)
```

```shell
aws route53 list-resource-record-sets --output text --hosted-zone-id $ZONE_ID --query "ResourceRecordSets[?Type == 'NS'].ResourceRecords[*].Value | []" | tr '\\t' '\\n'
```

```shell
aws route53 list-resource-record-sets --output json --hosted-zone-id $ZONE_ID   --query "ResourceRecordSets[?Name == '$SUB_DOMAIN.']|[?Type == 'A']"
```

```shell
dig +short $SUB_DOMAIN
```