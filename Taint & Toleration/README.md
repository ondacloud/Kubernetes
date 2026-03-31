### Setup Taint & Toleration
**Taint**
```shell
# Add Taint
kubectl taint node <NODE_GROUP_NAME> <KEY>=<VALUE>:<EFFECT>

# Delete Taint
kubectl taint node <NODE_GROUP_NAME> <KEY>=<VALUE>:<EFFECT> -
```

**Toleration**
```yaml
# All Taint Allow
tolerations:
- operator: Exists

# Taint Allow with Key Name is Role
tolerations:
- key: role
	operator: Exists

# Taint Allow with Key Name is Role and Effect is NoExecute
tolerations:
- ket: role
	operator: Exists
	effect: NoExecute

# Taint Allow with Role=System:Effect=NoSchedule
tolerations:
- key: role
  operator: Equal
  value: system
  effect: NoSchedule
```