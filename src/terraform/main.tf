resource "azurerm_resource_group" "example" {
  name     = "rg-${var.application_name}-${var.environment_name}-${var.primary_region}-${random_string.main.result}"
  location = var.primary_region
}

resource "azurerm_cosmosdb_account" "example" {
  name                      = "cosmos-${var.application_name}-${var.environment_name}-${var.primary_region}-${random_string.main.result}"
  location                  = var.cosmosdb_account_location
  resource_group_name       = azurerm_resource_group.example.name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = false
  enable_free_tier          = true
  geo_location {
    location          = var.location
    failover_priority = 0
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
  depends_on = [
    azurerm_resource_group.example
  ]
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "${random_pet.prefix.id}-cosmosdb-sqldb"
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
  throughput          = var.throughput
}

resource "azurerm_cosmosdb_sql_container" "example" {
  name                  = "${random_pet.prefix.id}-sql-container"
  resource_group_name   = azurerm_resource_group.example.name
  account_name          = azurerm_cosmosdb_account.example.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_path    = "/definition/id"
  partition_key_version = 1
  throughput            = var.throughput

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }

  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }
}

resource "random_string" "main" {
  length  = 8
  upper   = false
  special = false
}