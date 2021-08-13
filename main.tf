terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.61.0"
    }
  }
}

provider "azurerm" {
subscription_id = "5e2c0804-4181-4e60-ac99-ad6e00eda51c"
features{}
}

data "azurerm_resource_group" "rg" {
  name = "GE-NALH"
}

data "azurerm_storage_account" "storage_account" {
  name                = "nalhtestdatalake"
  resource_group_name = "GE-NALH"
}

data "azuread_group" "example" {
  for_each         = toset(["@Capital NALH Azure_unity_Data_Admins_dev", "@Capital NALH Azure_prism_Data_Admins_dev", "@Capital NALH Azure_eas_Data_Admins_dev"])
  display_name     = each.key
}

resource "azurerm_storage_data_lake_gen2_filesystem" "container" {
  for_each           = toset(["raw", "curated", "ds-workspace"])
  name               = each.key
  storage_account_id = data.azurerm_storage_account.storage_account.id
}

# ADLS Directories
resource "azurerm_storage_data_lake_gen2_path" "raw" {
  for_each           = toset(["ltc/unity", "premium rate increase/prism"])
  path               = each.key
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.container["raw"].name
  storage_account_id = data.azurerm_storage_account.storage_account.id
  resource           = "directory"
  ace {    
    type = "group"
    scope = "access"
    id = each.key == "ltc" ? data.azuread_group.example["@Capital NALH Azure_unity_Data_Admins_dev"].object_id : each.key == "unity" ? data.azuread_group.example["@Capital NALH Azure_unity_Data_Admins_dev"].object_id : each.key == "premium rate increase" ? data.azuread_group.example["@Capital NALH Azure_prism_Data_Admins_dev"].object_id : each.key == "prism" ? data.azuread_group.example["@Capital NALH Azure_prism_Data_Admins_dev"].object_id : ""
    permissions = each.key == "ltc" ? "[r-][w-][x-]": each.key == "premium rate increase" ? "[r-][w-][x-]" : ""
  }
}

/*
resource "azurerm_storage_data_lake_gen2_path" "curated" {
  for_each           = toset(["Safe-Harbor", "common", "Liberty-island/ltc/unity", "Liberty-island/Premium rate increase/prism"])
  path               = each.key
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.container["curated"].name
  storage_account_id = data.azurerm_storage_account.storage_account.id
  resource           = "directory"
}


resource "azurerm_storage_data_lake_gen2_path" "ds_workspace" {
  for_each           = toset(["pri/base dataset", "claims prediction/base dataset"])
  path               = each.key
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.container["ds-workspace"].name
  storage_account_id = data.azurerm_storage_account.storage_account.id
  resource           = "directory"
}

*/