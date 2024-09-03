<h1 align="center"> Create ingress </h1>

# Install ALB Controller on helm

```shell
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

# Install ALB Controller on helm with use Values

```shell
cat <<EOF> values.yaml
nodeSelector: {
  eks.amazonaws.com/nodegroup: <EKS Node Group Name>
}
EOF
```

```shell
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -f values.yaml
```

<br>

# Install Karpenter in Fargate
```shell
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set vpcId=<VPC_ID>
```

<br>

```shell
kubectl patch deployment aws-load-balancer-controller -n kube-system \
  --type=json -p='[{"op": "add", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1fargate-profile", "value":"kube-system"}]'

kubectl rollout restart deployment aws-load-balancer-controller -n kube-system
```

# Create ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <Ingress Name>
  namespace: <Namespace>
  annotations:
    <key>: <value>
spec:
  ingressClassName: alb
  rules:
  - http:
      paths: Prefix 
      - pathType: 
        path: /
        backend:
          service:
            name: <service name>
            port:
              number: <Port>
```

# Create ingress
```shell
kubectl apply -f ingress.yaml
```

<h1 align="center"> install ALB Controller </h1>

----

# Attach Subnet Tag

```
Public
Key = kubernetes.io/role/elb
Value = 1
```

```
Private
Key = kubernetes.io/role/internal-elb
Value = 1