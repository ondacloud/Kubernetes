<h1 align="center"> Create Deployment on Recreate</h1>

# What is Recreate on Deployment?
an all-or-nothing process that lets you update an application immediately, with some downtime

----
# Create Deployment on Recreate

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-dpm
  namespace: dev-ns
  labels:
    app: dev
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dev
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: dev
    spec:
      containers:
      - name: dev-cnt
        image: <image>
        ports:
        - containerPort: <Port>
```

# Create Deployment

```shell
kubectl apply -f deployment.yaml
```