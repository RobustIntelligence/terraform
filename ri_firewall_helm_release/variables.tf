variable "acm_cert_arn" {
  description = "ARN for the ACM cert to validate the Firewall domain."
  type        = string
}

variable "azure_openai_api_base_url" {
  description = "Base URL for the Azure OpenAI models used for internal rule implementation."
  type        = string
}

variable "azure_openai_api_version" {
  description = "API Version of Azure OpenAI used for internal rule implementation."
  type        = string
}

variable "azure_openai_chat_model_deployment_name" {
  description = "Name of the chat model deployed on Azure OpenAI used for internal rule implementation."
  type        = string
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
  description = "The name of the Kubernetes secret used to pull the Docker images for the Firewall."
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
  Enable Datadog integration. This integration allows customers to visualize the performance
  of RI Firewall in their Datadog account via metrics and dashboard. Enabling this flag requires: 1) A
  Datadog agent to be installed on this cluster with the robustintelligencehq/datadog-agent-firewall-integration
  image using the rime-extras package and 2) The Robust intelligence Firewall integration installed
  in your Datadog account.
  EOT
  type        = bool
  default     = false
}

variable "log_user_data" {
  description = <<EOT
  Whether to log user data for firewall requests in this cluster.
  Be careful with this option, because using this when we should not opens us
  up to legal trouble.
  EOT
  type        = bool
  default     = false
}

variable "manage_namespace" {
  description = <<EOT
  Whether or not to manage the namespace we are installing into.
  This will create the namespace(if applicable), setup docker credentials as a
  Kubernetes secret etc. Turn this flag off if you have trouble connecting to
  k8s from your Terraform environment.
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
  Optional file path to override values file for the RI Firewall Helm release.
  These values take precedence over values produced by the Terraform module.
  EOT
  type        = string
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key to use for Firewall."
  type        = string
}

variable "huggingface_api_key" {
  description = "HuggingFace API key to Robust Intelligence's private HuggingFace repo."
  type        = string
}


variable "yara_github_read_token" {
  description = "Read-only token to rime-yara GitHub repo to pull latest YARA patterns."
  type        = string
}

variable "yara_auto_update_enabled" {
  description = "Whether to allow yara server to periodically update its rules via a pull mechanism."
  type        = bool
  default     = true
}

variable "yara_rule_repo_ref" {
  description = "The revision of the YARA rule git repo to pull at server initialization. If empty, the latest release will be used."
  type        = string
  default     = ""
}

variable "yara_pattern_update_frequency" {
  description = "The cron frequency at which yara server should update its rules. If empty and yara_auto_update_enabled is true, the default frequency is every hour."
  type        = string
  default     = ""
}

variable "ri_firewall_repository" {
  description = "Repository URL where to locate the requested RI Firewall Helm chart for the given `ri_firewall_version`."
  type        = string
}

variable "ri_firewall_version" {
  description = "The version of the RI Firewall to be installed."
  type        = string
}

variable "release_name" {
  description = "Helm release name. Required only in a multi-tenant setting"
  type        = string
  default     = "ri-firewall"
}

variable "enable_auth0" {
  description = "Whether to enable auth0 for the Firewall."
  type        = bool
  default     = true
}

variable "firewall_enable_yara" {
  description = "Whether to enable firewall rules to call into the YARA service."
  type        = bool
  default     = true
}
