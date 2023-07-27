variable "helm_values_output_dir" {
  description = <<EOT
  The directory where to write the generated values YAML file used to configure the Helm release.
  A Helm chart "$helm_values_output_dir/rime_kube_system_values.yaml"
  will be created.
  EOT
  type        = string
  default     = ""
}

variable "create_managed_helm_release" {
  description = <<EOT
  Whether to deploy a RIME Helm chart onto the provisioned infrastructure managed by Terraform.
  Changing the state of this variable will either install/uninstall the RIME deployment
  once the change is applied in Terraform. If you want to install the RIME package manually,
  set this to false and use the generated values YAML file to deploy the release
  on the provisioned infrastructure.
  EOT
  type        = bool
  default     = false
}

variable "install_datadog" {
  description = "Whether or not to install the Datadog Agent."
  type        = bool
  default     = false
}

variable "datadog_api_key" {
  description = "API key for the Datadog server that will be used by the Datadog Agent."
  type        = string
  sensitive   = true
}

variable "rime_user" {
  description = "User of the RIME deployment."
  type        = string
}

variable "install_velero" {
  description = "Whether or not to install Velero."
  type        = bool
  default     = false
}

variable "velero_backup_schedule" {
  description = "Backup schedule time in cron time string format."
  type        = string
}

variable "velero_backup_ttl" {
  description = "Time to live for the Velero backup."
  type        = string
}

variable "velero_backup_namespaces" {
  description = "Namespaces to backup."
  type        = list(string)
}

variable "rime_repository" {
  description = "Repository URL where to locate the requested RIME chart for the give `rime_version`."
  type        = string
}

variable "rime_version" {
  description = "The version of the RIME software to be installed."
  type        = string
}

variable "resource_name_suffix" {
  description = "A suffix to name the IAM policy and role with."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL to the OIDC provider for IAM assumable roles used by K8s."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
}

variable "docker_registry" {
  description = "The name of the Docker registry that holds the chart images"
  type        = string
  default     = "docker.io"
}

variable "rime_docker_secret_name" {
  description = "The name of the Kubernetes secret used to pull the Docker image for RIME's backend services."
  type        = string
  default     = "rimecreds"
}
