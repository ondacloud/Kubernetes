<h1 align="center"> Create Calico </h1>

# install Calico on Helm
```shell
helm repo add projectcalico https://docs.tigera.io/calico/charts
kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.29.1 --namespace tigera-operator
```

# install Calicoctl on Helm
```shell
curl -L https://github.com/projectcalico/calico/releases/download/v3.29.1/calicoctl-linux-amd64 -o kubectl-calico
chmod +x kubectl-calico
sudo mv kubectl-calico /usr/local/bin/calicoctl
```

```yaml
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: allow-communication-for-a-pod
spec:
  selector: app == 'a'
  egress:
    - action: Allow
  ingress:
    - action: Allow
      source:
        selector: app == 'b'
    - action: Deny
      source:
        selector: app == 'c'
```

```shell
kubectl apply -f networkpolicy.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: a
  labels:
    app: a
spec:
  containers:
    - name: a-cnt
      image: nginx:latest
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: b
  labels:
    app: b
spec:
  containers:
    - name: b-cnt
      image: nginx:latest
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: c
  labels:
    app: c
spec:
  containers:
    - name: c-cnt
      image: nginx:latest
```

```shell
kubectl apply -f a.yaml && kubectl apply -f b.yaml && kubectl apply -f c.yaml
```