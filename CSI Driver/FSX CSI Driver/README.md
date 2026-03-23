### Setup FSX CSI Driver
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CODE="ap-northeast-2"
SUBNET_NAME="demo-private-a"
FSX_SECURITY_GROUP_NAME="demo-fsx-sg"
EKS_CLUSTER_NAME="demo-eks-cluster"
EKS_CLUSTER_SECURITY_GROUP_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$SUBNET_NAME" --query "Subnets[].SubnetId[]" --output text)
FSX_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=$SECURITY_GROUP_NAME" --query "SecurityGroups[].GroupId" --output text)
```

```shell
eksctl create iamserviceaccount \
    --region $REGION_CODE \
    --name fsx-csi-controller-sa \
    --namespace kube-system \
    --cluster $EKS_CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonFSxFullAccess \
    --role-name AmazonEKSFSxLustreCSIDriverFullAccess \
    --approve
```

```shell
kubectl apply -k "github.com/kubernetes-sigs/aws-fsx-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
```

```shell
kubectl annotate serviceaccount -n kube-system fsx-csi-controller-sa \
  eks.amazonaws.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/AmazonEKSFSxLustreCSIDriverFullAccess --overwrite=true
```

```shell
aws ec2 authorize-security-group-ingress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 988 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 1018-1023 --cidr 0.0.0.0/0 > /dev/null
```

```shell
aws ec2 authorize-security-group-egress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 988 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-egress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 1018-1023 --cidr 0.0.0.0/0 > /dev/null
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fsx-claim
  namespace: demo
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: fsx-sc
  resources:
    requests:
      storage: 1200Gi
```

```shell
kubectl apply -f pvc.yaml
```

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fsx-sc
provisioner: fsx.csi.aws.com
parameters:
  subnetId: SUBNET_ID
  securityGroupIds: SECURITY_GROUP_ID
  deploymentType: PERSISTENT_1
  automaticBackupRetentionDays: "1"
  dailyAutomaticBackupStartTime: "00:00"
  copyTagsToBackups: "true"
  perUnitStorageThroughput: "200"
  dataCompressionType: "NONE"
  weeklyMaintenanceStartTime: "7:09:00"
  fileSystemTypeVersion: "2.12"
mountOptions:
  - flock
```

```shell
sed -i "s|SUBNET_ID|$SUBNET_ID|g" sc.yaml
sed -i "s|SECURITY_GROUP_ID|$FSX_SECURITY_GROUP_ID|g" sc.yaml
```

```shell
kubectl apply -f sc.yaml
```