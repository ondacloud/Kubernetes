```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
ECR_NAME="demo-ecr"
```

```shell
sed -i "s|ACCOUNT_ID|$ACCOUNT_ID|g" constraint-image.yaml
sed -i "s|REGION_CODE|$REGION_CODE|g" constraint-image.yaml
sed -i "s|ECR_NAME|$ECR_NAME|g" constraint-image.yaml
```