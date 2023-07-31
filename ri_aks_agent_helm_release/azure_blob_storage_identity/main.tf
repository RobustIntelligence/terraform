resource "azuread_application" "default" {
  display_name = "rime-blob-reader-${var.resource_name_suffix}"
}

resource "azuread_service_principal" "default" {
  application_id               = azuread_application.default.application_id
  app_role_assignment_required = false
}

resource "azuread_application_federated_identity_credential" "default" {
  for_each = toset(var.service_account_names)

  application_object_id = azuread_application.default.object_id
  display_name          = "azure-blob-reader--${var.resource_name_suffix}-${each.key}"
  description           = "Kubernetes service account federated credential"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = var.oidc_issuer_url
  subject               = "system:serviceaccount:${var.namespace}:${each.key}"
}

## Lookup our storage account
data "azurerm_storage_account" "storage_account" {
  name                = var.azure_storage_account_name
  resource_group_name = var.azure_storage_account_resource_group
}

## Role assignment to the application
resource "azurerm_role_assignment" "storage_reader" {
  scope                = data.azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.default.id
}
