### Setup Assume Role on RBAC
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
EKS_CUSTER_NAME="secure-eks-cluster"
ADMIN_USER_NAME="sysop"
```

```shell
aws iam create-user --user-name $ADMIN_USER_NAME
```

```shell
cat <<EOF> $ADMIN_USER_NAME-policy.json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"eks:*",
				"ssm:*"
			],
			"Resource": "*"
		}
	]
}
EOF
```

```shell
aws iam create-policy --policy-name $ADMIN_USER_NAME-policy --policy-document file://$ADMIN_USER_NAME-policy.json
```

```shell
aws iam attach-user-policy --user-name $ADMIN_USER_NAME --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$ADMIN_USER_NAME-policy
```

```shell
sudo useradd $ADMIN_USER_NAME
```

```shell
aws iam create-access-key --user-name $ADMIN_USER_NAME
{
    "AccessKey": {
        "UserName": "sysop",
        "AccessKeyId": "AKIATUSFZA6SKAJ2F6ZN",
        "Status": "Active",
        "SecretAccessKey": "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",
        "CreateDate": "2023-09-24T06:06:04+00:00"
    }
}
```

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sysop
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch", "create", "delete", "describe"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sysop
subjects:
- kind: Group
  name: sysop
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: sysop
  apiGroup: rbac.authorization.k8s.io
```

```shell
kubectl apply -f $ADMIN_USER_NAME-rbac.yaml
```

```shell
sudo -i -u $ADMIN_USER_NAME
```

```shell
aws configure
AWS Access Key ID [None]: <sysop Access key>
AWS Secret Access Key [None]: <sysop Secret Access key>
Default region name [None]: ap-northeast-2
Default output format [None]: json
```

```shell
aws sts get-caller-identity
{
    "UserId": "AIDATUSFZA6SB5PUU64PR",
    "Account": "250328188836",
    "Arn": "arn:aws:iam::250328188836:user/sysop"
}
```

```shell
aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CUSTER_NAME
```