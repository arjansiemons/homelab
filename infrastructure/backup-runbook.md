# Backup Rollout Runbook

This runbook validates the backup implementation for:
- CloudNativePG backups to Backblaze B2
- Velero backups for full PVC protection (CSI snapshots plus filesystem fallback)

## 1. Prerequisites

Ensure these Azure Key Vault secrets exist:
- prod-backup-b2-access-key-id
- prod-backup-b2-secret-access-key
- prod-backup-b2-bucket-name
- prod-backup-b2-region
- prod-backup-b2-s3-url

## 2. Reconcile Flux

Run from this repo root.

```powershell
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization infrastructure -n flux-system
flux reconcile kustomization backups -n flux-system
```

## 3. Verify External Secrets

```powershell
kubectl get externalsecret -n flux-system backup-config
kubectl get externalsecret -n velero velero-b2-credentials
kubectl get externalsecret -n postgresql-system cnpg-backup-b2-credentials

kubectl describe externalsecret -n flux-system backup-config
kubectl describe externalsecret -n velero velero-b2-credentials
kubectl describe externalsecret -n postgresql-system cnpg-backup-b2-credentials
```

Expected: all show Ready status and recent sync.

## 4. Verify generated Kubernetes Secrets

```powershell
kubectl get secret -n flux-system backup-config
kubectl get secret -n velero velero-b2-credentials
kubectl get secret -n postgresql-system cnpg-backup-b2-credentials
```

## 5. Verify Velero deployment and schedules

```powershell
kubectl get helmrelease -n velero velero
kubectl get pods -n velero
kubectl get schedule -n velero
kubectl get volumesnapshotclass
```

Expected:
- HelmRelease Ready
- velero deployment and node-agent running
- schedules present: pvc-full-daily, pvc-full-weekly-archive
- VolumeSnapshotClass proxmox-csi-snapclass exists

## 6. Verify CNPG backup config

```powershell
kubectl get scheduledbackup -n postgresql-system
kubectl get cluster -n postgresql-system n8n-postgres -o yaml
kubectl get cluster -n postgresql-system cert-practice-postgres -o yaml
```

Expected:
- ScheduledBackup resources exist
- Cluster specs contain backup.barmanObjectStore

## 7. Run smoke backup tests

### 7.1 Velero ad-hoc backup

```powershell
velero backup create smoke-all --include-namespaces default,n8n,unifi-os --wait
velero backup describe smoke-all --details
```

### 7.2 CNPG ad-hoc backups

```powershell
kubectl cnpg backup n8n-postgres -n postgresql-system
kubectl cnpg backup cert-practice-postgres -n postgresql-system
kubectl get backup -n postgresql-system
```

## 8. Validate objects in Backblaze B2

Check that objects are created in paths:
- cnpg/n8n-postgres
- cnpg/cert-practice-postgres
- velero

Use either:
- Backblaze web console
- S3-compatible client (for example aws cli) against your B2 endpoint

## 9. Optional restore drill

```powershell
velero restore create --from-backup smoke-all
velero restore get
```

For database PITR/recovery, follow CloudNativePG restore procedures using backup artifacts in B2.

## 10. Troubleshooting

1. If Flux substitution fails with missing backup-config:
- Wait for ESO sync and retry reconciliation.

2. If Velero cannot access B2:
- Verify bucket name, region, and s3 URL values in Key Vault.
- Verify velero-b2-credentials cloud file is rendered in the secret.

3. If CNPG backup fails:
- Check cnpg-backup-b2-credentials secret keys ACCESS_KEY_ID and ACCESS_SECRET_KEY.
- Check endpoint and destinationPath substitution values are present in cluster specs.
