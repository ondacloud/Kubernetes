## Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: <Service Name>
  namespace: <Namespace>
spec:
  selector:
    app: worker
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```