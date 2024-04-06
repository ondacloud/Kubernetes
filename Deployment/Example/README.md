## Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <Deployment Name>
  namespace: <Namespace>
  labels:
    app: worker
spec:
  replicas: 2
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      containers:
      - name: <Container Name>
        image: <Image>
        ports:
        - containerPort: 80
```