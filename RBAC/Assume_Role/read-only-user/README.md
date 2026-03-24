### Setup Assume Role on RBAC
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
EKS_CUSTER_NAME="demoo-eks-cluster"
COMMON_USER_NAME="read-only-user"
```

```shell
aws iam create-user --user-name $COMMON_USER_NAME
```

```shell
cat <<EOF> $COMMON_USER_NAME-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "eks:*"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": "iam:PassRole",
          "Resource": "*",
          "Condition": {
              "StringEquals": {
                  "iam:PassedToService": "eks.amazonaws.com"
              }
          }
      }
  ]
}
EOF
```

```shell
aws iam create-policy --policy-name $COMMON_USER_NAME-policy --policy-document file://$COMMON_USER_NAME-policy.json
```

```shell
cat <<EOF> $COMMON_USER_NAME-assume-role.json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::$ACCOUNT_ID:user/$COMMON_USER_NAME"
			},
			"Action": "sts:AssumeRole"
		}
	]
}
EOF
```

```shell
aws iam create-role --role-name $COMMON_USER_NAME-role --assume-role-policy-document file://$COMMON_USER_NAME-assume-role.json
```

```shell
aws iam attach-role-policy --role-name $COMMON_USER_NAME-role --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$COMMON_USER_NAME-policy
```

```shell
sudo useradd $COMMON_USER_NAME
```

```shell
aws iam create-access-key --user-name $COMMON_USER_NAME
{
    "AccessKey": {
        "UserName": "$COMMON_USER_NAME",
        "AccessKeyId": "AKIATUSFZA6SHLAGRFGY",
        "Status": "Active",
        "SecretAccessKey": "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",
        "CreateDate": "2023-09-24T05:05:55+00:00"
    }
}
```

```shell
aws configure --profile $COMMON_USER_NAME
```

```shell
aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT_ID:role/$COMMON_USER_NAME-role --role-session-name $COMMON_USER_NAME-session --profile $COMMON_USER_NAME
{
    "Credentials": {
        "AccessKeyId": "ASIATUSFZA6SGMTAAFBQ",
        "SecretAccessKey": "BdXZfVQeJuTKxc4v2LtVjq8gK++Tj3wXESTBkEsl",
        "SessionToken": "IQoJb3JpZ2luX2VjEEUaDmFwLW5vcnRoZWFzdC0yIkYwRAIgXK+mOBtmnFVgEhEk+FtcbPieCLH9ECYMcdxKQjlePD0CIH/2Lw/9ZAKpJt5SddzKW9ZGRkX9JBH+jsHIvFbg+ZrmKp8CCD4QARoMMjUwMzI4MTg4ODM2IgxQvE9KezXdXYV6Npkq/AE8/5pnkBd4fRmzS8deivgPi/mdFPFxnESb9hr+vClO2zKAJMSultB/WblIh5X3fIP6HyOj9foBwpikf1LQNlRlKH33iOl13RaaXxqvd7oUWUIjtynIdwQIovDFvEMnq2UUqGgRFieqV6caZL7dYl4EcFuCRumhH50w6IB/A9tP6tPI71I0qqXkJFu7/5mWYi8iUeE9IjGQ6Wv+o6ImZBZuVKeKCUfBEQ7xz8HuDGyffALMUdqIO7RqRUZBB6Xkue4tWOUtxXCBcnZTmlQhEGa81lo3gLmx6Mu0FFsla76+ybv1YfvJ3XRjl2iOTHgCony5Uk5ON6+ox1mPPJww3Ye/qAY6ngF8UMKy4EOeVYQTmBj4k6TVm/uVDNYfgpzjRbdNBNblYvTRkEuGYZnJ00mYZRY4HtOKq7gmr5bHr3X9wV7cfqBLAURvK1dzc/Oss2Ta+hAE3sKtkVm5ObIfulgrq7y1++zaE+fQz08F9GtvEAVhmZmNGLesKODRWssoAKiEFGcXkKvaewAn/43rhvT2n/5ef+1BBXxPXTyEgtEw1KkIRQ==",
        "Expiration": "2023-09-24T06:06:37+00:00"
    },
    "AssumedRoleUser": {
        "AssumedRoleId": "AROATUSFZA6SNH4KK3LUD:read-only-user-session",
        "Arn": "arn:aws:sts::012345678910:assumed-role/read-only-user-role/read-only-user-session"
    }
}
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: read-only-user-role
  namespace: demo
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["list", "get", "describe", "watch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-only-user-rolebinding
  namespace: demo
subjects:
  - kind: Group
    name: read-only-user
roleRef:
  kind: Role
  name: read-only-user-role
  apiGroup: rbac.authorization.k8s.io
```

```shell
kubectl apply -f read-only-user-rbac.yaml
```

```shell
eksctl create iamidentitymapping --cluster $EKS_CUSTER_NAME --arn arn:aws:iam::$ACCOUNT_ID:role/$COMMON_USER_NAME-role --group $COMMON_USER_NAME --username $COMMON_USER_NAME-assume --region $REGION_CODE
```

```shell
sudo -i -u $COMMON_USER_NAME
```

```shell
aws configure
AWS Access Key ID [None]: <read-only-user Assume Access key>
AWS Secret Access Key [None]: <read-only-user Assume Secret Access key>
Default region name [None]: ap-northeast-2
Default output format [None]: json
```

```shell
vim ~/.aws/credentials
aws_security_token = <read-only-user Assume SesstionToken>
```

```shell
aws sts get-caller-identity
{
    "UserId": "AROATUSFZA6SNH4KK3LUD:read-only-user-session",
    "Account": "012345678910",
    "Arn": "arn:aws:sts::012345678910:assumed-role/read-only-user-role/read-only-user-session"
}
```

```shell
aws eks --region $REGION_CODE update-kubeconfig --name $EKS_CUSTER_NAME
```