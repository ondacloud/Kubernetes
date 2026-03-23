### Setup Nginx Ingress Controller
```yaml
controller:
  podAnnotations:
    linkerd.io/inject: ingress
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      # service.beta.kubernetes.io/aws-load-balancer-scheme: internal
```

```shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --create-namespace \
  -f values.yaml
```

```shell
kubectl describe deploy ingress-nginx-controller -n ingress-nginx | grep ingress-class
```
> -ingress-class=nginx가 출력되는지 확인한다.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-nginx
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /v1/dummy
            pathType: Prefix
            backend:
              service:
                name: demo-svc
                port:
                  number: 8080
          - path: /healthcheck
            pathType: Prefix
            backend:
              service:
                name: demo-svc
                port:
                  number: 8080

```

```shell
kubectl apply -f ingress.yaml
```