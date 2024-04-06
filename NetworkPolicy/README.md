<h1 align="center"> Create Network Policy </h1>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: <networkpolicy name>
  namespace: <namespace>
spec:
  podSelector:
    matchLabels:
      <key>: <value>
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - ipBlock:
            cidr: <cidr>
            except:
              - <cidr>
        - namespaceSelector:
            matchLabels:
              <key>: <value>
        - podSelector:
            matchLabels:
              <key>: <value>
      ports:
        - protocol: <protocol>
          port: <Port>
  egress:
    - to:
        - ipBlock:
            cidr: <cidr>
      ports:
        - protocol: <protocol>
          port: <Port>
```