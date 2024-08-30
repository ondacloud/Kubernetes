<h1 align="center"> Create Pod Security Group </h1>

# ENV
```shell
EKS_CLUSTER_NAME="<EKS_CLUSTER_NAME>"
EKS_CLUSTER_ROLE=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query cluster.roleArn --output text | cut -d / -f 2)
```

# Attach Policy in Role
```shell
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController --role-name $EKS_CLUSTER_ROLE
```

# Describe Demonset
```shell
kubectl describe daemonset aws-node --namespace kube-system | grep amazon-k8s-cni: | cut -d : -f 3
```

# ENV Demonset
```shell
kubectl set env daemonset aws-node -n kube-system ENABLE_POD_ENI=true
```

# Select Node Group
```shell
kubectl get nodes -o wide -l vpc.amazonaws.com/has-trunk-attached=true
kubectl describe no ip-172-168-3-249.ap-northeast-2.compute.internal | grep vpc.amazonaws.com/pod-eni
```

# Create Security Group
```shell
export VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId[]" --output text)
aws ec2 create-security-group --group-name <SG Name> --description <SG Name> --vpc-id $VPC_ID
aws ec2 authorize-security-group-ingress --group-id sg-00559426854f20b54 --protocol icmp --port -1 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id sg-065fb462800f7b1e6 --protocol icmp --port -1 --cidr 0.0.0.0/0
```

# Create podsgp.yaml
```yaml
apiVersion: vpcresources.k8s.aws/v1beta1
kind: SecurityGroupPolicy
metadata:
  name: <Pod_Security_Name>
  namespace: <Namespace>
spec:
  podSelector:
    matchLabels:
      <Key>: <Value> #Pod label
  securityGroups:
    groupIds:
      - <Security Group ID> # Security Group ID
```

```shell
kubectl apply -f podsgp.yaml
```

```shell
kubectl get sgp -n <Namespace>
```

```shell
kubectl get po -n <Namespace> -o wide
```