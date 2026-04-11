### EKS Service Account
**AWS Load Balancer Controller**
```yaml
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true
```

**cert-manager**
```yaml
  - metadata:
      name: cert-manager
      namespace: cert-manager
    wellKnownPolicies:
      certManager: true
```

**EBS CSI Driver**
```yaml
  - metadata:
      name: ebs-csi-controller-sa
      namespace: kube-system
    wellKnownPolicies:
      ebsCSIController: true
```

**EFS CSI Driver**
```yaml
  - metadata:
      name: efs-csi-controller-sa
      namespace: kube-system
    wellKnownPolicies:
      efsCSIController: true
```

**FSx CSI Driver**
```yaml
  - metadata:
      name: fsx-csi-controller-sa 
      namespace: kube-system
    managedPolicies:
      - "arn:aws:iam::aws:policy/AmazonFSxFullAccess"
```

**File Cache CSI Driver**
```yaml
  - metadata:
      name: fsx-csi-controller-sa 
      namespace: kube-system
    managedPolicies:
      - "arn:aws:iam::aws:policy/AmazonFSxFullAccess"
```

**Secrets Store CSI Driver**
```yaml
  - metadata:
      name: secrets-cert-controller-sa
      namespace: kube-system
    attachPolicy:
      Version: "2012-10-17"
      Statement:
      - Effect: Allow
        Action:
        - "autoscaling:DescribeAutoScalingGroups"
        - "autoscaling:DescribeAutoScalingInstances"
        - "autoscaling:DescribeLaunchConfigurations"
        - "autoscaling:DescribeTags"
        - "autoscaling:SetDesiredCapacity"
        - "autoscaling:TerminateInstanceInAutoScalingGroup"
        - "ec2:DescribeLaunchTemplateVersions"
        Resource: '*'
```

**External DNS**
```yaml
  - metadata:
      name: external-dns
      namespace: kube-system
  attachPolicy:
    Version: "2012-10-17"
    Statement:
      - Effect: Allow
        Action:
          - secretsmanager:GetSecretValue
          - secretsmanager:DescribeSecret
        Resource: "*"
```

**External Secrets**
```yaml
- metadata:
    name: external-secrets-cert-controller
    namespace: kube-system
  attachPolicy:
    Version: "2012-10-17"
    Statement:
      - Effect: Allow
        Action:
          - secretsmanager:GetResourcePolicy
          - secretsmanager:GetSecretValue
          - secretsmanager:DescribeSecret
          - secretsmanager:ListSecretVersionIds
        Resource: "*"
      - Effect: Allow
        Action:
          - kms:Decrypt
        Resource: "*"
```

**Cluster AutoScaler**
```yaml
  - metadata:
      name: cluster-autoscaler
      namespace: kube-system
      labels: {aws-usage: "cluster-ops"}
    wellKnownPolicies:
      autoScaler: true
  - metadata:
      name: autoscaler-service
      namespace: kube-system
    attachPolicy:
      Version: "2012-10-17"
      Statement:
      - Effect: Allow
        Action:
        - "autoscaling:DescribeAutoScalingGroups"
        - "autoscaling:DescribeAutoScalingInstances"
        - "autoscaling:DescribeLaunchConfigurations"
        - "autoscaling:DescribeTags"
        - "autoscaling:SetDesiredCapacity"
        - "autoscaling:TerminateInstanceInAutoScalingGroup"
        - "ec2:DescribeLaunchTemplateVersions"
        Resource: '*'
```