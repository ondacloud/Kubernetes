## Install Package
[**eksctl**](https://docs.aws.amazon.com/ko_kr/emr/latest/EMR-on-EKS-DevelopmentGuide/setting-up-eksctl.html)
```shell
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/bin
```

[**kubectl**](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/install-kubectl.html)
```shell
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin
```

[**helm**](https://helm.sh/docs/intro/install/)
```shell
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
mv ./get_helm.sh /usr/local/bin
```