<h1 align="center"> Create Taint </h1>

# ADD Taint
```shell
kubectl taint node <Node Name> <key>=<value>:<effect>
```

# Delete Taint
```shell
kubectl taint node <Node Name> <key>=<value>:<effect> -
```