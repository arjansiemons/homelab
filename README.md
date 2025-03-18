# Homelab

This repository contains the Kubernetes configuration for my homelab environment. The content is managed with FluxCD, which provides automatic synchronization between this repository and the Kubernetes cluster.

## Structure

- `apps/`: Application manifests
- `clusters/`: FluxCD cluster configuration
  - `production/`: Production cluster configuration
- `infrastructure/`: Infrastructure components (network, storage, monitoring)
- `docs/`: Documentation
- `tofu/`: OpenTofu (Terraform) configuration

## Secrets Management

Secrets are managed via Azure KeyVault using the CSI Secrets Store Driver, instead of Sealed Secrets.
