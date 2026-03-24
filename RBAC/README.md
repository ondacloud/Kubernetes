### Setup RBAC
**Role**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: <ROLE_NAME>
  namespace: <NAMESPACE>
rules:
- apiGroups: [""] 
  resources: ["<VALUE>"]
  verbs: ["<VALUE>", "<VALUE>", "<VALUE>"]
```

**RoleBdining**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: <ROLEBINDING_NAME>
  namespace: <NAMESPACE>

roleRef:
  kind: ClusterRole
  name: <CLUSTERROLE_NAME>
  apiGroup: rbac.authorization.k8s.io
  
subjects:
- kind: User
  name: <USER_NAME>
  apiGroup: rbac.authorization.k8s.io

- kind: ServiceAccount
  name: <SERVICEACCOUNT_NAME>
  namespace: <NAMESPACE>

- kind: Group
  name: <GROUP_NAME>
  apiGroup: rbac.authorization.k8s.io
```

**ClusterRole**
```yaml
apiVersion: rbac.authorziation.k8s.io/v1
kind: ClusterRole
metadata:
  name: <CLUSTERROLE_NAME>
rules:
- apiGroups: [""]
  resources: ["<value>"]
  verbs: ["<value>", "<value>", "<value>"]
```

**ClusterRoleBinding**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: <CLUSTERROLEBINDING_NAME>
  
roleRef:
- kind: ClusterRole
  name: <CLUSTER_ROLE_NAME>
  apiGroup: rbac.authorization.k8s.io
  
subjects:
- kind: Group
  name: <GROUP_NAME>
  apiGroup: rbac.authorization.k8s.io
```