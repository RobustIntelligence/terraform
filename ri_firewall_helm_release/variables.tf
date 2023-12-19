variable "acm_cert_arn" {
  description = "ARN for the ACM cert to validate our domain."
  type        = string
}

variable "firewall_system_config" {
  description = <<EOT
  Initial firewall system configuration.
  This includes information about which model provider (OpenAI or Azure OpenAI)
  we will use for evaluation.
  It has no customer configuration; the customer can configure certain fields
  later with an API call.
  EOT
  type        = any
}

variable "create_managed_helm_release" {
  description = <<EOT
  Whether to deploy a RI Firewall Helm chart onto the provisioned infrastructure managed by Terraform.
  Changing the state of this variable will either install/uninstall the RI Firewall deployment
  once the change is applied in Terraform. If you want to install the RI Firewall package manually,
  set this to false and use the generated values YAML file to deploy the release
  on the provisioned infrastructure.
  EOT
  type        = bool
  default     = false
}

variable "datadog_tag_pod_annotation" {
  description = "Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {\"tag\": \"val\"}."
  type        = string
  default     = ""
}

variable "docker_credentials" {
  description = <<EOT
  Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:
  [{
    docker-server= "",
    docker-username="",
    docker-password="",
    docker-email=""
  }]
  EOT
  type        = list(map(string))
}

variable "docker_secret_name" {
  description = "The name of the Kubernetes secret used to pull the Docker image for RIME's backend services."
  type        = string
  default     = "rimecreds"
}

variable "ingress_class_name" {
  description = "The name of the ingress class to use for RI Firewall services. If empty, ingress class will be ri-<namespace>"
  type        = string
  default     = ""
}


variable "domain" {
  description = "Domain to use for the Firewall."
  type        = string
}

variable "enable_datadog_integration" {
  description = <<EOT
  Enable datadog integration. This integration allows customers to visualize the performance
  of AI Firewall in their Datadog account via metrics and dashboard. Enabling this flag requires: 1) A
  datadog agent to be installed on this cluster with the robustintelligencehq/datadog-agent-firewall-integration
  image using the rime-extras package and 2) The Robust intelligence AI Firewall integration installed
  in your Datadog account.
  EOT
  type        = bool
  default     = false
}

variable "manage_namespace" {
  description = <<EOT
  Whether or not to manage the namespace we are installing into.
  This will create the namespace(if applicable), setup docker credentials as a
  kubernetes secret etc. Turn this flag off if you have trouble connecting to
  k8s from your terraform environment.
  EOT
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace where the RI Firewall Helm chart will be installed."
  type        = string
}

variable "override_values_file_path" {
  description = <<EOT
  Optional file path to override values file for the ri firewall helm release.
  These values take precendence over values produced by the terraform module.
  EOT
  type        = string
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key for using tests that rely on OpenAI models."
  type        = string
}

variable "huggingface_api_key" {
  description = "HuggingFace API key for using tests that require downloading private models from HuggingFace."
  type        = string
}


variable "yara_github_read_token" {
  description = "Read-only token to rime-yara GitHub repo to pull latest YARA patterns."
  type        = string
}

variable "ri_firewall_repository" {
  description = "Repository URL where to locate the requested RI Firewall chart for the given `ri_firewall_version`."
  type        = string
}

variable "ri_firewall_version" {
  description = "The version of the RI Firewall software to be installed."
  type        = string
}

variable "release_name" {
  description = "helm release name. Must be set in a multitenant setting"
  type        = string
  default     = "ri-firewall"
}

variable "enable_auth0" {
  description = "Whether to enable auth0 for the firewall server."
  type        = bool
  default     = true
}
