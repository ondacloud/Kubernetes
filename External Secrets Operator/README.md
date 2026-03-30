### Setup on External Secrets Operator
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
APP_EKS_NODE_GROUP_NAME="demo-app-node"
ADDON_EKS_NODE_GROUP_NAME="demo-addon-node"
SECRETS_MANAGER_NAME="demo-secrets"
```

```shell
cat > secret-policy.json <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"secretsmanager:GetResourcePolicy",
				"secretsmanager:GetSecretValue",
				"secretsmanager:DescribeSecret",
				"secretsmanager:ListSecretVersionIds"
			],
			"Resource": [
				"SECRETS_MANAGER_ARN"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"kms:Decrypt"
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
SECRETS_MANAGER_ARN=$(aws secretsmanager list-secrets --query "SecretList[?Name=='$SECRETS_MANAGER_NAME'].ARN" --output text)
```

```shell
sed -i "s|SECRETS_MANAGER_ARN|$SECRETS_MANAGER_ARN|g" secret-policy.json
```

```shell
POLICY_ARN=$(aws --region $REGION_CODE --query Policy.Arn --output text iam create-policy --policy-name secretsmanager-policy --policy-document file://secret-policy.json)
```


```shell
eksctl create iamserviceaccount \
    --name external-secrets-cert-controller \
    --region="$REGION_CORD" \
    --cluster "$EKS_CLUSTER_NAME" \
    --namespace=demo \
    --attach-policy-arn "$POLICY_ARN" \
    --override-existing-serviceaccounts \
    --approve
```

```shell
helm repo add external-secrets https://charts.external-secrets.io
```

```shell
kubectl annotate serviceaccount external-secrets-cert-controller \
  meta.helm.sh/release-name=external-secrets \
  meta.helm.sh/release-namespace=demo \
  -n demo \
  --overwrite
```

```shell
kubectl label serviceaccount external-secrets-cert-controller \
  app.kubernetes.io/managed-by=Helm \
  -n demo \
  --overwrite
```

```shell
helm install external-secrets \
   external-secrets/external-secrets \
   -n demo \
   --set serviceAccount.create=false \
   -f values.yaml
```

```shell
sed -i "s|REGION_CODE|$REGION_CODE|g" secretstore.yaml
sed -i "s|SECRETS_MANAGER_NAME|$SECRETS_MANAGER_NAME|g" external-secret-operator.yaml
```

```shell
kubectl apply -f secretstore.yaml
kubectl apply -f external-secret-operator.yaml
```