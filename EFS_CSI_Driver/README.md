<h1 align="center"> Create EFS CSI Driver </h1>

# ENV
```shell
CLUSTER_NAME="<EKS_CLUSTER_NAME>"
CLUSTER_OIDC=$(aws eks describe-cluster --name skills-cluster --query "cluster.identity.oidc.issuer" --output text | cut -c 9-100)
ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
```

# Install EFS CSI Driver
```shell
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
   --namespace kube-system \
   --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/eks/aws-efs-csi-driver \
   --set controller.serviceAccount.create=false \
   --set controller.serviceAccount.name=efs-csi-controller-sa
```

# Create EBS CSI Driver Trust Policy
```shell
cat <<\EOF> aws-ebs-csi-driver-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/OIDC"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "OIDC:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF
```

```shell
sed -i "s|ACCOUNT_ID|$ACCOUNT|g" aws-ebs-csi-driver-trust-policy.json
sed -i "s|OIDC|$CLUSTER_OIDC|g" aws-ebs-csi-driver-trust-policy.json
```

```shell
aws iam create-role --role-name AmazonEKS_EBS_CSI_DriverRole --assume-role-policy-document file:///home/ec2-user/test-json/aws-ebs-csi-driver-trust-policy.json
```

```shell
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --role-name AmazonEKS_EBS_CSI_DriverRole
```

```shell
eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --service-account-role-arn arn:aws:iam::$ACCOUNT:role/AmazonEKS_EBS_CSI_DriverRole --force
```

# Create StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
  namespace: <Namespace>
provisioner: efs.csi.aws.com
```

# Create PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
  namespace: <Namespace>
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
    volumeHandle: <EFS ID>
```

```shell
kubectl apply -f pv.yaml
```

# Create PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
  namespace: <Namespace>
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

# Create Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <Deployment Name>
  namespace: <Namespace>
  labels:
    <Key>: <Value>
spec:
  replicas: 2
  selector:
    matchLabels:
      <Key>: <Value>
  template:
    metadata:
      labels:
        <Key>: <Value>
    spec:
      containers:
      - name: <Container Name>
        image: <IMAGE>
        ports:
        - containerPort: <Port>
        volumeMounts:
        - name: efs-pv
          mountPath: <Path>
      volumes:
      - name: efs-claim
        persistentVolumeClaim:
          claimName: efs-claim
```

```shell
kubectl apply -f deployment.yaml
```