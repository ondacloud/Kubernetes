<h1 align="center"> Create External Secret Operator - Basic </h1>

```shell
helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace
```

```shell
SECRET_ARN=$(aws secretsmanager list-secrets --query "SecretList[].ARN[]" --output text)
KMS_KEY_ID=$(aws kms create-key --tags TagKey=Name,TagValue=wsi-secret | jq -r '.KeyMetadata.KeyId')
aws kms create-alias --alias-name alias/wsi-secret --target-key-id $KMS_KEY_ID
KMS_ARN=$(aws kms describe-key --key-id $KMS_KEY_ID --query "KeyMetadata.Arn" --output text)
```

```shell
cat <<\EOF> secret-policy.json
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
			"Resource": ["SECRET_ARN"]
		},
      {
        "Effect": "Allow",
        "Action": ["kms:Decrypt"],
        "Resource": ["KEY_ARN"]
      }
    ]
}
EOF
```

```shell
sed -i "s|SECRET_ARN|$SECRET_ARN|g" secret-policy.json
sed -i "s|KEY_ARN|$KMS_ARN|g" secret-policy.json
```

```shell
REGION="ap-northeast-2"
CLUSTER_NAME="wsi-eks-cluster"
POLICY_ARN=$(aws --region "$REGION" --query Policy.Arn --output text iam create-policy --policy-name secretsmanager-policy --policy-document file://secret-policy.json)
```

```shell
eksctl create iamserviceaccount \
	--name external-secrets-cert-controller \
	--region=$REGION \
	--cluster $CLUSTER_NAME \
	--namespace=external-secrets \
	--attach-policy-arn $POLICY_ARN \
	--override-existing-serviceaccounts \
	--approve 
```

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets
  namespace: external-secrets
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
<br>

> SecretStore - Access Key를 사용하려면 아래 코드를 사용합니다.
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets
  namespace: external-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-northeast-2
      auth:
        #secretRef:
          #accessKeyIDSecretRef:
            #name: awssm-secret
            #key: access-key
          #secretAccessKeySecretRef:
            #name: awssm-secret
            #key: secret-access-key  특정 user 즉 특정 configure를 설정하고 싶을 때 사용
        jwt:
          serviceAccountRef:
            name: external-secrets-cert-controller
```
```shell
echo -n <Root Access Key> > ./access-key
echo -n <Root Secret Key> ./secret-access-key
kubectl create secret generic awssm-secret --from-file=./access-key --from-file=./secret-access-key
```

```shell
kubectl apply -f secretstore.yaml
```

```shell
kubectl get secrets -n external-secrets
```

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: external-secrets
spec:
  refreshInterval: 10m #query 빈도 즉 1시간마다 aws에 해당 자격증명을 업데이트한다 ex) 1h 1시간, 10m 10분
  secretStoreRef:
    name: aws-secrets #SecretStore name
    kind: SecretStore
  target:
    name: db-credentials #target name
    creationPolicy: Owner
  data:
    - secretKey: mongodbuser
      remoteRef:
        key: prod/appdata/docudb #Security Manager name
        property: username
    - secretKey: mongodbpassword
      remoteRef:
        key: prod/appdata/docudb
        property: password
  #dataFrom:
  #- extract:
      #key: remote-key-in-the-provider 특정 key를 배출할 때 쓰인다
```

```shell
kubectl apply -f externalsecret.yaml
```

```shell
kubectl get externalSecret -n external-secrets
```

```shell
kubectl get secret db-credentials -n external-secrets -o yaml | grep -i "mongodbpassword:"
```

```shell
kubectl get secret db-credentials -n external-secrets -o yaml | grep -i "mongodbuser:"
```

```shell
echo '<VALUE>' | base64 -d
```