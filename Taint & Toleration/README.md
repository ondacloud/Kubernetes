### Setup Taint & Toleration
**Taint**
```shell
# Add Taint
kubectl taint node <Node Name> <key>=<value>:<effect>

# Delete Taint
kubectl taint node <Node Name> <key>=<value>:<effect> -
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
```yaml
tolerations:
- key: role
  operator: Equal
  value: system
  effect: NoSchedule
```