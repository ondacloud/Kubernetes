### Setup EFS CSI Driver
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
EFS_NAME="demo-efs"
EFS_ID=$(aws efs describe-file-systems --query "FileSystems[?Name=='$EFS_NAME'].FileSystemId" --output text)
EKS_CLUSTER_OIDC=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -c 9-100)
```

```shell
cat <<\EOF> aws-efs-csi-driver-trust-policy.json
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
aws iam create-role --role-name AmazonEKS_EFS_CSI_DriverRole --assume-role-policy-document file://aws-efs-csi-driver-trust-policy.json
```

<!-- ```shell
eksctl create addon --name aws-efs-csi-driver --cluster $CLUSTER_NAME --service-account-role-arn arn:aws:iam::$ACCOUNT_ID:role/AmazonEKS_EFS_CSI_DriverRole --force
``` -->

```shell
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
   --namespace kube-system \
   --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/eks/aws-efs-csi-driver \
   --set controller.serviceAccount.create=false \
   --set controller.serviceAccount.name=efs-csi-controller-sa
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
  namespace: demo
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: EFS_ID
```

```shell
sed -i "s|EFS_ID|$EFS_ID|g" pv.yaml
```

```shell
kubectl apply -f pv.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
  namespace: demo
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```

```shell
kubectl apply -f pvc.yaml
```

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
  namespace: dev-ns
provisioner: efs.csi.aws.com
```

```shell
kubectl apply -f sc.yaml
```

```shell
mkdir ~/dist/
```

```shell
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $EFS_ID.efs.$REGION_CODE.amazonaws.com:/ ~/dist/
```