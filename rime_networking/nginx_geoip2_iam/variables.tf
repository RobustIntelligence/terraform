variable "resource_name_suffix" {
  description = "A suffix to name the IAM policy and role with."
  type        = string
  validation {
    condition     = length(var.resource_name_suffix) <= 25 && can(regex("^[a-z0-9.-]+$", var.resource_name_suffix))
    error_message = "Must not be longer than 25 characters and must contain only letters, numbers, dots (.), and hyphens (-)."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
  }
}

variable "oidc_provider_url" {
  description = "URL to the OIDC provider for IAM assumable roles used by K8s."
  type        = string
}

variable "namespace" {
  description = "Namespace where the RIME Helm chart is to be installed."
  type        = string
}

variable "service_account_names" {
  description = "The names of the service accounts to link to the IAM role"
  type        = list(string)
}
