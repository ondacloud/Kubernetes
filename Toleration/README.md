<h1 align="center"> Create Toleration </h1>


**Toleration의 값은 Deployment Secsion에 추가합니다.**

# All Taint Allow
```yaml
tolerations:
- operator: Exists
```

# Taint Allow with Key Name is Role
```yaml
tolerations:
- key: role
	operator: Exists
```

# Taint Allow with Key Name is Role and Effect is NoExecute
```yaml
tolerations:
- ket: role
	operator: Exists
	effect: NoExecute
```

# Taint Allow with Role=System:Effect=NoSchedule
```yaml
tolerations:
- key: role
  operator: Equal
  value: system
  effect: NoSchedule
```