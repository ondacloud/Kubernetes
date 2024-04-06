<h1 align="center"> Create Calico </h1>

# install Calico on helm

```shell
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo update
helm install calico projectcalico/tigera-operator --version v3.25.1
kubectl patch installation default --type='json' -p='[{"op": "replace", "path": "/spec/cni", "value": {"type":"Calico"} }]'
```