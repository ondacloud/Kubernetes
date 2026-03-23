### Setup VPC Lattice
```shell
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION_CORD="ap-northeast-2"
VPC_NAME="demo-vpc"
BASTION_NAME="demo-bastion-ec2"
VPC_LATTICE_NAME="lattice-svc-net"
EKS_CLUSTER_NAME="demo-eks-cluster"
EKS_CLUSTER_SG=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
VPC_LATTICE_PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=='com.amazonaws.$REGION_CODE.vpc-lattice'].PrefixListId" --output text)
VPC_LATTICE_PREFIX_LIST_ID_IPV6=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=='com.amazonaws.$REGION_CODE.ipv6.vpc-lattice'].PrefixListId" --output text)
```

```shell
aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent --addon-version v1.0.0-eksbuild.1
```

```shell
aws ec2 authorize-security-group-ingress --group-id $EKS_CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=${VPC_LATTICE_PREFIX_LIST_ID}}],IpProtocol=-1" > /dev/null
aws ec2 authorize-security-group-ingress --group-id $EKS_CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=${VPC_LATTICE_PREFIX_LIST_ID_IPV6}}],IpProtocol=-1" > /dev/null
```

```shell
curl https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/recommended-inline-policy.json  -o recommended-inline-policy.json
```

```shell
aws iam create-policy \
    --policy-name VPCLatticeControllerIAMPolicy \
    --policy-document file://recommended-inline-policy.json
```

```shell
kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/deploy-namesystem.yaml
```

```shell
cat <\<EOF> trust-relationship.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
EOF
```

```shell
aws iam create-role --role-name VPCLatticeControllerIAMRole --assume-role-policy-document file://trust-relationship.json
```

```shell
aws iam attach-role-policy --role-name VPCLatticeControllerIAMRole --policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/VPCLatticeControllerIAMPolicy
```

```shell
eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --approve --region $REGION_CODE
```

```shell
eksctl create iamserviceaccount \
    --region $REGION_CODE \
    --cluster=$EKS_CLUSTER_NAME \
    --namespace=aws-application-networking-system \
    --name=gateway-api-controller \
    --attach-policy-arn=$VPCLatticeControllerIAMPolicyArn \
    --override-existing-serviceaccounts \
    --approve
```

```shell
wget https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/deploy-v1.0.6.yaml
```

```shell
sed -i '8222,8227d' deploy-v1.0.6.yaml
```

```shell
kubectl apply -f deploy-v1.0.6.yaml
```

```shell
kubectl apply -f https://raw.githubusercontent.com/aws/aws-application-networking-k8s/main/files/controller-installation/gatewayclass.yaml
```

```shell
aws vpc-lattice create-service-network --name $VPC_LATTICE_NAME
```

```shell
SERVICE_NETWORK_ID=$(aws vpc-lattice list-service-networks --query "items[?name=='$VPC_LATTICE_NAME'].id" --output text)
VPC_ID=$(aws ec2 describe-vpcs --filter Name=tag:Name,Values=$VPC_NAME --query "Vpcs[].VpcId" --output text)
```

```shell
aws vpc-lattice create-service-network-vpc-association --service-network-identifier $SERVICE_NETWORK_ID --vpc-identifier $VPC_ID
```

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: VPC_LATTICE_NAME
  namespace: default
  annotations:
    application-networking.k8s.aws/lattice-vpc-association: "true"
spec:
  gatewayClassName: amazon-vpc-lattice
  listeners:
    - name: http
      protocol: HTTP
      port: 80
```

```shell
sed -i "s|VPC_LATTICE_NAME|$VPC_LATTICE_NAME|g" gateway.yaml
```

```shell
kubectl get gateway -n default
```
> gateway가 정상적으로 동작 시 PROGRAMMEND가 True로 뜬다.

```yaml
apiVersion: application-networking.k8s.aws/v1alpha1
kind: TargetGroupPolicy
metadata:
  name: policy
  namespace: default
spec:
  targetRef:
    group: ""
    kind: Service
    name: demo-svc
  protocol: HTTP
  protocolVersion: HTTP1
  healthCheck:
    enabled: true
    intervalSeconds: 10
    timeoutSeconds: 1
    healthyThresholdCount: 3
    unhealthyThresholdCount: 2
    path: "/healthcheck"
    port: 8080
    protocol: HTTP
    protocolVersion: HTTP1
    statusMatch: "200"
```

```shell
kubectl apply -f targetgrouppolicy.yaml
```

```yaml
apiVersion: application-networking.k8s.aws/v1alpha1
kind: IAMAuthPolicy
metadata:
    name: iam-auth-policy
    namespace: default
spec:
    targetRef:
        group: "gateway.networking.k8s.io"
        kind: HTTPRoute
        name: lattice-svc
        namespace: default
    policy: |
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": "*",
                    "Resource": "*",
                    "Condition": {
                        "IpAddress": {
                            "aws:SourceIp": "BASTION_IP/32"
                        }
                    }
                }
            ]
        }
```

```shell
BASTION_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$BASTION_NAME" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
```

```shell
sed -i "s|BASTION_IP|$BASTION_IP|g" iamauthpolicy.yaml
```

```shell
kubectl apply -f iamauthpolicy.yaml
```

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: lattice-svc
  namespace: default
spec:
  parentRefs:
  - name: lattice-svc-net
    sectionName: http
  rules:
  - backendRefs:
    - name: skills-svc
      kind: Service
      port: 8080
    matches:
    - path:
        type: PathPrefix
        value: /healthcheck
```

```shell
kubectl apply -f httproute.yaml
```