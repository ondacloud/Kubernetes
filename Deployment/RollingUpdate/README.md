<h1 align="center"> Create Deployment on RollingUpdate</h1>

# What is RollingUpdate on Deployment?
allow Deployments' update to take place with zero downtime by incrementally updating Pods instances with new ones

----
# Create Deployment on RollingUpdate
```
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
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 50%
      maxUnavailable: 50%
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
```
kubectl apply -f deployment.yaml
```