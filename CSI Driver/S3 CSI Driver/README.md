### Setup S3 CSI Driver
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE=ap-northeast-2
S3_BUCKET_NAME="demo-bucket"
EKS_CLUSTER_NAME="demo-eks-cluster"
EKS_CLUSTER_OIDC=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -c 9-100)
```

```shell
aws s3 mb s3://$S3_BUCKET_NAME
```

```shell
cat << EOF > aws-s3-csi-driver-trust-policy.json 
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
sed -i "s|ACCOUNT_ID|$ACCOUNT_ID|g" aws-s3-csi-driver-trust-policy.json
sed -i "s|EKS_CLUSTER_OIDC|$EKS_CLUSTER_OIDC|g" aws-s3-csi-driver-trust-policy.json
```

```shell
aws iam create-role --role-name AmazonEKS_S3_CSI_DriverRole --assume-role-policy-document file:///aws-s3-csi-driver-trust-policy.json
```

```shell
cat <<\EOF> s3-policy.json
{
   "Version": "2012-10-17",
   "Statement": [
        {
            "Sid": "MountpointFullBucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::S3_BUCKET_NAME"
            ]
        },
        {
            "Sid": "MountpointFullObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::S3_BUCKET_NAME/*"
            ]
        }
   ]
}
EOF
```

```shell
sed -i "s|S3_BUCKET_NAME|$S3_BUCKET_NAME|g" s3-policy.json
```

```shell
aws iam create-policy --policy-name AmazonS3CSIDriverPolicy --policy-document file://s3-policy.json
```

```shell
aws iam attach-role-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonS3CSIDriverPolicy --role-name AmazonEKS_S3_CSI_DriverRole
```

```shell
eksctl create addon --name aws-s3-csi-driver --cluster $EKS_CLUSTER_NAME --service-account-role-arn arn:aws:iam::$ACCOUNT_ID:role/AmazonEKS_S3_CSI_DriverRole --force
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: s3-pv
spec:
  capacity:
    storage: 1200Gi # Ignored, required
  accessModes:
    - ReadWriteMany # Supported options: ReadWriteMany / ReadOnlyMany
  storageClassName: "" # Required for static provisioning
  claimRef: # To ensure no other PVCs can claim this PV
    namespace: default # Namespace is required even though it's in "default" namespace.
    name: s3-pvc # Name of your PVC
  mountOptions:
    - allow-delete
    - region REGION_CODE
    - prefix demo/
  csi:
    driver: s3.csi.aws.com # Required
    volumeHandle: s3-csi-driver-volume
    volumeAttributes:
      bucketName: S3_BUCKET_NAME # Bucket Name
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: s3-pvc
spec:
  accessModes:
    - ReadWriteMany # Supported options: ReadWriteMany / ReadOnlyMany
  storageClassName: "" # Required for static provisioning
  resources:
    requests:
      storage: 1200Gi # Ignored, required
  volumeName: s3-pv # Name of your PV
---
apiVersion: v1
kind: Pod
metadata:
  name: s3-app
spec:
  containers:
    - name: app
      image: centos
      command: ["/bin/sh"]
      args:
        [
          "-c",
          "echo 'Hello from the container!' >> /data/$(date -u).txt; tail -f /dev/null",
        ]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: s3-pvc
```

```shell
sed -i "s|REGION_CODE|$REGION_CODE|g" static_provisioning.yaml
sed -i "s|S3_BUCKET_NAME|$S3_BUCKET_NAME|g" static_provisioning.yaml
```

```shell
kubectl apply -f static_provisioning.yaml
```