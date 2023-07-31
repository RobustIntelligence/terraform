output "azure_blob_reader_tenant_id" {
  description = "The tenant ID of the Azure Blob Reader Service Principal"
  value       = azuread_service_principal.default.application_tenant_id
}

output "azure_blob_reader_client_id" {
  description = "The client ID of the Azure Blob Reader Service Principal"
  value       = azuread_service_principal.default.application_id
}
