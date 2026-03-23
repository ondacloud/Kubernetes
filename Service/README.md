### Setup Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-svc
  namespace: demo
spec:
  selector:
    app: demo
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

```shell
kubectl apply -f service.yaml
```