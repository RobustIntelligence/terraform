variable "namespace" {
  description = "The k8s namespace to install the rime-agent into"
  type        = string
}

variable "oidc_issuer_url" {
  description = "URL to the OIDC issuer for workload identity assumable roles used by K8s."
  type        = string
}

variable "resource_name_suffix" {
  description = "A suffix to name the IAM policy and role with."
  type        = string
}

variable "service_account_names" {
  description = "The names of the service accounts to link to the IAM role"
  type        = list(string)
}

variable "azure_storage_account_name" {
  description = "The name of the Azure storage account to use for the RIME backend."
  type        = string
}

variable "azure_storage_account_resource_group" {
  description = "The name of the Azure storage account to use for the RIME backend."
  type        = string
}
