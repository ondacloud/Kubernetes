### Setup on Secrets Store CSI Driver
```shell
SECRETS_MANAGER_NAME="demo-secrets"
REGION_CODE="ap-northeast-2"
```

```shell
helm repo update
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
    -n kube-system \
    -f values.yaml
```

```shell
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
```

```shell
SECRETS_MANAGER_ARN=$(aws secretsmanager list-secrets --query "SecretList[?Name=='$SECRETS_MANAGER_NAME'].ARN" --output text)
sed -i "s|SECRETS_MANAGER_ARN|$SECRETS_MANAGER_ARN|g" secret-policy.json
sed -i "s|SECRETS_MANAGER_ARN|$SECRETS_MANAGER_ARN|g" secret-provider.yaml
```

```shell
POLICY_ARN=$(aws --region $REGION_CODE --query Policy.Arn --output text iam create-policy --policy-name secrets-policy --policy-document file://secret-policy.json)
```

```shell
eksctl utils associate-iam-oidc-provider \
    --region "$REGION_CORD" \
    --cluster "$EKS_CLUSTER_NAME" \
    --approve
```

```shell
eksctl create iamserviceaccount \
    --name secrets-cert-controller \
    --region "$REGION_CORD" \
    --cluster "$EKS_CLUSTER_NAME" \
    --namespace=demo \
    --attach-policy-arn "$POLICY_ARN" \
    --override-existing-serviceaccounts \
    --approve
```

```shell
OIDC_PROVIDER_URL=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | sed 's/^https:\/\///')
OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, '$OIDC_PROVIDER_URL')].Arn" --output text)
```

```shell
sed -i "s|OIDC_PROVIDER_ARN|$OIDC_PROVIDER_ARN|g" assume-role-policy.json
sed -i "s|OIDC_PROVIDER_URL|$OIDC_PROVIDER_URL|g" assume-role-policy.json
```

```shell
aws iam create-role --role-name secrets-role --assume-role-policy-document file://assume-role-policy.json > /dev/null
aws iam attach-role-policy --role-name secrets-role --policy-arn $POLICY_ARN
```

```shell
kubectl apply -f secret-provider.yaml
```