####################################################
#
# This Terraform impelments:
#     1) Azure CNI + Cilium (eBPF) for AKS
#     2) k8s with managed Azure AD integration
#     3) AKV
#     4) API server authorized IP ranges
#     5) 
#
####################################################

# Configure the Azure Provider
terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.72.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "1.4.0"
    }
  }

  backend "azurerm" {}
}


provider "azuread" {
  # Configuration options
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = false
      #
      # not compatible with byok ADF keyvault setup, retrieval, and encryption...
      #
      #recover_soft_deleted_key_vaults = true
    }
  }
  //  skip_credentials_validation
}

data "azurerm_client_config" "current" {}

locals {
  tenant_id       = data.azurerm_client_config.current.tenant_id
  subscription_id = data.azurerm_client_config.current.subscription_id
  object_id       = data.azurerm_client_config.current.object_id
}

locals {
  tags = {
    BusinessUnit    = "Tyee Software Engineering"
    CostCenter      = "333-32555-000"
    Environment     = var.environment
    SXAPPID         = var.sxappid
    AppName         = var.name
    OwnerEmail      = var.owner_email
    Platform        = var.platform
    PlatformAppName = "${var.platform}-${var.name}"
  }
}

//
// IP addresses of ADO machines around the globe to let in...
//
//
locals {
  devops = [
    "20.37.158.0/23",
    "20.37.194.0/24",
    "20.39.13.0/26",
    "20.41.6.0/23",
    "20.41.194.0/24",
    "20.42.5.0/24",
    "20.42.134.0/23",
    "20.42.226.0/24",
    "20.45.196.64/26",
    "20.189.107.0/24",
    "20.195.68.0/24",
    "40.74.28.0/23",
    "40.80.187.0/24",
    "40.82.252.0/24",
    "40.119.10.0/24",
    "51.104.26.0/24",
    "52.150.138.0/24",
    "52.228.82.0/24",
    "191.235.226.0/24",
    "20.51.251.83",
    "20.98.103.209",
    "98.232.189.107",
    "20.37.194.0/24",
    "20.42.226.0/24",
    "191.235.226.0/24",
    "52.228.82.0/24",
    "20.37.158.0/23",
    "20.45.196.64/26",
    "20.189.107.0/24",
    "20.42.5.0/24",
    "20.41.6.0/23",
    "20.39.13.0/26",
    "40.80.187.0/24",
    "40.119.10.0/24",
    "20.41.194.0/24",
    "20.195.68.0/24",
    "51.104.26.0/24",
    "52.150.138.0/24",
    "40.74.28.0/23",
    "40.82.252.0/24",
    "20.42.134.0/23",
    "76.138.138.227"
  ]
}

//
// IP addresses of Github Actions machines around the globe to let in...
//
//
data "local_file" "githubactions_ipaddresses" {
  filename = "${path.module}/githubactions_ipaddresses.txt"
}
locals {
  githubactions_ipaddresses = split(",", trimspace(data.local_file.githubactions_ipaddresses.content))
}

resource "azurerm_resource_group" "main" {

  name     = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}-rg"
  location = var.location

  tags = local.tags
}

#
# Load up our module where we have the vnet, nsgs, and subnets defined...
#
module "azure_vnet_nsg_subnet" {
  source = "./modules/azure-vnet-nsg-subnet"

  resgroup_main_location      = azurerm_resource_group.main.location
  resgroup_main_name          = azurerm_resource_group.main.name
  name                        = var.name
  location                    = var.location
  platform                    = var.platform
  region                      = var.region
  environment                 = var.environment
  vnet_address_space          = var.vnet_address_space
  subnet_address_prefix_web   = var.subnet_address_prefix_web
  subnet_address_prefix_app   = var.subnet_address_prefix_app
  subnet_address_prefix_db    = var.subnet_address_prefix_db
  tags                        = local.tags
}

#
# Load up out module where our storage accounts are defined for the function app and for the content for the single page application (SPA)
#
module "azure_storage_accounts" {
  source = "./modules/azure-storage-accounts"

  resgroup_main_location      = azurerm_resource_group.main.location
  resgroup_main_name          = azurerm_resource_group.main.name
  name                        = var.name
  location                    = var.location
  platform                    = var.platform
  region                      = var.region
  environment                 = var.environment
  subnet1_id                  = module.azure_vnet_nsg_subnet.subnet1.id
  ip_to_allow                 = "76.138.138.227"
  tags                        = local.tags
}


#
# Our REST api's are backed by CosmosDB (sql api)...
#
module "azure_cosmosdb" {
  source = "./modules/azure-cosmosdb"

  resgroup_main_location      = azurerm_resource_group.main.location
  resgroup_main_name          = azurerm_resource_group.main.name
  name                        = var.name
  location                    = var.location
  platform                    = var.platform
  region                      = var.region
  environment                 = var.environment
  subnet3_id                  = module.azure_vnet_nsg_subnet.subnet3.id
  ip_to_allow                 = "76.138.138.227"
  tags                        = local.tags
}

resource "azurerm_eventgrid_topic" "eventgrid" {
  depends_on = [azurerm_resource_group.main]

  name                ="${var.name}-${var.platform}-${var.region}-${var.environment}-topic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}


//todo, make execution of EventGrid subscription conditional on the code being deployed...
/*
#
# For the EventGrid subscription registrations below to work, the code for the Azure Functions must have already been deployed successfully...
#
# az eventgrid event-subscription create --name EndPointCheckerDynatrace --endpoint '/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.Web/sites/${azurerm_function_app.func_app.name}/functions/EndPointCheckerTypeDynatrace' --endpoint-type azurefunction --subject-begins-with Dynatrace --subject-case-sensitive false --event-delivery-schema eventgridschema --labels functions-endpointtypedynatrace --source-resource-id '/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.EventGrid/topics/${azurerm_eventgrid_topic.eventgrid.name}' --subscription ${var.subscriptionid}
resource "azurerm_eventgrid_event_subscription" "egEndPointCheckerDynatrace" {
  name                   = "${var.name}-${var.platform}-${var.region}-${var.environment}-eventgrid-sub-dynatrace"
  scope                  = azurerm_resource_group.main.id

  event_delivery_schema  = "EventGridSchema"
  labels                 = ["functions-endpointtypedynatrace"]

  subject_filter{
    subject_begins_with  = "Dynatrace"
    case_sensitive       = false
  }

# --source-resource-id '/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.EventGrid/topics/${azurerm_eventgrid_topic.eventgrid.name}'
  azure_function_endpoint {
    function_id = "/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.EventGrid/topics/${azurerm_eventgrid_topic.eventgrid.name}/functions/EndPointCheckerDynatrace"
  }
}


# az eventgrid event-subscription create --name EndPointCheckerHttp --endpoint '/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.Web/sites/${azurerm_function_app.func_app.name}/functions/EndPointCheckerTypeHttp' --endpoint-type azurefunction --subject-begins-with Http --subject-case-sensitive false --event-delivery-schema eventgridschema --labels functions-endpointtypehttp --source-resource-id '/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.EventGrid/topics/${azurerm_eventgrid_topic.eventgrid.name}' --subscription ${var.subscriptionid}
resource "azurerm_eventgrid_event_subscription" "egEndPointCheckerHttp" {
  name                   = "${var.name}-${var.platform}-${var.region}-${var.environment}-eventgrid-sub-http"
  scope                  = azurerm_resource_group.main.id

  event_delivery_schema  = "EventGridSchema"
  labels                 = ["functions-endpointtypehttp"]

  subject_filter{
    subject_begins_with  = "Http"
    case_sensitive       = false
  }
# --source-resource-id '/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.EventGrid/topics/${azurerm_eventgrid_topic.eventgrid.name}' --subscription ${var.subscriptionid}
  azure_function_endpoint {
    function_id = "/subscriptions/${var.subscriptionid}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.EventGrid/topics/${azurerm_eventgrid_topic.eventgrid.name}/functions/EndPointCheckerHttp"
  }
}
*/

####
# BYOK key for ADF....
#
resource "random_string" "forKeyvault" {
  length  = 8
  special = false
}

locals {
  kv_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.name}-${var.platform}-${random_string.forKeyvault.result}"
  kv_base_name = lower(replace(local.kv_temp_name, "/[[:^alnum:]]/", ""))
  kv_name      = substr(local.kv_base_name, 0, length(local.kv_base_name) < 21 ? -1 : 21)
}

resource "azurerm_user_assigned_identity" "uaidentity" {
  name                = "${local.kv_name}-id"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_key_vault" "keyvault" {

  name                       = "${local.kv_name}-kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = local.tenant_id
  sku_name                   = "premium"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = local.tenant_id
    object_id = local.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
    ]
  }

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    #    ip_rules       = ["20.51.251.83","20.98.103.209","98.232.189.107","13.65.175.147"]
    #    ip_rules       = local.devops
    ip_rules                   = local.githubactions_ipaddresses
    virtual_network_subnet_ids = [module.azure_vnet_nsg_subnet.subnet2.id]
  }
  
  tags = local.tags
}
/*
resource "azurerm_key_vault_access_policy" "azure_cli_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id = local.tenant_id
  object_id = local.object_id

  key_permissions = [
      "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy", "Rotate", "Release", "Update", "Verify", "Decrypt", "Encrypt", "Sign"
  ]

  secret_permissions = [
      "List", "Get", "Delete", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
      "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore"
  ]

}
*/

resource "azurerm_key_vault_access_policy" "azure_dmw_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = local.tenant_id
  object_id    = var.operatorDMWObjectid

  key_permissions = [
    "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy", "Rotate", "Release", "Update", "Verify", "Decrypt", "Encrypt", "Sign"
  ]

  secret_permissions = [
    "List", "Get", "Delete", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
    "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore"
  ]

}


resource "azurerm_key_vault_access_policy" "azure_uaidentity_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = local.tenant_id
  object_id    = azurerm_user_assigned_identity.uaidentity.principal_id

  key_permissions = [
    "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy", "Rotate", "Release", "Update", "Verify", "Decrypt", "Encrypt", "Sign"
  ]

  secret_permissions = [
    "List", "Get", "Delete", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
    "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore"
  ]

}

resource "azurerm_key_vault_key" "keyvaultkey" {

  name         = "${local.kv_name}-ke"
  key_vault_id = azurerm_key_vault.keyvault.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

#
# Load up our secrets
#
resource "azurerm_key_vault_secret" "sql_user" {
  depends_on = [azurerm_key_vault.keyvault]
  name         = "SQL-USER"
  value        = "${var.sql_user_name}"
  key_vault_id = "${azurerm_key_vault.keyvault.id}"
  tags = local.tags
}

resource "azurerm_key_vault_secret" "sql_password" {
  depends_on = [azurerm_key_vault.keyvault]
  name         = "SQL-PASSWORD"
  value        = "${var.sql_password}"
  key_vault_id = "${azurerm_key_vault.keyvault.id}"
  tags = local.tags
}

resource "azurerm_key_vault_secret" "sql_server" {
  depends_on = [azurerm_key_vault.keyvault]
  name         = "SQL-SERVER"
  value        = "${var.sql_server}"
  key_vault_id = "${azurerm_key_vault.keyvault.id}"
  tags = local.tags
}

resource "azurerm_key_vault_secret" "sql_dbname" {
  depends_on = [azurerm_key_vault.keyvault]
  name         = "SQL-DBNAME"
  value        = "${var.sql_dbname}"
  key_vault_id = "${azurerm_key_vault.keyvault.id}"
  tags = local.tags
}

/*
locals {
  sp_appId_value = "${chomp(data.local_file.readin_from_file_for_appid.content)}"
  sp_password_value = "${chomp(data.local_file.readin_from_file_for_password.content)}"
}
*/

locals {
  aks_cluster_name = "${var.region}-${var.platform}-${var.name}-${var.environment}-aks"
  aks_cluster_name_base = lower(replace(local.aks_cluster_name, "/[[:^alnum:]]/", ""))
}

locals {
  str_newline = "\n"
}

######
# create the aks cluster
#
#     --api-server-authorized-ip-ranges ${var.client_ip_address} 
/*
locals {
  az_aks_create_w_newline = <<EOF
az aks create 
    --resource-group ${azurerm_resource_group.main.name} 
    --name ${local.aks_cluster_name} 
    --network-plugin azure 
    --vnet-subnet-id ${azurerm_subnet.subnet2.id} 
    --docker-bridge-address ${var.docker_bridge_address} 
    --dns-service-ip ${var.dns_service_ip} 
    --service-cidr ${var.aks_service_cidr} 
    --generate-ssh-keys 
    --node-count 3 
    --min-count 2 
    --max-count 15 
    --enable-cluster-autoscaler 
    --nodepool-name tyeendepool1
    --aad-server-app-id ${local.serverApplicationId} 
    --aad-server-app-secret ${local.serverApplicationSecret} 
    --aad-client-app-id ${local.clientApplicationId} 
    --aad-tenant-id ${var.tentantIdForNortonLifeLockDirectoryForAKSApps} 
    --kubernetes-version ${var.aks_version} 
    --service-principal ${local.sp_appId_value} 
    --client-secret ${local.sp_password_value} 
EOF

  az_aks_create = replace(local.az_aks_create_w_newline, local.str_newline, "")
}

resource "null_resource" "create_aks_cluster" {
  depends_on = [null_resource.az_login_symc_directory]
  #
  # Create the AKS cluster...
  #
  provisioner "local-exec" {
    command = "${chomp(local.az_aks_create)}"
  }
}
*/

resource "azurerm_kubernetes_cluster" "k8s" {
  name                       = local.aks_cluster_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  dns_prefix                 = "${local.aks_cluster_name}-dns"

  /*
  aci_connector_linux - (Optional) A aci_connector_linux block as defined below. For more details, please visit Create and configure an AKS cluster to use virtual nodes.
  automatic_channel_upgrade - (Optional) The upgrade channel for this Kubernetes Cluster. Possible values are patch, rapid, node-image and stable. Omitting this field sets this value to none.
  auto_scaler_profile
  azure_policy_enabled - (Optional) Should the Azure Policy Add-On be enabled? For more details please visit Understand Azure Policy for Azure Kubernetes Service
  confidential_computing - (Optional) A confidential_computing block as defined below. For more details please the documentation
  disk_encryption_set_id - (Optional) The ID of the Disk Encryption Set which should be used for the Nodes and Volumes. More information can be found in the documentation. 
  image_cleaner_enabled - (Optional) Specifies whether Image Cleaner is enabled.
  image_cleaner_interval_hours - (Optional) Specifies the interval in hours when images should be cleaned up. Defaults to 48
  ingress_application_gateway - (Optional) A ingress_application_gateway block as defined below.
  key_management_service - (Optional) A key_management_service block as defined below. For more details, please visit Key Management Service (KMS) etcd encryption to an AKS cluster.
  key_vault_secrets_provider - (Optional) A key_vault_secrets_provider block as defined below. For more details, please visit Azure Keyvault Secrets Provider for AKS.
  kubernetes_version - (Optional) Version of Kubernetes specified when creating the AKS managed cluster. If not specified, the latest recommended version will be used at provisioning time (but won't auto-upgrade). AKS does not require an exact patch version to be specified, minor version aliases such as 1.22 are also supported. - 
  local_account_disabled - (Optional) If true local accounts will be disabled. See the documentation for more information. -> Note: If local_account_disabled is set to true, it is required to enable Kubernetes RBAC and AKS-managed Azure AD integration. See the documentation for more information.
  maintenance_window - (Optional) A maintenance_window block as defined below.
  maintenance_window_auto_upgrade - (Optional) A maintenance_window_auto_upgrade block as defined below.
  maintenance_window_node_os - (Optional) A maintenance_window_node_os block as defined below.
  microsoft_defender - (Optional) A microsoft_defender block as defined below.
  monitor_metrics - (Optional) Specifies a Prometheus add-on profile for the Kubernetes Cluster. A monitor_metrics block as defined below.
  network_profile - (Optional) A network_profile block as defined below. Changing this forces a new resource to be created.  -> Note: If network_profile is not defined, kubenet profile will be used by default.
  node_os_channel_upgrade - (Optional) The upgrade channel for this Kubernetes Cluster Nodes' OS Image. Possible values are Unmanaged, SecurityPatch, NodeImage and None.  -> Note: node_os_channel_upgrade must be set to NodeImage if automatic_channel_upgrade has been set to node-image  -> Note: This requires that the Preview Feature Microsoft.ContainerService/NodeOsUpgradeChannelPreview is enabled and the Resource Provider is re-registered, see the documentation for more information.
  private_cluster_enabled - (Optional) Should this Kubernetes Cluster have its API server only exposed on internal IP addresses? This provides a Private IP Address for the Kubernetes API on the Virtual Network where the Kubernetes Cluster is located. Defaults to false. Changing this forces a new resource to be created.
  private_cluster_public_fqdn_enabled - (Optional) Specifies whether a Public FQDN for this Private Cluster should be added. Defaults to false.
  service_mesh_profile - (Optional) A service_mesh_profile block as defined below.  -> Note: This requires that the Preview Feature Microsoft.ContainerService/AzureServiceMeshPreview is enabled and the Resource Provider is re-registered, see the documentation for more information.
  workload_autoscaler_profile - (Optional) A workload_autoscaler_profile block defined below. KEDA, KEDA, KEDA....
  workload_identity_enabled - (Optional) Specifies whether Azure AD Workload Identity should be enabled for the Cluster. Defaults to false. -> Note: To enable Azure AD Workload Identity oidc_issuer_enabled must be set to true.  
  role_based_access_control_enabled - (Optional) Whether Role Based Access Control for the Kubernetes Cluster should be enabled. Defaults to true. 
  storage_profile - (Optional) A storage_profile block as defined below
  windows_profile - (Optional) A windows_profile block as defined below. only for Windows container workloads
  */
  api_server_access_profile{
    authorized_ip_ranges      = ["76.138.138.227"]
    subnet_id                 = module.azure_vnet_nsg_subnet.subnet2.id
    //see: https://learn.microsoft.com/en-us/azure/aks/api-server-vnet-integration
    //vnet_integration_enabled  = true
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_D2_v2"
    node_count = var.node_count
  }
  linux_profile {
    admin_username = "admin" #var.username

    ssh_key {
      key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    }
  }
  network_profile {
    network_plugin = "kubenet"
    //see: https://learn.microsoft.com/en-us/azure/aks/azure-cni-powered-by-cilium
    //network_plugin    = "azure"
    //ebpf_data_plane = "cilium"
    //network_plugin_mode = "overlay"
    load_balancer_sku = "standard"
  }

  tags = local.tags
}

######
# bug work around....can't specify the     --attach-acr nirvdockercontainerregistry.azurecr.io  above...
# have to attach it after the cluster is created
#
# attach the acr to the cluster....here
#
locals {
  az_aks_update_acr_w_newline = <<EOF
az aks update 
    --resource-group ${azurerm_resource_group.main.name} 
    --name ${local.aks_cluster_name} 
    --attach-acr ${var.azure_container_registry} 
EOF

  az_aks_update_acr = replace(local.az_aks_update_acr_w_newline, local.str_newline, "")
}

/*
resource "null_resource" "update_aks_cluster_acr" {
  depends_on = [null_resource.create_aks_cluster]
  #
  # Update with the ACR to the cluster...
  #
  provisioner "local-exec" {
    command = "${chomp(local.az_aks_create)}"
  }
}
*/

######
# enable the aks addon for virtual-node
#
locals {
  az_aks_enableaddons_w_newline = <<EOF
az aks enable-addons 
    --resource-group ${azurerm_resource_group.main.name} 
    --name ${local.aks_cluster_name} 
    --addons virtual-node 
    --subnet-name ${module.azure_vnet_nsg_subnet.subnet2.name}
EOF

  az_aks_enableaddons = replace(local.az_aks_enableaddons_w_newline, local.str_newline, "")
}

resource "null_resource" "enable_virtual_node_addon" {
  #depends_on = [null_resource.update_aks_cluster_acr]
  #
  # Enable virtual nodes addon
  #
  provisioner "local-exec" {
    command = "${chomp(local.az_aks_enableaddons)}"
  }
}

