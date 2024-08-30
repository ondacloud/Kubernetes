<h1 align="center"> Create External Secret Operator - Basic </h1>

```shell
EKS_CLUSTER_NAME="<EKS_CLUSTER_NAME>"
EKS_NODE_GROUP_NAME="<EKS_NODE_GROUP_NAME>"
REGION_CORD=$(aws configure get region --output text)
NAMESPACE_NAME="<NAMESPPACE_NAME>"
SECRET_NAME="<Secret Manager Name>"
```

```shell
cat >secret-policy.json <<EOF
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
			"Resource": ["*"]
		},
      {
        "Effect": "Allow",
        "Action": ["kms:Decrypt"],
        "Resource": ["*"]
      }
    ]
}
EOF
```

```shell
POLICY_ARN=$(aws --region "$REGION_CORD" --query Policy.Arn --output text iam create-policy --policy-name secretsmanager-policy --policy-document file://secret-policy.json)
```

```shell
eksctl create iamserviceaccount \
    --name external-secrets-cert-controller \
    --region="$REGION_CORD" \
    --cluster "$CLUSTER_NAME" \
    --namespace=<Namespace> \
    --attach-policy-arn "$POLICY_ARN" \
    --override-existing-serviceaccounts \
    --approve
```

```shell
helm repo add external-secrets https://charts.external-secrets.iamserviceaccount
```

```shell
kubectl annotate serviceaccount external-secrets-cert-controller \
  meta.helm.sh/release-name=external-secrets \
  meta.helm.sh/release-namespace=$NAMESPACE_NAME \
  -n $NAMESPACE_NAME \
  --overwrite
```

```shell
kubectl label serviceaccount external-secrets-cert-controller \
  app.kubernetes.io/managed-by=Helm \
  -n $NAMESPACE_NAME \
  --overwrite
```

```shell
cat > values.yaml <<EOF
{
  "installCRDs": true,
  "nodeSelector": {
    "eks.amazonaws.com/nodegroup": "$EKS_NODE_GROUP_NAME"
  },
  "webhook": {
    "nodeSelector": {
      "eks.amazonaws.com/nodegroup": "$EKS_NODE_GROUP_NAME"
    }
  },
  "certController": {
    "nodeSelector": {
      "eks.amazonaws.com/nodegroup": "$EKS_NODE_GROUP_NAME"
    }
  }
}
EOF
```

```shell
helm install external-secrets \
   external-secrets/external-secrets \
   -n kube-system \
   -f values.yaml \
   --set serviceAccount.create=false
```


```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets
  namespace: <Namespace>
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-northeast-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-cert-controller
```

```shell
kubectl apply -f secretstore.yaml
```

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: <Namespace>
spec:
  refreshInterval: 30s
  secretStoreRef:
    name: aws-secrets
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
    - secretKey: MYSQL_USER
      remoteRef:
        key: SECRET_NAME
        property: username
    - secretKey: MYSQL_PASSWORD
      remoteRef:
        key: SECRET_NAME
        property: password
    - secretKey: MYSQL_HOST
      remoteRef:
        key: SECRET_NAME
        property: host
    - secretKey: MYSQL_PORT
      remoteRef:
        key: SECRET_NAME
        property: port
    - secretKey: MYSQL_DBNAME
      remoteRef:
        key: SECRET_NAME
        property: dbname
    - secretKey: REGION
      remoteRef:
        key: SECRET_NAME
        property: aws_region
```

```shell
sed -i "s|SECRET_NAME|$SECRET_NAME|g" external-secret-operator.yaml
```

```shell
kubectl apply -f external-secret-operator.yaml
```