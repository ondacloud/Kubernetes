### Setup ArgoCD & Image Updater on CodeCommit
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
CODECOMMIT_NAME="demo-commit"
ECR_NAME="demo-ecr"
```

```shell
kubectl create ns argocd
```

```yaml
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
```

```shell
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
helm install argocd argo/argo-cd \
    --create-namespace \
    --namespace argocd \
    --values argocd-values.yaml
```

```shell
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm -rf argocd-linux-amd64
```

```shell
sudo dnf install -y expect
ARGO_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login --port-forward --port-forward-namespace argocd --plaintext --username admin --password $ARGO_PW 127.0.0.1:8080
expect -c "
spawn argocd account --port-forward-namespace argocd update-password
expect -re \".*Enter.*\"
send \"$ARGO_PW\r\"
expect -re \".*Enter.*\"
send \"Skill53##\r\"
expect -re \".*Confirm.*\"
send \"Skill53##\r\"
interact
"
```

```shell
eksctl create iamserviceaccount \
    --cluster $EKS_CLUSTER_NAME \
    --region $REGION_CODE \
    --name argocd-image-updater \
    --namespace argocd \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
    --approve
```

```yaml
config:
  argocd:
    grpcWeb: true
    serverAddress: "http://argocd-server.argocd"
    insecure: true
    plaintext: true
  logLevel: debug
  registries:
    - name: ECR
      api_url: "https://ACCOUNT_ID.dkr.ecr.REGION_CODE.amazonaws.com"
      prefix: "ACCOUNT_ID.dkr.ecr.REGION_CODE.amazonaws.com"
      ping: true
      insecure: false
      credentials: "ext:/scripts/auth1.sh"
      credsexpire: 10h
authScripts:
  enabled: true
  scripts:
    auth1.sh: |
      #!/bin/sh
      aws ecr --region REGION_CODE get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d
```

```shell
sed -i "s|ACCOUNT_ID|$ACCOUNT_ID|g" argocd-image-updater-values.yaml
sed -i "s|REGION_CODE|$REGION_CODE|g" argocd-image-updater-values.yaml
```

```shell
helm install argocd-image-updater argo/argocd-image-updater \
    --namespace argocd \
    --set serviceAccount.create=false \
    --values argocd-image-updater-values.yaml
```

```shell
kubectl create ns argo-rollouts
```

```shell
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
sudo install -o root -g root -m 0755 kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
rm -rf kubectl-argo-rollouts-linux-amd64
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ing
  namespace: argocd
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: demo-argocd-alb
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
kubectl apply -f ingress.yaml
```

```shell
aws iam create-user --user-name commit-user --tags Key=Name,Value=commit-user > /dev/null 2>&1 || true
```

```shell
aws iam attach-user-policy --user-name commit-user --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitFullAccess
```

```shell
CODECOMMIT_CLONE_URL=$(aws codecommit get-repository --repository-name $CODECOMMIT_NAME --query "repositoryMetadata.cloneUrlHttp" --region $REGION_CODE --output text)
IAM_USER_CODECOMMIT_AUTH=$(aws iam create-service-specific-credential --user-name commit-user --service-name codecommit.amazonaws.com)
CODECOMMIT_AUTH_USERNAME=$(echo $IAM_USER_CODECOMMIT_AUTH | jq -r .ServiceSpecificCredential.ServiceUserName)
CODECOMMIT_AUTH_SECRET_PASSWORD=$(echo $IAM_USER_CODECOMMIT_AUTH | jq -r .ServiceSpecificCredential.ServicePassword)
EKS_CLUSTER_ARN=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.arn" --output text)
```

```shell
echo y | argocd cluster --port-forward-namespace argocd add $EKS_CLUSTER_ARN
```

```shell
argocd repo --port-forward-namespace argocd add $CODECOMMIT_CLONE_URL --username $CODECOMMIT_AUTH_USERNAME --password $CODECOMMIT_AUTH_SECRET_PASSWORD
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: CODECOMMIT_CLONE_URL
    targetRevision: main
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: app
  syncPolicy:
    automated:
      prune: true
      allowEmpty: true
      selfHeal: true
    syncOptions:
        - CreateNamespace=true
```

```shell
sed -i "s|CODECOMMIT_CLONE_URL|$CODECOMMIT_CLONE_URL|g" application.yaml
```

```shell
kubectl apply -f application.yaml
```