variable "use_blob_store" {
  description = "Whether to use blob store for the cluster."
  type        = bool
  default     = false
}

variable "k8s_namespace" {
  description = "Namespace where the RIME Helm chart is installed."
  type        = string
  # This module requires that these conditions are met.
  # The validation conditions should match the ones in the outer most level where k8s_namespace string is first passed as input.
  # Redundant validation is added here as a safeguard for when the outer most k8s_namespace conidtion is editted without updating this condition.
  # The conditions are required because k8s_namespace is included in the blob-store S3 bucket name, which has a limit on length and what characters can be included.
  validation {
    condition     = length(var.k8s_namespace) <= 12 && can(regex("^[a-z0-9.-]+$", var.k8s_namespace))
    error_message = "Must not be longer than 12 characters and must contain only letters, numbers, dots (.), and hyphens (-)."
  }
}

variable "oidc_provider_url" {
  description = "URL to the OIDC provider for IAM assumable roles used by K8s."
  type        = string
}

variable "resource_name_suffix" {
  description = "A suffix to name the IAM policy and role with."
  type        = string
  # This module requires that these conditions are met.
  # The validation conditions should match the one in the outer most level where resource_name_suffix is first passed as input.
  # Redundant validation is added here as a safeguard for when the outer most resource_name_suffix conidtion is editted without updating this condition.
  # The conditions are required because resource_name_suffix is included in the blob-store S3 bucket name, which has a limit on length and what characters can be included.
  validation {
    condition     = length(var.resource_name_suffix) <= 25 && can(regex("^[a-z0-9.-]+$", var.resource_name_suffix))
    error_message = "Must not be longer than 25 characters and must contain only letters, numbers, dots (.), and hyphens (-)."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
