resource "kubernetes_manifest" "secret_provider_class" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "azure-keyvault-provider"
      namespace = var.namespace
    }
    spec = {
      provider = "azure"
      parameters = {
        usePodIdentity: "false"
        useVMManagedIdentity: "true"    
        userAssignedIdentityID: var.managed_identity_client_id
        keyvaultName: var.keyvault.name
        cloudName: "AzurePublicCloud"
        objects: jsonencode({
          array = [
            for secret_name in var.secrets : {
              objectName = secret_name
              objectType = "secret"
              objectVersion = ""
            }
          ]
        })
      }
    }
  }
}