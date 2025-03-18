# Azure KeyVault Kubernetes Integration

This module configures the integration between Azure KeyVault and Kubernetes via the CSI Secrets Driver.

## Requirements

- Azure KeyVault with the required secrets
- CSI Secrets Store Driver installed in the cluster
- Azure Provider for CSI Secrets Store installed
- Managed Identity configured with access to the KeyVault

## Usage

```terraform
module "keyvault_k8s_integration" {
  source = "./bootstrap/keyvault-k8s-integration"
  
  keyvault = {
    name           = "my-keyvault"
    resource_group = "my-resource-group"
  }
  
  managed_identity_client_id = "client-id-for-keyvault-access"
  
  secrets = [
    "secret1",
    "secret2"
  ]
}
```

## Using Secrets in Pods

Add the following to your pod configuration:

```yaml
volumes:
- name: secrets-store-inline
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: "azure-keyvault-provider"
```

Then mount the volume in your containers:

```yaml
volumeMounts:
- name: secrets-store-inline
  mountPath: "/mnt/secrets-store"
  readOnly: true
```

The secrets will be available as files in the mounted path.