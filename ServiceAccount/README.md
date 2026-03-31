### Setup on ServiceAccount
> CLI
```shell
kubectl create sa demo-sa -n demo
```

> Manifest
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: demo-sa
  namespace: demo
```

```shell
kubectl apply -f serviceaccount.yaml
```