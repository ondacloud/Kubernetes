<h1 align="center"> Create Job </h1>

# Create Job
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: <Job Name>
  namespace: <Namespace>
spec:
  template:
    spec:
      containers:
      - name: <Container Name>
        image: <IMAGE>
        command: ["sh", "-c", "sleep 10"]
      restartPolicy: Never
  backoffLimit: 3
```

```shell
kubectl apply -f job.yaml
```

# Result Value
```shell
kubectl get job -n <Namespace>
```

```shell
kubectl get po -n <Namespace>
```
| Pod를 조회한 후 STATUS가 Completed면 정상적으로 생성된 것을 확인 할 수 있습니다.