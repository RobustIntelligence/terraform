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

variable "docker_registry" {
  description = "The name of the Docker registry that holds the images for the chart."
  type        = string
  default     = "docker.io"
}

variable "docker_secret_name" {
  description = "The name of the Kubernetes secret used to pull the Docker image for RIME."
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

variable "override_values_file_path" {
  description = <<EOT
  Optional file path to override values file for the rime helm release.
  EOT
  type        = string
  default     = ""
}

variable "rime_helm_repository" {
  description = "Helm Repository URL where the requested RIME chart for is located`."
  type        = string
}

variable "rime_version" {
  description = "The version of the RIME software to be installed."
  type        = string
}

variable "enable_cert_manager" {
  description = "enable deployment of cert-manager"
  type        = bool
  default     = true
}
