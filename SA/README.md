<h1 align="center"> Create SA </h1>

```shell
EKS_CLUSTER_NAME="<CLUSTER_NAME>"
REGION_CODE=$(aws configure get region --output text)
```

```shell
eksctl create iamserviceaccount \
    --name <Service Account Name> \
    --region=$REGION_CODE \
    --cluster $EKS_CLUSTER_NAME \
    --namespace=wsi\
    --attach-policy-arn "<IAM_POLICY_ARN>" \
    --override-existing-serviceaccounts \
    --approve
```