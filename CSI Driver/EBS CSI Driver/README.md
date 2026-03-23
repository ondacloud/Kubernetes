### Setup EBS CSI Driver
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
EKS_CLUSTER_NAME="demo-eks-cluster"
EKS_APP_NODE_GROUP_NAME="demo-app-node"
EKS_ADDON_NODE_GROUP_NAME="demo-addon-node"
APP_NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_APP_NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
ADDON_NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_ADDON_NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
EKS_CLUSTER_OIDC=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -c 9-100)
```

```shell
cat <<\EOF> aws-ebs-csi-driver-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/EKS_CLUSTER_OIDC"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "EKS_CLUSTER_OIDC:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF
```

```shell
sed -i "s|ACCOUNT_ID|$ACCOUNT_ID|g" aws-ebs-csi-driver-trust-policy.json
sed -i "s|EKS_CLUSTER_OIDC|$EKS_CLUSTER_OIDC|g" aws-ebs-csi-driver-trust-policy.json
```

```shell
aws iam create-role --role-name AmazonEKS_EBS_CSI_DriverRole --assume-role-policy-document file:///aws-ebs-csi-driver-trust-policy.json
```

```shell
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --role-name AmazonEKS_EBS_CSI_DriverRole
```

```shell
eksctl create addon --name aws-ebs-csi-driver --cluster $EKS_CLUSTER_NAME --service-account-role-arn arn:aws:iam::$ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole --force
```

```shell
cat << EOF > ebs-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVolume",
                "ec2:DeleteVolume",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumeStatus",
                "ec2:ModifyVolume",
                "ec2:CreateTags"
            ],
            "Resource": "*"
        }
    ]
}
EOF
```

```shell
aws iam create-policy --policy-name AmazonEBSCSIDriverPolicy --policy-document file://ebs-policy.json
```

```shell
aws iam attach-role-policy --role-name $APP_NODE_GROUP_ROLE_NAME --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonEBSCSIDriverPolicy
aws iam attach-role-policy --role-name $ADDON_NODE_GROUP_ROLE_NAME --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonEBSCSIDriverPolicy
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
  namespace: demo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 10Gi
```

```shell
kubectl apply -f pvc.yaml
```

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
```

```shell
kubectl apply -f sc.yaml
```