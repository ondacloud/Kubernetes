<h1 align="center"> Create Deployment on HealthCheck</h1>

# What is HealthCheck on Deployment?
Continue to check the status of the pod.

----
# Create Deployment on HealthCheck

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
        startupProbe:
          httpGet:
            path: /healthcheck
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 10
          failureThreshold: 12
          successThreshold: 1
        readinessProbe:
          httpGet:
            path: /healthcheck
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 10
          failureThreshold: 3
          successThreshold: 1
        livenessProbe:
          httpGet:
            path: /healthcheck
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 10
          failureThreshold: 6
          successThreshold: 1
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh","-c","sleep 30"]
      terminationGracePeriodSeconds: 10
```

# Create Deployment

```shell
kubectl apply -f deployment.yaml
```