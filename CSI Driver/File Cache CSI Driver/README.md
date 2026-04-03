### Setup File Cache CSI Driver
```shell
REGION_CODE="ap-northeast-2"
SUBNET_NAME="demo-private-a"
FSX_SECURITY_GROUP_NAME="demo-fsx-sg"
EKS_CLUSTER_NAME="demo-eks-cluster"
EKS_APP_NODE_GROUP_NAME="demo-app-node"
EKS_ADDON_NODE_GROUP_NAME="demo-addon-node"
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$SUBNET_NAME" --query "Subnets[].SubnetId[]" --output text)
FSX_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=$SECURITY_GROUP_NAME" --query "SecurityGroups[].GroupId" --output text)
EKS_CLUSTER_SECURITY_GROUP_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
APP_NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_APP_NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
ADDON_NODE_GROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_ADDON_NODE_GROUP_NAME --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
```

```shell
eksctl create iamserviceaccount \
    --region $REGION_CODE \
    --name file-cache-csi-controller-sa \
    --namespace kube-system \
    --cluster $EKS_CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonFSxFullAccess \
    --role-name AmazonEKSFileCacheCSIDriverFullAccess \
    --approve
```

```shell
cat <<\EOF> file-cache-csi-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ds:DescribeDirectories",
                "fsx:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "fsx.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "s3.data-source.lustre.fsx.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:/aws/fsx/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "firehose:PutRecord"
            ],
            "Resource": [
                "arn:aws:firehose:*:*:deliverystream/aws-fsx-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:route-table/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestTag/AmazonFSx": "ManagedByAmazonFSx"
                },
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": [
                        "fsx.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs"
            ],
            "Resource": "*",
            "Condition": {
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": [
                        "fsx.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
```

```shell
aws iam create-policy --policy-name AmazonFileCacheCSIDriverPolicy --policy-document file://file-cache-csi-policy.json
```

```shell
aws iam attach-role-policy --role-name $APP_NODE_GROUP_ROLE_NAME --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonFileCacheCSIDriverPolicy
aws iam attach-role-policy --role-name $ADDON_NODE_GROUP_ROLE_NAME --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonFileCacheCSIDriverPolicy
```

```shell
kubectl annotate serviceaccount file-cache-csi-controller-sa -n kube-system meta.helm.sh/release-name=aws-file-cache-csi-driver --overwrite
kubectl annotate serviceaccount file-cache-csi-controller-sa -n kube-system meta.helm.sh/release-namespace=kube-system --overwrite
kubectl label serviceaccount file-cache-csi-controller-sa -n kube-system app.kubernetes.io/managed-by=Helm --overwrite
```

```shell
helm repo add aws-file-cache-csi-driver https://kubernetes-sigs.github.io/aws-file-cache-csi-driver/
helm repo update
helm install aws-file-cache-csi-driver aws-file-cache-csi-driver/aws-file-cache-csi-driver \
    -n kube-system \
    --set clusterName=$EKS_CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=file-cache-csi-controller-sa
```

```shell
aws ec2 authorize-security-group-ingress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 988 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-egress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 988 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 1018-1023 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-egress --group-id $EKS_CLUSTER_SECURITY_GROUP_ID --protocol tcp --port 1018-1023 --cidr 0.0.0.0/0 > /dev/null
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fc-claim
  namespace: demo
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: fc-sc
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
  name: fc-sc
provisioner: filecache.csi.aws.com
parameters:
  subnetId: SUBNET_ID
  securityGroupIds: SECURITY_GROUP_ID
  dataRepositoryAssociations: "FileCachePath=/ns1/,DataRepositoryPath=nfs://10.0.92.69/,NFS={Version=NFS3},DataRepositorySubdirectories=[subdir1,subdir2,subdir3]"
  fileCacheType: "LUSTRE"
  fileCacheTypeVersion: "2.12"
  weeklyMaintenanceStartTime: "7:00:00"
  LustreConfiguration: "DeploymentType=CACHE_1,PerUnitStorageThroughput=1000,MetadataConfiguration={StorageCapacity=2400}"
  copyTagsToDataRepositoryAssociations: "true"
  extraTags: "skills=app"
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