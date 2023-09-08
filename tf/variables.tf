variable "name" {
  description = "Name to be used as basis for all resources."
  default     = "trip"
}

variable "short_name" {
  description = "Short name to be used as basis for all resources."
  default     = "t"
}

variable "location" {
  description = "Azure region."
  default     = "southcentralus"
}

variable "region" {
  description = "The region site code (e.g. mue1)"
  default     = "tys"
}

variable "environment" {
  description = "The environment code (e.g. prod)"
  default     = "devintus"
}

variable "sxappid" {
  description = "SXAPPID for tagging"
  default     = ""
}

variable "owner_email" {
  description = "Owner DL for tagging"
  default     = "dwhanger@microsoft.com"
}

variable "platform" {
  description = "Platform for tagging"
  default     = "webp"
}

variable "vnet_address_space" {
  description = "VNET address space"
  default     = ""
}

variable "dns_service_ip" {
  description = "dns service ip for aks cluster"
  default     = ""
}

variable "aks_service_cidr" {
  description = "aks service cidr for aks cluster"
  default     = ""
}

variable "docker_bridge_address" {
  description = "docker bridge address"
  default     = "172.17.0.1/16"
}

variable "subnet_address_prefix_web" {
  description = "Subnet for the web tier"
  default     = ""
}

variable "subnet_address_prefix_app" {
  description = "Subnet for the app tier"
  default     = ""
}

variable "subnet_address_prefix_db" {
  description = "Subnet for the db tier"
  default     = ""
}
/*
variable "azdevops_library_groupid" {
  description = "the azure devops (dwhanger) library groupid to update with the generated variables and apikeys"
  default     = "35"
}

variable "azdevops_build_id" {
  description = "the azure devops (dwhanger) build id number"
  default     = "115"
}

variable "azdevops_release_id" {
  description = "the azure devops (dwhanger) release id number"
  default     = "3"
}

variable "azdevops_organization_url" {
  description = "the azure devops (dwhanger) url to the organization...which is the dwhanger part"
  default     = "https://dev.azure.com/dwhanger"
}

variable "azdevops_project" {
  description = "the azure devops (dwhanger) project setup in azx-norton"
  default     = "eCommerce"
}

variable "azdevops_library_name" {
  description = "the azure devops (azx-norton) library variable for name"
  default     = "trip-viewer-devintus(Nirvana)"
}

variable "azdevops_library_VSTS_ProjectName" {
  description = "the azure devops (azx-norton) library variable for VSTS_ProjectName"
  default     = "eCommerce"
}

variable "azdevops_library_VSTS_PersonalAccessToken" {
  description = "the azure devops (azx-norton) library variable for VSTS_PersonalAccessToken"
  default     = "<insert PAT here>"
}

variable "azdevops_library_VSTS_InstanceName" {
  description = "the azure devops (azx-norton) library variable for VSTS_InstanceName"
  default     = "azx-norton"
}
*/
variable "key_vault_name" {
  description = "the name of the keyvault where the secrets are stored"
  default     = ""
}

variable "key_vault_resourcegroup" {
  description = "the resource group for the keyvault...keyvault in order to be accessible via tf needs to be in same subscription"
  default     = ""
}

variable "devops_git_setup" {
  description = "setup for devops git or not"
  default     = [""]
  type        = set(string)
}

/*
variable "repo_account_name" {
  description = "the account name"
  default     = ""
}

variable "repo_branch_name" {
  description = "the branch name"
  default     = ""
}

variable "repo_project_name" {
  description = "the project name"
  default     = ""
}

variable "repo_git_url" {
  description = "the git url"
  default     = ""
}

variable "repo_repository_name" {
  description = "the repo name"
  default     = ""
}

variable "repo_syn_root_folder" {
  description = "the root folder for synapse in the git repo"
  default     = "/syn"
}

variable "repo_adf_root_folder" {
  description = "the root folder for adf in the git repo"
  default     = "/adf"
}

variable "repo_tenant_id" {
  description = "the tenant id"
  default     = ""
}

variable "aad_group_env_adf_folder_owner" {
  description = "AD group name for the ADF folder"
  default     = ""
}
*/

variable "azure_container_registry" {
  description = "the name of the container registry"
  default     = "nirvdockercontainerregistry"
}

variable "sql_user_name" {
  description = "SQL server username"
  default     = "<plug in your real username>"
}

variable "sql_password" {
  description = "SQL server password"
  default     = "<plug in your real password>"
}

variable "sql_server" {
  description = "SQL server name"
  default     = "<plug in your sql server name>"
}

variable "sql_dbname" {
  description = "the database name"
  default     = "<plug in your database name>"
}

variable "aks_version" {
  description = "the aks version"
  default     = "1.27"
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 3
}

variable "operatorDMWObjectid" {
  description = "Object id for the user operator running the tf script from command line...needed for provisioning the keyvault..."
  default     = ""
}

