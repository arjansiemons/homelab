module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version        = "v1.8.1"
    update_version = "v1.8.3" # renovate: github-releases=siderolabs/talos
    schematic      = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values  = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "192.168.2.5"
    gateway         = "192.168.2.1"
    talos_version   = "v1.8.1"
    proxmox_cluster = "homelab"
  }

  nodes = {
    "ctrl-00" = {
      host_node     = "pve"
      machine_type  = "controlplane"
      ip            = "192.168.2.80"
      mac_address   = "BC:24:11:2E:C8:00"
      vm_id         = 800
      cpu           = 2
      ram_dedicated = 4096
      #      igpu          = true
      update = true
    }
    "ctrl-01" = {
      host_node     = "pve"
      machine_type  = "controlplane"
      ip            = "192.168.2.81"
      mac_address   = "BC:24:11:2E:C8:01"
      vm_id         = 801
      cpu           = 2
      ram_dedicated = 4096
      #  igpu          = true
      update = true
    }
    "ctrl-02" = {
      host_node     = "pve"
      machine_type  = "controlplane"
      ip            = "192.168.2.82"
      mac_address   = "BC:24:11:2E:C8:02"
      vm_id         = 802
      cpu           = 2
      ram_dedicated = 4096
      update        = true
    }
    "work-00" = {
      host_node     = "pve"
      machine_type  = "worker"
      ip            = "192.168.2.85"
      mac_address   = "BC:24:11:2E:A8:00"
      vm_id         = 810
      cpu           = 4
      ram_dedicated = 8192
      usb           = true
      update        = true
    }
    "work-01" = {
      host_node     = "pve"
      machine_type  = "worker"
      ip            = "192.168.2.86"
      mac_address   = "BC:24:11:2E:A8:01"
      vm_id         = 811
      cpu           = 4
      ram_dedicated = 8192
      update        = true
    }
    "work-02" = {
      host_node     = "pve"
      machine_type  = "worker"
      ip            = "192.168.2.87"
      mac_address   = "BC:24:11:2E:A8:02"
      vm_id         = 812
      cpu           = 2
      ram_dedicated = 8192
      update        = true
    }
  }
}

# Azure KeyVault reference
data "azurerm_key_vault" "homelab" {
  name                = var.azure_keyvault.name
  resource_group_name = var.azure_keyvault.resource_group
}

# Fetch Proxmox API token from KeyVault
data "azurerm_key_vault_secret" "proxmox_api_token" {
  name         = "proxmox-api-token"
  key_vault_id = data.azurerm_key_vault.homelab.id
}

# Module for KeyVault-Kubernetes integration
module "keyvault_k8s_integration" {
  depends_on = [module.talos]
  source     = "./bootstrap/keyvault-k8s-integration"
  
  keyvault = var.azure_keyvault
  namespace = "kube-system"
  
  # Secrets to map to Kubernetes
  secrets = [
    "proxmox-api-token"
    # Add other secret names as needed
  ]
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos]
  source     = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

