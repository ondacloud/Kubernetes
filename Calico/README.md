### Setup on Calico
[**Calico Release**](https://github.com/projectcalico/calico/releases)

```shell
kubectl create ns tigera-operator
```

```shell
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo update
helm install calico projectcalico/tigera-operator \
    --version v3.31.4 \
    --namespace tigera-operator \
    -f values.yaml
```

```shell
kubectl patch installation default --type='json' -p='[{"op": "replace", "path": "/spec/cni", "value": {"type":"Calico"} }]'
```

```shell
curl -L https://github.com/projectcalico/calico/releases/download/v3.31.4/calicoctl-linux-amd64 -o calicoctl
chmod +x calicoctl
sudo mv calicoctl /usr/local/bin
```

```yaml
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: allow-communication-for-a-pod
spec:
  selector: app == 'a-pod'
  egress:
    - action: Allow
  ingress:
    - action: Allow
      source:
        selector: app == 'b-pod'
    - action: Deny
      source:
        selector: app == 'c-pod'
```

```shell
kubectl apply -f network-policy.yaml
```