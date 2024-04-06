<h1 align="center"> Create RBAC from Assume Role - ClusterRole / ClusterRoleBinding </h1>

# ENV
```shell
ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
USERNAME="<USERNAME>"
```

# Create IAM User
```shell
aws iam create-user --user-name $USERNAME
```

# Create Policy.json
```shell
cat <<EOF> $USERNAME-role-policy.json
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
aws iam create-policy --policy-name $USERNAME-policy --policy-document file://$USERNAME-role-policy.json
```

# Create Trust Policy
```shell
cat <<EOF> $USERNAME-assume-role.json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::ACCOUNT:user/USERNAME"
			},
			"Action": "sts:AssumeRole"
		}
	]
}
EOF
```

```shell
sed -i "s|ACCOUNT|$ACCOUNT|g" $USERNAME-assume-role.json
sed -i "s|USERNAME|$USERNAME|g" $USERNAME-assume-role.json
```

```shell
aws iam create-role --role-name $USERNAME-role --assume-role-policy-document file://$USERNAME-assume-role.json
```

# Attach Policy in Role
```shell
aws iam attach-role-policy --role-name $USERNAME-role --policy-arn arn:aws:iam::$ACCOUNT:policy/$USERNAME-policy
```

# Create User
```shell
sudo useradd $USERNAME
```

# Create User Access Key
```shell
aws iam create-access-key --user-name $USERNAME
{
    "AccessKey": {
        "UserName": "USERNAME",
        "AccessKeyId": "AKIATUSFZA6SHLAGRFGY",
        "Status": "Active",
        "SecretAccessKey": "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",
        "CreateDate": "2023-09-24T05:05:55+00:00"
    }
}
```

# Setting User Profile
```shell
aws configure --profile $USERNAME
```

# Create Assume-Role
```shell
aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT:role/$USERNAME-role --role-session-name $USERNAME-session --profile $USERNAME
{
    "Credentials": {
        "AccessKeyId": "ASIATUSFZA6SGMTAAFBQ",
        "SecretAccessKey": "BdXZfVQeJuTKxc4v2LtVjq8gK++Tj3wXESTBkEsl",
        "SessionToken": "IQoJb3JpZ2luX2VjEEUaDmFwLW5vcnRoZWFzdC0yIkYwRAIgXK+mOBtmnFVgEhEk+FtcbPieCLH9ECYMcdxKQjlePD0CIH/2Lw/9ZAKpJt5SddzKW9ZGRkX9JBH+jsHIvFbg+ZrmKp8CCD4QARoMMjUwMzI4MTg4ODM2IgxQvE9KezXdXYV6Npkq/AE8/5pnkBd4fRmzS8deivgPi/mdFPFxnESb9hr+vClO2zKAJMSultB/WblIh5X3fIP6HyOj9foBwpikf1LQNlRlKH33iOl13RaaXxqvd7oUWUIjtynIdwQIovDFvEMnq2UUqGgRFieqV6caZL7dYl4EcFuCRumhH50w6IB/A9tP6tPI71I0qqXkJFu7/5mWYi8iUeE9IjGQ6Wv+o6ImZBZuVKeKCUfBEQ7xz8HuDGyffALMUdqIO7RqRUZBB6Xkue4tWOUtxXCBcnZTmlQhEGa81lo3gLmx6Mu0FFsla76+ybv1YfvJ3XRjl2iOTHgCony5Uk5ON6+ox1mPPJww3Ye/qAY6ngF8UMKy4EOeVYQTmBj4k6TVm/uVDNYfgpzjRbdNBNblYvTRkEuGYZnJ00mYZRY4HtOKq7gmr5bHr3X9wV7cfqBLAURvK1dzc/Oss2Ta+hAE3sKtkVm5ObIfulgrq7y1++zaE+fQz08F9GtvEAVhmZmNGLesKODRWssoAKiEFGcXkKvaewAn/43rhvT2n/5ef+1BBXxPXTyEgtEw1KkIRQ==",
        "Expiration": "2023-09-24T06:06:37+00:00"
    },
    "AssumedRoleUser": {
        "AssumedRoleId": "AROATUSFZA6SNH4KK3LUD:USERNAME-session",
        "Arn": "arn:aws:sts::ACCOUNT:assumed-role/USERNAME-role/USERNAME-session"
    }
}
```

# Create RBAC
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: <Role Name>
  namespace: <Namespace>
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["list", "get", "describe", "watch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: infra-rolebinding
  namespace: <Namespace>
subjects:
  - kind: Group
    name: <USERNAME>
roleRef:
  kind: Role
  name: <Role Name>
  apiGroup: rbac.authorization.k8s.io
```

```shell
kubectl apply -f $USERNAME-rbac.yaml
```

```shell
eksctl create iamidentitymapping --cluster infra-eks-cluster --arn arn:aws:iam::$ACCOUNT:role/$USERNAME-role --group $USERNAME --username $USERNAME-assume
```

# User Access
```shell
sudo -i -u $USERNAME
```

```shell
aws configure
AWS Access Key ID [None]: <USERNAME Assume Access key>
AWS Secret Access Key [None]: <USERNAME Assume Secret Access key>
Default region name [None]: ap-northeast-2
Default output format [None]: json
```

```shell
vim ~/.aws/credentials
aws_security_token = <USERNAME Assume SesstionToken>
```

```shell
aws sts get-caller-identity
{
    "UserId": "AROATUSFZA6SNH4KK3LUD:USERNAME-session",
    "Account": "ACCOUNT",
    "Arn": "arn:aws:sts::ACCOUNT:assumed-role/USERNAME-role/USERNAME-session"
}
```

```shell
aws eks --region ap-northeast-2 update-kubeconfig --name infra-eks-cluster
```