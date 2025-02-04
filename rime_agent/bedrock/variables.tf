variable "namespace" {
  description = "The k8s namespace to install the rime-agent into"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL to the OIDC provider for IAM assumable roles used by K8s."
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

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
