#
# Create our storage accounts for web artifacts...
#
locals {
  webstatic_sa_temp_name = "${var.name}webp${var.region}${var.environment}"
  webstatic_sa_base_name = "${lower(replace(local.webstatic_sa_temp_name, "/[[:^alnum:]]/", ""))}webstatic"

  webstatic_sa_name = "${substr(
    local.webstatic_sa_base_name,
    0,
    length(local.webstatic_sa_base_name) < 22 ? -1 : 22,
  )}sa"
}

resource "azurerm_storage_account" "webstatic_files" {
#  depends_on = [azurerm_subnet.subnet1]

  name                      = local.webstatic_sa_name
  resource_group_name       = var.resgroup_main_name
  location                  = var.resgroup_main_location
  enable_https_traffic_only = "true"
  min_tls_version           = "TLS1_2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  is_hns_enabled            = "true"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = [var.ip_to_allow]
    virtual_network_subnet_ids = [var.subnet1_id]

    bypass                     = ["AzureServices"]
  }

  static_website {
    index_document = "index.html"
  }

  tags = var.tags
}

resource "azurerm_storage_account_network_rules" "databricks_sa_network_rules" {
  storage_account_id = azurerm_storage_account.webstatic_files.id

  default_action             = "Deny"
  ip_rules                   = [var.subnet1_id]
  virtual_network_subnet_ids = [var.subnet1_id]
  bypass                     = ["Metrics", "AzureServices"]
}

resource "azurerm_storage_blob" "webstatic_blob" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.webstatic_files.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "<h1>This is static content coming from the Terraform</h1>"
}


#
# Get the static website url...
#
data "azurerm_storage_account" "static_website_url" {
  name                = azurerm_storage_account.webstatic_files.name
  resource_group_name = var.resgroup_main_name
}
