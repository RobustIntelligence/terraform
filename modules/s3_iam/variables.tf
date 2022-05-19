variable "k8s_namespace" {
  description = "Namespace where the RIME Helm chart is to be installed."
  type = object({
    namespace = string
    primary   = bool
  })
}

variable "oidc_provider_url" {
  description = "URL to the OIDC provider for IAM assumable roles used by K8s."
  type        = string
}

variable "resource_name_suffix" {
  description = "A suffix to name the IAM policy and role with."
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
