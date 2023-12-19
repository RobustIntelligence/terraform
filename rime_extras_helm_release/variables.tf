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

variable "datadog_api_key" {
  description = "API key for the Datadog server that will be used by the Datadog Agent."
  type        = string
  default     = ""
  sensitive   = true
}

variable "docker_credentials" {
  description = <<EOT
  Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:
  [[{
    docker-server= "",
    docker-username="",
    docker-password="",
    docker-email=""
  }]]
  EOT
  type        = list(map(string))
}

variable "docker_registry" {
  description = "The name of the Docker registry that holds the chart images"
  type        = string
  default     = "docker.io"
}

variable "docker_secret_name" {
  description = "The name of the Kubernetes secret used to pull the Docker image for RIME's backend services."
  type        = string
  default     = "rimecreds"
}

variable "helm_values_output_dir" {
  description = <<EOT
  The directory where to write the generated values YAML file used to configure the Helm release.
  A Helm chart "$helm_values_output_dir/rime_kube_system_values.yaml"
  will be created.
  EOT
  type        = string
  default     = ""
}

variable "install_datadog" {
  description = "Whether or not to install the Datadog Agent."
  type        = bool
  default     = false
}

variable "install_prometheus_node_exporter" {
  description = "Whether or not to install the Prometheus Node Exporter."
  type        = bool
  default     = false
}

variable "install_prometheus_server" {
  description = "Whether or not to install the Prometheus Server."
  type        = bool
  default     = false
}

variable "install_observability_proxy_server" {
  description = "Whether or not to install the Observability Proxy Server."
  type        = bool
  default     = false
}

variable "install_prometheus_cloudwatch_exporter" {
  description = "Whether or not to install the CloudWatch Exporter."
  type        = bool
  default     = false
}

variable "proxy_remote_write_url" {
  description = "URL of the remote write endpoint in the observability proxy server. Promethes server writes to this endpoint."
  type        = string
  default     = "http://observability-proxy-server:8000/remote_write"
}

variable "proxy_remote_write_port" {
  description = "Port for remote writing to the proxy server"
  type        = number
  default     = 8000
}

variable "api_gateway_remote_write_url" {
  description = "URL of the remote write endpoint in the API Gateway. The proxy server writes to this endpoint."
  type        = string
  default     = ""
}

variable "remote_write_secret_name" {
  description = "Name of the Kubernetes secret that holds the API key for the Prometheus remote write endpoint."
  type        = string
  default     = "remote-write-api-key"
}

variable "remote_write_api_key" {
  description = "API key for the Prometheus remote write endpoint."
  type        = string
  default     = ""
  sensitive   = true
}

variable "install_velero" {
  description = "Whether or not to install Velero. Do not enable for Firewall Deployments"
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

variable "oidc_provider_url" {
  description = "URL to the OIDC provider for IAM assumable roles used by K8s."
  type        = string
}

variable "override_values_file_path" {
  description = <<EOT
  Optional file path to override values file for the rime-extras helm release.
  EOT
  type        = string
  default     = ""
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

variable "rime_repository" {
  description = "Repository URL where to locate the requested RIME chart for the give `rime_version`."
  type        = string
}

variable "rime_user" {
  description = "User of the RIME deployment."
  type        = string
}

variable "rime_version" {
  description = "The version of the RIME software to be installed."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
}

variable "velero_backup_schedule" {
  description = "Backup schedule time in cron time string format."
  type        = string
  default     = "0 2 * * *"
}

variable "velero_backup_ttl" {
  description = "A suffix to name the IAM policy and role with."
  type        = string
  default     = "336h"
}

variable "cluster_name" {
  description = "Name of the cluster."
  type        = string
  default     = ""
}

variable "install_humio_fluentbit" {
  description = "Whether or not to install the Humio(Crowdstrike) fluent bit agent."
  type        = bool
  default     = false
}

variable "humio_hostname" {
  description = "Hostname of the cloud instance of the humio server"
  type        = string
  default     = ""
}

variable "humio_ingest_token" {
  description = "Ingest token for the cloud instance of the humio server"
  type        = string
  default     = ""
  sensitive   = true
}
