### Setup on OPA Gatekeeper
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
```

```shell
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.17.1/deploy/gatekeeper.yaml
```

```shell
kubectl get pods -n gatekeeper-system
```

```shell
# audit-controller log 확인
kubectl logs -l control-plane=audit-controller -n gatekeeper-system

# gatekeeper-system log 확인
kubectl logs -l control-plane=controller-manager -n gatekeeper-system
```