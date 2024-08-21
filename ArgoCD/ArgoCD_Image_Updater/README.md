<h1 align="center"> ArgoCD Image Updater </h1>

# Create ArgoCD Image Updater
```shell
eksctl create iamserviceaccount \
    --cluster <Cluster Name> \
    --name argocd-image-updater \
    --namespace argocd \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
    --approve
```

```shell
cat <<\EOF> argocd-image-updater-values.yaml
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
EOF
```

```shell
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
AWS_DEFAULT_REGION=$(aws configure set region ap-northeast-2 && aws configure get region --output text)
```
> Delete Token Command <br> argocd account delete-token --account image-updater image-updater

```shell
sed -i "s|ACCOUNT_ID|$AWS_ACCOUNT_ID|g" argocd-image-updater-values.yaml
sed -i "s|REGION_CODE|$AWS_DEFAULT_REGION|g" argocd-image-updater-values.yaml
```

```shell
helm install argocd-image-updater argo/argocd-image-updater \
    --namespace argocd \
    --set serviceAccount.create=false \
    --values argocd-image-updater-values.yaml
```

```shell
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
sudo install -o root -g root -m 0755 kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

```shell
kubectl argo rollouts version
```

```shell
CODECOMMIT_CLONEURL=$(aws codecommit get-repository --repository-name <CodeCommit Name> --query "repositoryMetadata.cloneUrlHttp" --region ap-northeast-2 --output text)
CC_AUTH=$(aws iam create-service-specific-credential --user-name sysop --service-name codecommit.amazonaws.com)
CC_AUTH_USERNAME=$(echo $CC_AUTH | jq -r .ServiceSpecificCredential.ServiceUserName)
CC_AUTH_SECRET_PASSWORD=$(echo $CC_AUTH | jq -r .ServiceSpecificCredential.ServicePassword)
```

```shell
argocd repo add $CODECOMMIT_CLONEURL --username $CC_AUTH_USERNAME --password $CC_AUTH_SECRET_PASSWORD
```

```shell
EKS_CLUSTER_ARN=$(aws eks describe-cluster --name <Cluster Name> --query "cluster.arn" --output text)
```

```shell
echo y | argocd cluster add $EKS_CLUSTER_ARN
```

```shell
ECR_REPO_URI=$(aws ecr describe-repositories --query "repositories[?repositoryName=='<ECR NAME>'].repositoryUri" --output text)
```

```shell
argocd app create py-app \
    --repo $CODECOMMIT_CLONEURL \
    --path . \
    --self-heal \
    --sync-policy automated \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace app \
    --annotations argocd-image-updater.argoproj.io/image-list=org/app=$ECR_REPO_URI \
    --annotations argocd-image-updater.argoproj.io/org_app.pull-secret=ext:/scripts/auth1.sh \
    --annotations argocd-image-updater.argoproj.io/org_app.update-strategy=latest \
    --upsert
```