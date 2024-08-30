<h1 align="center"> Create Kubernetes DashBoard </h1>

# ENV
```shell
CLUSTER_NAME="<EKS_CLUSTER_NAME>"
```

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl proxy --port=8080 --address='0.0.0.0' --disable-filter=true &
localhost:8080/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
aws eks get-token --cluster-name $CLUSTER_NAME | jq -r '.status.token'
```
|localhost 대신 EC2 Public CIDR로 접근 할 수 있습니다.