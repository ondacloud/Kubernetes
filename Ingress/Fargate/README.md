### Setup Ingress on Fargate
```shell
EKS_CLUSTER_NAME="demo-eks-cluster"
```

```shell
#!/bin/bash
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
PUBLIC_A_SN_NAME="demo-public-a"
PUBLIC_B_SN_NAME="demo-public-b"
PUBLIC_C_SN_NAME="demo-public-c"
PRIVATE_A_SN_NAME="demo-private-a"
PRIVATE_B_SN_NAME="demo-private-b"
PRIVATE_C_SN_NAME="demo-private-c"

PUBLIC_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PUBLIC_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PUBLIC_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_A_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_A_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_B_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_B_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)
PRIVATE_C_SN_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_C_SN_NAME" --query "Subnets[].SubnetId[]" --output text --region $REGION_CODE)

PUBLIC_SN_IDS=("$PUBLIC_A_SN_ID" "$PUBLIC_B_SN_ID" "$PUBLIC_C_SN_ID")
PRIVATE_SN_IDS=("$PRIVATE_A_SN_ID" "$PRIVATE_B_SN_ID" "$PRIVATE_C_SN_ID")

for name in "${PUBLIC_SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/cluster/$EKS_CLUSTER_NAME,Value=shared
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/elb,Value=1
done

for name in "${PRIVATE_SN_IDS[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/cluster/$EKS_CLUSTER_NAME,Value=shared
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/internal-elb,Value=1
done
```

```shell
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -f values.yaml \
  --disable-openapi-validation
```

```shell
kubectl patch deployment aws-load-balancer-controller -n kube-system \
  --type=json -p='[{"op": "add", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1fargate-profile", "value":"kube-system"}]'
```

```shell
kubectl rollout restart deployment aws-load-balancer-controller -n kube-system
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
kubectl apply -f ingress.yaml
```