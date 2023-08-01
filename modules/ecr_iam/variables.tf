variable "ecr_registry_arn" {
  description = "ARN of the registry to store custom built rime images."
  type        = string
  validation {
    condition     = can(regex("^arn:aws:ecr:[\\w-]+:[0-9]{12}$", var.ecr_registry_arn))
    error_message = "The ecr arn must be of the form 'arn:aws:ecr:<region>:<aws_account_id>' where region is a region name and aws_account_id is 12 digits."
  }
}

variable "k8s_namespaces" {
  description = <<EOT
    All Kubernetes namespaces where the RIME Helm chart is to be installed.
    A Helm chart will be constructed for each of these called "$helm_values_output_dir/values_$namespace.yaml".
    For manual installation of these Helm charts, be sure to install them in their intended namespace.
    EOT
  type = set(object({
    namespace = string
    primary   = bool
  }))
}

variable "oidc_provider_url" {
  description = "URL to the OIDC provider for IAM assumable roles used by K8s."
  type        = string
}

variable "repository_prefix" {
  description = "Prefix used for all repositories created and managed by the RIME Image Registry service."
  type        = string
  // See https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html
  // for repository naming rules.
  validation {
    condition     = can(regex("^[a-z][a-z0-9]*(?:[/_-][a-z0-9]+)*$", var.repository_prefix))
    error_message = "The repository prefix must be 1 or more lowercase alphanumeric words separated by a '-', '_', or '/' where the first character is a letter."
  }
}

variable "resource_name_suffix" {
  description = "A suffix to name the IAM policies and roles with."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default     = {}
}
