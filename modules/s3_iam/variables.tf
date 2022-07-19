variable "k8s_namespace" {
  description = "Namespace where the RIME Helm chart is to be installed."
  type = object({
    namespace = string
    primary   = bool
  })
  # This module requires that these conditions are met.
  # The validation conditions should match the ones in the outer most level where k8s_namespace string is first passed as input.
  # Redundant validation is added here as a safeguard for when the outer most k8s_namespace conidtion is editted without updating this condition.
  # The conditions are required because k8s_namespace is included in the blob-store S3 bucket name, which has a limit on length and what characters can be included.
  validation {
    condition     = length(var.k8s_namespace.namespace) <= 12 && can(regex("^[a-z0-9.-]+$", var.k8s_namespace.namespace))
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
}

variable "service_account_name" {
  description = "The name of the service account to link to the IAM role"
  type        = string
}

variable "s3_authorized_bucket_path_arns" {
  description = <<EOT
  A list of all S3 bucket path arns of which RIME will be granted access to.
  Each path must be of the form:
      arn:aws:s3:::<BUCKET>/sub/path
  where <BUCKET> is the name of the S3 bucket and `sub/path` comprises
  some path within the bucket. You can also use wildcards '?' or '*' within
  the arn specification (e.g. 'arn:aws:s3:::datasets/*').
  EOT
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
