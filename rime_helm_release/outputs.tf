output "blob_store_bucket_arn" {
  value = var.enable_blob_store ? module.blob_store[0].blob_store_bucket_arn : ""
}

output "blob_store_bucket_name" {
  value = var.enable_blob_store ? module.blob_store[0].blob_store_bucket_name : ""
}

output "internal_firewall_agent_api_key_secret_name" {
  value = local.internal_firewall_agent_api_key_secret_name
}

output "dependency_link" {
  value = var.create_managed_helm_release ? { namespace = helm_release.rime[0].metadata[0].namespace } : {}
}
