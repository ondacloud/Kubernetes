<h1 align="center"> Create Service </h1>

# Create Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: dev-svc
  namespace: dev-ns
  labels:
    app: dev
spec:
  selector:
    app: dev
  ports:
    - protocol: <protocol>
      port: <Port>
      targetPort: <Port>
```

# Create Service
```shell
kubectl apply -f Service.yaml
```