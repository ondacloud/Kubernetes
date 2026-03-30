```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
```

```shell
sed -i "s|ACCOUNT_ID|$ACCOUNT_ID|g" constraint-repository.yaml
sed -i "s|REGION_CODE|$REGION_CODE|g" constraint-repository.yaml
```

```shell

```

```shell
sed -i "s|ECR_URL|$ECR_URL|g" allowed-repository.yaml
sed -i "s|IMAGE_TAG|$IMAGE_TAG|g" allowed-repository.yaml
```