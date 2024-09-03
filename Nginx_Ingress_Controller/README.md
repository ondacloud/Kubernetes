<h1 align="center"> Create Nginx Ingress Controller </h1>

```shell
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/aws/deploy.yaml
```

```yaml
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: /healthcheck
```
> annotations부분에 healthcheck-path를 추가해줍니다.

```yaml
nodeSelector:
	eks.amazonaws.com/nodegroup: <EKS Node Group Name>
```
> Deployment 부분 하단에 Node Selector를 추가해줍니다.

```shell
kubectl apply -f deploy.yaml
```

```shell
kubectl describe deploy ingress-nginx-controller -n ingress-nginx | grep ingress-class
```
> --ingress-class=nginx가 출력되는지 확인합니다.

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
      - path: /v1/
        pathType: Prefix
        backend:
          service:
            name: <Service Name>
            port:
              number: 8080
status:
  loadBalancer:
    ingress:
    - ip: SVC_ID
```

```shell
SVC_ID=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o json | jq -r .spec.clusterIP)
```

```shell
sed -i "s|SVC_ID|$SVC_ID|g" ingress.yaml
```

```shell
kubectl apply -f ingress.yaml
```