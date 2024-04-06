<h1 align="center"> Create EBS CSI Driver </h1>

# ENV
```shell
CLUSTER_NAME="<EKS_CLUSTER_NAME>"
CLUSTER_OIDC=$(aws eks describe-cluster --name skills-cluster --query "cluster.identity.oidc.issuer" --output text | cut -c 9-100)
ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
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
  name: ebs-sc
  namespace: <Namespace>
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
```

```shell
kubectl apply -f sc.yaml
```

# Create PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
  namespace: dev-ns
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: "ebs-sc"
  resources:
    requests:
      storage: 4Gi
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
        image: <Image>
        ports:
        - containerPort: <Port>
      volumes:
      - name: ebs-claim
        persistentVolumeClaim:
          claimName: ebs-claim
```

```shell
kubectl apply -f deployment.yaml
```