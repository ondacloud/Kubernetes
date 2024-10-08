<h1 align="center"> Create Batch </h1>

```shell
EKS_CLUSTER_NAME="<CLUSTER_NAME>"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: batch
  labels:
    name: batch
```

```shell
kubectl apply -f ns.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: batch-cluster-role
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["daemonsets", "deployments", "statefulsets", "replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["clusterroles", "clusterrolebindings"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: batch-cluster-role-binding
subjects:
- kind: User
  name: batch
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: batch-cluster-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: batch-compute-environment-role
  namespace: batch
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["create", "get", "list", "watch", "delete", "patch"]
  - apiGroups: [""]
    resources: ["serviceaccounts"]
    verbs: ["get", "list"]
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["roles", "rolebindings"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: batch-compute-environment-role-binding
  namespace: batch
subjects:
- kind: User
  name: batch
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: batch-compute-environment-role
  apiGroup: rbac.authorization.k8s.io
```

```shell
kubectl apply -f rbac.yaml
```

```shell
eksctl create iamidentitymapping \
    --cluster $EKS_CLUSTER_NAME \
    --arn "arn:aws:iam::$ACCOUNT_ID:role/AWSServiceRoleForBatch" \
    --username batch
```