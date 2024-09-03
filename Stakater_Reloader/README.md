<h1 align="center"> Stakater Reloader </h1>

```shell
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
helm install reloader stakater/reloader
```

```yaml
  annotations:
    reloader.stakater.com/auto: "true"
```
> Deployment 부분에 annotations를 추가합니다.