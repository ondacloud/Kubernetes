## Install Package
[**eksctl**](https://docs.aws.amazon.com/ko_kr/eks/latest/eksctl/installation.html)
```shell
# x86 x64
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
eksctl version

# ARM64
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_arm64.tar.gz"
tar -xzf eksctl_Linux_arm64.tar.gz -C /tmp && rm eksctl_Linux_arm64.tar.gz
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

[**kubectl**](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/install-kubectl.html)
```shell
# x86 x64
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version

# ARM64
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl.sha256"
echo "$(cat kubectl.sha256) kubectl" | sha256sum --check
sudo install -o ec2-user -g ec2-user -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

[**helm**](https://helm.sh/docs/intro/install/)
```shell
# Version 3.X.X
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -rf get_helm.sh
helm version

# Version 4.X.X
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
rm -rf get_helm.sh
helm version
```

[**k9s**](https://github.com/derailed/k9s/releases)
```shell
curl -LO https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_Linux_amd64.tar.gz
tar -xf k9s_Linux_amd64.tar.gz
chmod +x k9s
sudo mv k9s /usr/local/bin
```

[**kubectx & kubens**](https://github.com/ahmetb/kubectx)
```shell
sudo dnf install -y git
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
```