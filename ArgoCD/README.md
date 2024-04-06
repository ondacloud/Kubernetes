<h1 align="center"> ArgoCD </h1>

# Create ArgoCD
```shell
kubectl create ns argocd
```

```shell
cat <<\EOF> argocd-value.yaml
configs:
  cm:
    accounts.image-updater: apiKey
    timeout.reconciliation: 60s
  rbac:
    policy.csv: |
      p, role:image-updater, applications, get, */*, allow
      p, role:image-updater, applications, update, */*, allow
      g, image-updater, role:image-updater
    policy.default: role.readonly
  params:
    server.insecure: true
EOF
```

```shell
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

```shell
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
```

```shell
helm install argocd argo/argo-cd \
    --create-namespace \
    --namespace argocd \
    --values argocd-value.yaml
```

# Join ArgoCD Server
```shell
kubectl port-forward svc/argocd-server -n argocd --address=0.0.0.0 8080:443 &
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
argocd login 127.0.0.1:8080  # ID : admin
argocd account update-password
```

# Create Ingress on ArgoCD Server
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ing
  namespace: argocd
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: argocd-alb
    alb.ingress.kubernetes.io/group.name: argocd-tg
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '5'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '3'
    alb.ingress.kubernetes.io/healthy-threshold-count: '3'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    alb.ingress.kubernetes.io/target-group-attributes: deregistration_delay.timeout_seconds=30
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
```

```shell
kubectl apply -f argocd-ingress.yaml
```