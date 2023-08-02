variable "namespace" {
  description = "The k8s namespace to install the rime-agent into"
  type        = string
}

variable "override_values_file_path" {
  description = <<EOT
  Optional file path to override values file for the rime-agent helm release.
  EOT
  type        = string
  default     = ""
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
  description = <<EOT
  A suffix to use with the names of resources created by this module.
  EOT
  type        = string
}

variable "azure_storage_account_name" {
  description = "The name of the Azure storage account to use for the RIME backend."
  type        = string
}

variable "azure_storage_account_resource_group" {
  description = "The name of the Azure storage account to use for the RIME backend."
  type        = string
}

variable "create_managed_helm_release" {
  description = <<EOT
  Whether to deploy the RIME Agent Helm chart onto the provisioned infrastructure managed by Terraform.
  Changing the state of this variable will either install/uninstall the RIME deployment
  once the change is applied in Terraform. If you want to install the RIME package manually,
  set this to false and use both the custom values file and the terraform generated values YAML file to deploy the release
  on the provisioned infrastructure.
  EOT
  type        = bool
  default     = false
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

variable "helm_values_output_dir" {
  description = <<EOT
  The directory where to write the generated values YAML file used to configure the Helm release.
  For the give namespace `k8s_namespace`, a Helm chart "$helm_values_output_dir/values_$namespace.yaml"
  will be created.
  EOT
  type        = string
  default     = ""
}

variable "docker_secret_name" {
  description = "The name of the Kubernetes secret used to pull the Docker image for RIME's backend services."
  type        = string
  default     = "rimecreds"
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

variable "rime_docker_agent_image" {
  description = "The name of the Docker image for the RIME agent, not including a tag."
  type        = string
  default     = "robustintelligencehq/rime-agent"
}

variable "rime_docker_default_engine_image" {
  description = "The name of the Docker image used as the default for the RIME engine, not including a tag."
  type        = string
  default     = "robustintelligencehq/rime-testing-engine-dev"
}

variable "docker_registry" {
  description = "The name of the Docker registry that holds the chart images"
  type        = string
  default     = "docker.io"
}

variable "oidc_issuer_url" {
  description = "URL to the OIDC issuer for workload identity assumable roles used by K8s."
  type        = string
}

variable "cp_release_name" {
  description = "Name of the control plane helm release to determine addresses."
  type        = string
  default     = "rime"
}

variable "cp_namespace" {
  description = "Namespace where the control plane helm chart is installed. Used to determine addresses."
  type        = string
  default     = "default"
}

variable "datadog_tag_pod_annotation" {
  description = "Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {\"tag\": \"val\"}."
  type        = string
  default     = ""
}

variable "enable_crossplane_tls" {
  description = "enable tls for crossplane"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "enable deployment of cert-manager"
  type        = bool
  default     = true
}

variable "separate_model_testing_group" {
  description = "Whether to force model testing jobs to run on dedicated model-testing nodes, using NodeSelectors"
  type        = bool
  default     = true
}
