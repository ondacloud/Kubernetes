### Setup Namespace
```shell
NAMESPACE_NAME="demo"
```

```shell
sed -i "s|$NAMESPACE_NAME|$NAMESPACE_NAME|g" namespace.yaml
```

```shell
kubectl apply -f namespace.yaml
```