variable "keyvault" {
  type = object({
    name           = string
    resource_group = string
  })
  description = "Azure KeyVault configuration"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for the SecretProviderClass"
  default     = "default"
}

variable "managed_identity_client_id" {
  type        = string
  description = "Client ID of the managed identity with access to KeyVault"
  default     = ""
}

variable "secrets" {
  type        = list(string)
  description = "List of secret names that should be available in Kubernetes"
  default     = []
}