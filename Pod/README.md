<h1 align="center"> Create pod </h1>

# Create pod
```
apiVersion: v1
kind: Pod
metadata:
  name: dev-pod
	labels:
	app: dev
spec:
  containers:
  - name: dev-container
    image: <image>
    ports:
    - containerPort: <Port>
```

# Create pod
```
kubectl apply -f pod.yaml
```