<h1 align="center"> Create Kyverno </h1>


# [Install Kyverno](https://kyverno.io/docs/installation/methods/)

```shell
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.11.1/install.yaml
```


```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: enforce
  rules:
  - name: check-for-labels
    match:
      resources:
        kinds:
        - Pod
        namespaces:
        - "prod"
    validate:
      message: "label 'app.security.kubernetes.io' is not passed"
      pattern:
        metadata:
          labels:
            app.security.kubernetes.io: "pass"
  - name: check-for-image-tag
    match:
      resources:
        kinds:
        - Pod
        namespaces:
        - "default"
    validate:
      message: "Using a mutable image tag e.g. 'latest' is not allowed."
      pattern:
        spec:
          containers:
          - image: "!*:latest"
```

```shell
kubectl apply -f policy.yaml
```