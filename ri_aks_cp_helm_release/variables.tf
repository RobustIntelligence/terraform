variable "admin_username" {
  description = "The initial admin username for your installation. Must be a valid email."
  type        = string
}

variable "admin_password" {
  description = "The initial admin password for your installation"
  type        = string
}

variable "certificate_secret_name" {
  description = <<EOT
  Name of the tls secret containing the certificate you want to expose externally.
  This should be a certificate that is valid for the domain you will be exposing
  the ri control plane on.
  EOT
  type        = string
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

variable "docker_image_names" {
  description = <<EOT
  The configuration for the docker images used to run rime, each of which
  is in the docker registry specified by `docker_registry`. These image names
  serve the following purpose.
    * backend:            the image for RIME's backend services.
    * frontend:           the image for RIME's frontend services.
  EOT
  type = object({
    backend  = string
    frontend = string
  })
  default = {
    backend  = "robustintelligencehq/rime-backend"
    frontend = "robustintelligencehq/rime-frontend"
  }
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

variable "domain" {
  description = "The domain to use for all exposed rime services."
  type        = string
}

variable "disable_vault_tls" {
  description = "disable tls for vault"
  type        = bool
  default     = false
}

variable "enable_mongo_tls" {
  description = "enable tls for mongo"
  type        = bool
  default     = true
}

variable "enable_rest_tls" {
  description = "enable tls for rest"
  type        = bool
  default     = true
}

variable "enable_grpc_tls" {
  description = "enable tls for grpc"
  type        = bool
  default     = true
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

variable "enable_autorotate_tls" {
  description = "enable auto rotation for tls"
  type        = bool
  default     = true
}

variable "external_vault" {
  description = "Whether to use external Vault."
  type        = bool
  default     = false
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
  description = "Namespace where the RIME Helm chart is to be installed."
  type        = string
}

variable "rime_license" {
  description = "Json Web Token containing Robust Intelligence license information."
  type        = string
}

variable "rime_repository" {
  description = "Repository URL where to locate the requested RIME chart for the given `rime_version`."
  type        = string
}

// TODO(blaine): should we peg the TF module version & the Helm chart version since they
// interact through the values template?
variable "rime_version" {
  description = "The version of the RIME software to be installed."
  type        = string
}

variable "mongo_db_size" {
  description = "MongoDb volume size"
  type        = string
  default     = "32Gi"
}

// TODO(chris): change to verbosity level instead of boolean
variable "verbose" {
  description = "Whether to use verbose mode for RIME application services."
  type        = bool
  default     = false
}

variable "internal_lbs" {
  description = "Whether or not the load balancers should be spun up as internal."
  type        = bool
  default     = false
}

variable "ip_allowlist" {
  # Note: external client IP addresses are preserved by the load balancer. You may also want to include the external IP
  # address for the cluster on the allowlist if OIDC is being used, since OIDC will make a callback to the auth-server
  # using that IP address.
  description = "A set of CIDR routes to add to the allowlist for all ingresses. If not specified, all IP addresses are allowed."
  type        = list(string)
  default     = []
}

variable "separate_model_testing_group" {
  description = "Whether to force model testing jobs to run on dedicated model-testing nodes, using NodeSelectors"
  type        = bool
  default     = true
}

variable "storage_class_name" {
  description = "Name of storage class to use for persistent volumes"
  type        = string
  default     = "default"
}

variable "release_name" {
  description = "helm release name"
  type        = string
  default     = "rime"
}

variable "datadog_tag_pod_annotation" {
  description = "Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {\"tag\": \"val\"}."
  type        = string
  default     = ""
}

variable "override_values_file_path" {
  description = <<EOT
  Optional file path to override values file for the rime helm release.
  EOT
  type        = string
  default     = ""
}
