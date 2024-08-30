```shell
# 환경변수
export BUCKET_NAME="<S3_BUCKET_NAME>"
export REGION_CODE=$(aws configure get region --output text)
```

```shell
wget https://github.com/vmware-tanzu/velero/releases/download/v1.9.2/velero-v1.9.2-linux-amd64.tar.gz
tar zxvf velero-v1.9.2-linux-amd64.tar.gz
sudo cp velero-v1.9.6-linux-amd64/velero /usr/local/bin/.
```

```shell
velero install \
    --provider aws \
    --bucket $BUCKET_NAME \
    --secret-file ./credentials-velero \
    --backup-location-config region=$REGION_CODE \
    --use-volume-snapshots=false \
    --plugins velero/velero-plugin-for-aws:v1.3.0 \
    --use-restic
```

```shell
velero backup create <BACKUP_NAME> --include-namespaces <NAMESPACE> --wait
```

```shell
velero get backup
```

```shell
velero restore create --from-backup <BACKUP_NAME> --wait
```