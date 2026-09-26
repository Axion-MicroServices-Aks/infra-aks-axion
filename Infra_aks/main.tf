
# the code is to deploy aks single node cluster for lab purpose.

# RG
resource "azurerm_resource_group" "aks" {
  name     = "aks-rg"
  location = "West Europe"
  tags = {
    project = "test"
    costcenter = "D86"
  }
  
}

#VNet for Aks Cluster

resource "azurerm_virtual_network" "aks_vnet" {
  name                = "vnet-${azurerm_resource_group.aks.name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = ["10.0.0.0/16"]
  
}

#Subnet for Aks Cluster

resource "azurerm_subnet" "aks_nodes_subnet" {
  depends_on = [ azurerm_virtual_network.aks_vnet ]
  name                 = "subnet-${azurerm_resource_group.aks.name}"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
}

#subnet for Private Endpoing

resource "azurerm_subnet" "aks_PE_subnet" {
  depends_on = [ azurerm_virtual_network.aks_vnet ]
  name                 = "pe_subnet-${azurerm_resource_group.aks.name}"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
# Aks Cluster infra with One Node

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "axionaks"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "axionaks"

  default_node_pool {
    name           = "system"
    node_count     = 1
    vm_size        = "Standard_D2_v3"
    vnet_subnet_id = azurerm_subnet.aks_nodes_subnet.id

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.100.0.0/16"
    dns_service_ip = "10.100.0.10"
  }
}

# ACR CONFIGURATION 

resource "azurerm_container_registry" "acr" {
  name                = "acra12xion45app"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Basic"
  admin_enabled       = true

}