### Setup on Cordon & Drain
**Cordon**
```shell
# ADD Cordon
kubectl cordon <NODE_GROUP_NAME>

# Delete Cordon
kubectl uncordon <NODE_GROUP_NAME>
```

**Drain**
```shell
# Add Drain
kubectl drain <NODE_GROUP_NAME>

# Delete Drain
```shell
kubectl uncordon <NODE_GROUP_NAME>
```