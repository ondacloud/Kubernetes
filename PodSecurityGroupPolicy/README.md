### Setup PodSecurityGroupPolicy
```shell
REGION_CODE="ap-northeast-2"
EKS_CLUSTER_NAME="demo-eks-cluster"
VPC_NAME="demo-vpc"
SECURITY_GROUP_NAME="demo-pod-sg"
```

```shell
EKS_CLUSTER_ROLE=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query cluster.roleArn --output text | cut -d / -f 2)
```

```shell
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController --role-name $EKS_CLUSTER_ROLE
```

```shell
kubectl describe daemonset aws-node --namespace kube-system | grep amazon-k8s-cni: | cut -d : -f 3
```

```shell
kubectl set env daemonset aws-node -n kube-system ENABLE_POD_ENI=true
```

```shell
kubectl rollout restart daemonset aws-node -n kube-system
```

```shell
kubectl patch ds aws-node -n kube-system \
  -p '{"spec":{"template":{"spec":{"initContainers":[{"env":[{"name":"DISABLE_TCP_EARLY_DEMUX","value":"true"}],"name":"aws-vpc-cni-init"}],"containers":[{"env":[{"name":"ENABLE_POD_ENI","value":"true"}],"name":"aws-node"}]}}}}'
```

```shell
kubectl rollout status ds aws-node -n kube-system
```

```shell
kubectl get nodes -o wide -l vpc.amazonaws.com/has-trunk-attached=true
kubectl describe daemonset aws-node -n kube-system | grep ENABLE_POD_ENI
kubectl label nodes <NODE_NAME> vpc.amazonaws.com/has-trunk-attached=true

kubectl describe no <node> | grep vpc.amazonaws.com/pod-eni
```
> 첫번째 명령어를 해서 노드가 출력이 되지 않았지만 두번째 명령문이 출력된 경우 수동으로 레이블을 지정

```shell
VPC_ID=$(aws ec2 describe-vpcs --filter Name=tag:Name,Values=$VPC_NAME --query "Vpcs[].VpcId[]" --output text)
```

```shell
aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description $SECURITY_GROUP_NAME --vpc-id $VPC_ID
```

```shell
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='$SECURITY_GROUP_NAME'].GroupId" --output text)
```

```shell
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol icmp --port -1 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $SECURITY_GROUP_ID --protocol icmp --port -1 --cidr 0.0.0.0/0
```

```yaml
apiVersion: vpcresources.k8s.aws/v1beta1
kind: SecurityGroupPolicy
metadata:
  name: demo-sgp
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: demo
  securityGroups:
    groupIds:
      - SECURITY_GROUP_ID
```

```shell
sed -i "s|SECURITY_GROUP_ID|$SECURITY_GROUP_ID|g" podsg.yaml
```

```shell
kubectl apply -f podsg.yaml
```

```shell
kubectl get sgp -n demo
```