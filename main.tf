terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.75.0"
    }
  }
}

locals {
  workload = "databoss"
}

resource "azurerm_resource_group" "default" {
  name     = "rg-${local.workload}"
  location = var.location
}

module "vnet" {
  source   = "./modules/vnet"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location
}

module "datalake" {
  source   = "./modules/datalake"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  vnet_id                       = module.vnet.vnet_id
  subnet_id                     = module.vnet.default_subnet_id
  public_ip_address_to_allow    = var.public_ip_address_to_allow
  public_network_access_enabled = var.datalake_public_network_access_enabled
}

module "external_storage" {
  source   = "./modules/storage/external"
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location
}

module "outbound_storage" {
  source   = "./modules/storage/outbound"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  vnet_id                       = module.vnet.vnet_id
  subnet_id                     = module.vnet.default_subnet_id
  public_ip_address_to_allow    = var.public_ip_address_to_allow
  public_network_access_enabled = var.outbound_storage_public_network_access_enabled
}

module "adf" {
  source   = "./modules/adf"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  managed_virtual_network_enabled = var.adf_managed_virtual_network_enabled
  public_network_enabled          = var.adf_public_network_enabled
  datalake_primary_dfs_endpoint   = module.datalake.primary_dfs_endpoint
  datalake_primary_access_key     = module.datalake.primary_access_key
  ir_virtual_network_enabled      = var.adf_ir_virtual_network_enabled
  storage_account_id              = module.datalake.storage_account_id

  # External Storage
  external_storage_connection_string = module.external_storage.primary_blob_connection_string
}

module "databricks" {
  source   = "./modules/databricks"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  sku                           = var.dbw_sku
  public_network_access_enabled = var.dbw_public_network_access_enabled

  vnet_id                                           = module.vnet.vnet_id
  vnet_no_public_ip                                 = var.dbw_vnet_no_public_ip
  databricks_vnet_public_subnet_name                = module.vnet.databricks_public_subnet_name
  databricks_vnet_private_subnet_name               = module.vnet.databricks_private_subnet_name
  databricks_vnet_public_subnet_nsg_association_id  = module.vnet.databricks_public_subnet_nsg_association_id
  databricks_vnet_private_subnet_nsg_association_id = module.vnet.databricks_private_subnet_nsg_association_id
}

module "mssql" {
  source   = "./modules/mssql"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  sku                           = var.mssql_sku
  max_size_gb                   = var.mssql_max_size_gb
  public_ip_address_to_allow    = var.public_ip_address_to_allow
  public_network_access_enabled = var.mssql_public_network_access_enabled
  admin_admin                   = var.mssql_admin_login
  admin_login_password          = var.mssql_admin_login_password
  default_subnet_id             = module.vnet.default_subnet_id
  databricks_public_subnet_id   = module.vnet.databricks_public_subnet_id
  databricks_private_subnet_id  = module.vnet.databricks_private_subnet_id
}

module "keyvault" {
  source   = "./modules/keyvault"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  mssql_admin_login          = var.mssql_admin_login
  mssql_admin_login_password = var.mssql_admin_login_password
  datalake_connection_string = module.datalake.primary_connection_string
  datalake_access_key        = module.datalake.primary_access_key
}

resource "local_file" "databricks_tfvars" {
  content = <<EOF
workspace_url        = "${module.databricks.workspace_url}"
keyvault_resource_id = "${module.keyvault.id}"
keyvault_uri         = "${module.keyvault.vault_uri}"
mssql_fqdn           = "${module.mssql.fully_qualified_domain_name}"
dls_name             = "${module.datalake.storage_account_name}"
EOF

  filename = "${path.module}/databricks/.auto.tfvars"
}
