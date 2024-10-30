variable "helm_values_output_dir" {
  description = <<EOT
  The directory where to write the generated values YAML file used to configure the Helm release.
  For the give namespace `k8s_namespace`, a Helm chart "$helm_values_output_dir/values_$namespace.yaml"
  will be created.
  EOT
  type        = string
  default     = ""
}

variable "acm_cert_arn" {
  description = "ARN for the ACM cert to validate the Firewall domain."
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

variable "enable_logscale_logging" {
  description = <<EOT
  Enable logging firewall validation logs to logscale(crowdstrike). This integration allows customers to visualize the performance
  of RI Firewall in their logscale account via dashboard. Enabling this flag requires: 1) A
  Logscale agent to be installed using the rime-extras package and 2) The Robust intelligence Firewall integration installed
  in your logscale account.
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

variable "huggingface_api_key" {
  description = "HuggingFace API key to Robust Intelligence's private HuggingFace repo."
  type        = string
}

variable "maxmind_license_key" {
  description = "MaxMind license key to use the MaxMind GeoIP2 database."
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

variable "enable_register_firewall_agent" {
  description = "Whether to enable the register firewall agent job."
  type        = bool
  default     = false
}

variable "create_firewall_agent" {
  description = "Whether to create a new firewall agent."
  type        = bool
  default     = false
}

variable "agent_id" {
  description = "The ID of the agent being deployed. Not required if `create_firewall_agent` is true."
  type        = string
  default     = ""
}

variable "api_key" {
  description = "The single-use API key to register the agent. Not required if `create_firewall_agent` is true."
  type        = string
  default     = ""
  sensitive   = true
}

variable "agent_override_values_file" {
  description = "The file where agent override values are stored."
  type        = string
  default     = "./agent_override_values.yaml"
}

variable "control_plane_cluster_name" {
  description = "The name of the cluster where the Control Plane is deployed."
  type        = string
  default     = ""
}

variable "control_plane_namespace" {
  description = "The name of the namespace where the Control Plane is deployed."
  type        = string
  default     = ""
}

variable "platform_address" {
  description = "The URL of the control plane. For example https://my_firewall.firewall.rbst.io."
  type        = string
  default     = ""
}

# Allows us to make elements of this helm release depend on outputs from other resources
variable "dependency_link" {
  description = "The dependency link to the helm release."
  type        = map(string)
  default     = {}
}

variable "validate_response_visibility_control" {
  description = <<EOT
  Control for which part of the Validate response appears in stdout and the API.
  `firewall_request_*` controls the visibility of the raw user request to the firewall.
  `rule_eval_metadata_*` controls the visibility of internal evaluation metadata such as
    model scores and model versions.
  EOT
  type = object({
    firewall_request_enable_stdout_logging         = bool
    firewall_request_enable_api_response           = bool
    rule_evaluation_metadata_enable_stdout_logging = bool
    rule_evaluation_metadata_enable_api_response   = bool
  })
  default = {
    firewall_request_enable_stdout_logging         = false
    firewall_request_enable_api_response           = false
    rule_evaluation_metadata_enable_stdout_logging = true
    rule_evaluation_metadata_enable_api_response   = false
  }
}
