<h1 align="center"> Create HPA </h1>

# Install Metrics Server
```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/rele ases/latest/download/components.yaml
```

# Create HPA
**Basic**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: <HPA Name>
  namespace: <Namespace>
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <Deployment Name>
  minReplicas: <Number>
  maxReplicas: <Number>
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: <Number>
```

<br>

**Segmentation**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: <HPA Name>
  namespace: <Namespace>
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <Deployment Name>
  minReplicas: <Number>
  maxReplicas: <Number>
  behavior:
    scaleUp:
      stabilizationWindowSeconds: <Number>
      policies:
      - type: Pods
        value: <Number>
        periodSeconds: <Number>
    scaleDown:
      stabilizationWindowSeconds: 1<Number>
      policies:
      - type: Pods
        value: <Number>
        periodSeconds: <Number>
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: <Number>
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageValue: <Number>Mi

```