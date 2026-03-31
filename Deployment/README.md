### Setup Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-deploy
  namespace: demo
  labels:
    app: demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
      - name: demo-cnt
        image: IMAGE
        ports:
        - containerPort: 8080
```

> ECR

```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
ECR_NAME="demo-ecr"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com/$ECR_NAME"
IMAGE_TAG="v1.0.0"
```

```shell
sed -i "s|IMAGE|$ECR_URI:$IMAGE_TAG|g" deployment.yaml
```

```shell
kubectl apply -f deployment.yaml
```