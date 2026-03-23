### Setup AWS-Auth
```shell
EKS_CLUSTER_NAME="demo-eks-cluster"
CODEBUILD_ROLE_NAME="build-role"
```

```shell
CODEBUILD_ROLE_ARN=$(aws iam list-roles --query "Roles[?RoleName=='$CODEBUILD_ROLE_NAME'].Arn" --output text)
```

```shell
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth.yaml
```

```shell
if ! grep -q "$CODEBUILD_ROLE_ARN" aws-auth.yaml; then
  awk -v arn="$CODEBUILD_ROLE_ARN" '
  /mapRoles: \|/ {
    print
    printf "    - groups:\n"
    printf "      - system:masters\n"
    printf "      rolearn: %s\n", arn
    printf "      username: codebuild-admin\n"
    next
  }
  { print }
  ' aws-auth.yaml > tmpfile && mv tmpfile aws-auth.yaml
fi
```

```shell
kubectl apply -f aws-auth.yaml
```

```shell
rm -rf aws-auth.yaml
```

```shell
aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn $CODEBUILD_ROLE_ARN --type STANDARD
```

```shell
aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --principal-arn $CODEBUILD_ROLE_ARN --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster
```