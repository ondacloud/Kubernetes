<h1 align="center"> Create RBAC </h1>

# Create Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: <Role name>
  namespace: <namespcae>
rules:
- apiGroups: [""] 
  resources: ["<value>"]
  verbs: ["<vale>", "<vale>", "<vale>"]
```

# Create RoleBiding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: <RoleBinding name>
  namespace: <namespcae>

roleRef:
  kind: ClusterRole
  name: <ClusterRole name>
  apiGroup: rbac.authorization.k8s.io
  
subjects:
- kind: User
  name: <User name>
  apiGroup: rbac.authorization.k8s.io

- kind: ServiceAccount
  name: <ServiceAccout name>
  namespace: <namespcae>

- kind: Group
  name: <Group name>
  apiGroup: rbac.authorization.k8s.io
```

# Create ClusterRole

```yaml
apiVersion: rbac.authorziation.k8s.io/v1
kind: ClusterRole
metadata:
  name: <ClusterRole name>
rules:
- apiGroups: [""]
  resources: ["<value>"]
  verbs: ["<value>", "<value>", "<value>"]
```

# Create ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: <ClusterRoleBinding name>
  
roleRef:
- kind: ClusterRole
  name: <ClusterRole name>
  apiGroup: rbac.authorization.k8s.io
  
subjects:
- kind: Group
  name: <Group name>
  apiGroup: rbac.authorization.k8s.io
```