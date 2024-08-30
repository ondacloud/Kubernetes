## Service

**NLB Instance**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <Service Name>
  namespace: <Namespace>
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-name: <NLB Name>
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    # service.beta.kubernetes.io/aws-load-balancer-scheme: internal
    # service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: http
    # service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: /healthcheck
    # service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: "8080"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "5"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "3"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold: "3"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
spec:
  selector:
    app: worker
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: LoadBalancer
```

<br>

**NLB IP**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <Service Name>
  namespace: <Namespace>
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb-ip"
    service.beta.kubernetes.io/aws-load-balancer-name: <NLB Name>
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    # service.beta.kubernetes.io/aws-load-balancer-scheme: internal
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    # service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: http
    # service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: /healthcheck
    # service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: "8080"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "5"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "3"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold: "3"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
spec:
  selector:
    app: worker
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  type: LoadBalancer
```