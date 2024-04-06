## Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <Ingress Name>
  namespace: <Namespace>
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: <ALB Name>
    alb.ingress.kubernetes.io/scheme: internet-facing
    # alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}'
    alb.ingress.kubernetes.io/healthcheck-path: <Path>
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '5'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '3'
    alb.ingress.kubernetes.io/healthy-threshold-count: '3'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    alb.ingress.kubernetes.io/target-group-attributes: deregistration_delay.timeout_seconds=30
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: <Service Name>
            port:
              number: 80
```