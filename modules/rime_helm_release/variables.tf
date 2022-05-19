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

// See https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html
// for repository naming rules.
variable "image_registry_config" {
  description = "Settings that configure the ECR registry used for RIME managed images."
  type = object({
    enable                       = bool
    allow_external_custom_images = bool
    image_builder_role_arn       = string
    registry_id                  = string
    repo_manager_role_arn        = string
    repository_prefix            = string
  })
  validation {
    condition     = !var.image_registry_config.enable || (can(regex("^[0-9]{12}$", var.image_registry_config.registry_id)) && can(regex("^[a-z][a-z0-9]*(?:[/_-][a-z0-9]+)*$", var.image_registry_config.repository_prefix)))
    error_message = "The ecr registry id must be a 12 digit aws_account_id and the ecr repository prefix must be 1 or more lowercase alphanumeric words separated by a '-', '_', or '/' where the first character is a letter."
  }
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

variable "k8s_namespace" {
  description = "Namespace where the RIME Helm chart is to be installed."
  type        = string
  validation {
    condition     = var.k8s_namespace != "app"
    error_message = "The namespace 'app' is reserved."
  }
}

variable "name" {
  description = "The name for this module."
  type        = string
}

variable "oauth_config" {
  description = "Settings that configure oauth authentication."
  type = object({
    client_id     = string
    client_secret = string
    auth_url      = string
    token_url     = string
    user_info_url = string
  })

  sensitive = true
}

variable "rime_docker_backend_image" {
  description = "The name of the Docker image for RIME's backend services."
  type        = string
}

variable "rime_docker_frontend_image" {
  description = "The name of the Docker image for RIME's frontend service."
  type        = string
}

variable "rime_docker_image_builder_image" {
  description = "The name of the Docker image for RIME's image builder service."
  type        = string
}

variable "rime_docker_model_testing_image" {
  description = "The name of the Docker image for RIME's model testing jobs."
  type        = string
}

variable "rime_docker_secret_name" {
  description = "The name of the Kubernetes secret used to pull the Docker image for RIME's backend services."
  type        = string
}

variable "domain" {
  description = "The domain to use for all exposed rime services."
  type        = string
}

variable "rime_jwt" {
  description = "Json Web Token containing Robust Intelligence license information."
  type        = string
}

variable "datadog_frontend_client_token" {
  description = "Datadog frontend client token."
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

variable "s3_reader_role_arn" {
  description = "ARN for the role that allows RBAC roles read access to selected S3 buckets."
  type        = string
}

variable "use_blob_store" {
  description = "Whether to use blob store for the cluster."
  type        = bool
  default     = false
}

variable "s3_blob_store_role_arn" {
  description = "Role ARN if needed to for blob store service operations."
  type        = string
  default     = ""
}

variable "s3_blob_store_bucket_name" {
  description = "Bucket name of the bucket used for blob store."
  type        = string
  default     = ""
}


variable "use_file_upload_service" {
  description = "Whether to use file upload service."
  type        = bool
  default     = false
}

variable "mongo_db_size" {
  description = "MongoDb volume size"
  type        = string
  default     = "32Gi"
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
}

variable "load_balancer_security_groups_ids" {
  description = "List of security group ids to add to the load balancers."
  type        = list(string)
}

// TODO(chris): change to verbosity level instead of boolean
variable "verbose" {
  description = "Whether to use verbose mode for RIME application services."
  type        = bool
  default     = false
}

variable "acm_cert_arn" {
  description = "ARN for the acm cert to validate our domain."
  type        = string
}

variable "admin_api_key" {
  description = "Admin API Key to be installed into the cluster."
  type        = string
}

variable "enable_firewall" {
  description = "Enable rime firewall"
  type        = bool
}

variable "vouch_whitelist_domains" {
  description = "List of domains to add to the vouch domains whitelist. If no whitelist domains are specified, all domains will be allowed."
  type        = list(string)
  default     = []
}

variable "enable_vouch" {
  description = "Use oidc/vouch to protect the frontend"
  type        = bool
}

variable "internal_lbs" {
  description = "Whether or not the load balancers should be spun up as internal."
  type        = bool
}
