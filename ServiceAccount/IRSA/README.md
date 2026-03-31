### Setup on ServiceAccount with IRSA
```shell
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
```

**CLI**
```shell
# Policy
eksctl create iamserviceaccount \
    --region $REGION_CODE \
    --cluster $EKS_CLUSTER_NAME \
    --name demo-sa \
    --namespace demo \
    --attach-policy-arn $IAM_POLICY_ARN \
    --override-existing-serviceaccounts \
    --approve

# Role
eksctl create iamserviceaccount \
    --region $REGION_CODE \
    --cluster $EKS_CLUSTER_NAME \
    --name demo-sa \
    --namespace demo \
    --attach-role-arn $IAM_ROLE_ARN \
    --override-existing-serviceaccounts \
    --approve
```

**Manifest**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: demo-sa
  namespace: demo
  annotations:
    eks.amazonaws.com/role-arn: IAM_ROLE_ARN
```

```shell
sed -i "s|IAM_ROLE_ARN|$IAM_ROLE_ARN|g" serviceaccount.yaml
```

```shell
kubectl apply -f serviceaccount.yaml
```