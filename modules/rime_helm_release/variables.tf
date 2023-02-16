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

variable "image_registry_config" {
  description = "Settings that configure the ECR registry used for RIME managed images."
  type = object({
    registry_type                = string
    allow_external_custom_images = bool
    // TODO(11974): make this optional once we switch to TF >= 1.3.0.
    ecr_config = object({
      registry_id       = string
      repository_prefix = string
    })
    // TODO(11974): make this optional once we switch to TF >= 1.3.0.
    gar_config = object({
      location   = string
      project    = string
      repository = string
    })
    // TODO: refactor these variables into something that is platform agnostic.
    image_builder_role_arn = string
    repo_manager_role_arn  = string
  })
  validation {
    condition = (
      (
        // See https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html
        // for repository naming rules.
        var.image_registry_config.registry_type != "ecr" || (
          var.image_registry_config.ecr_config != null &&
          can(regex("^[0-9]{12}$", var.image_registry_config.ecr_config.registry_id)) &&
          can(regex("^[a-z][a-z0-9]*(?:[/_-][a-z0-9]+)*$", var.image_registry_config.ecr_config.repository_prefix))
        )
        ) && (
        // See https://cloud.google.com/compute/docs/naming-resources
        // for GCP naming conventions for resources.
        var.image_registry_config.registry_type != "gar" || (
          var.image_registry_config.gar_config != null &&
          can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.image_registry_config.gar_config.project)) &&
          can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.image_registry_config.gar_config.repository))
        )
      )
    )
    error_message = (
      var.image_registry_config.registry_type == "ecr" ?
      "The ecr registry id must be a 12 digit aws_account_id and the ecr repository prefix must be 1 or more lowercase alphanumeric words separated by a '-', '_', or '/' where the first character is a letter." :
      var.image_registry_config.registry_type == "gar" ?
      "The gar config is malformed" :
      "unknown registry type: %{if var.image_registry_config.registry_type != null}${var.image_registry_config.registry_type}%{else}null%{endif}"
    )
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

variable "rime_docker_managed_base_image" {
  description = "The name of the base Docker image from which managed images are built"
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

variable "use_blob_store" {
  description = "Whether to use blob store for the cluster."
  type        = bool
  default     = true
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
  default     = true
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

variable "user_pilot_flow" {
  description = "A unique flow ID shown when choosing the option of \"Trigger manually\" on userpilot dashboard"
  type        = string
}

variable "internal_lbs" {
  description = "Whether or not the load balancers should be spun up as internal."
  type        = bool
}

variable "ip_allowlist" {
  # Note: external client IP addresses are preserved by load balancer. You may also want to include the external IP
  # address for the cluster on the allowlist if OIDC is being used, since OIDC will make a callback to the auth-server
  # using that IP address.
  description = "A set of CIDR routes to add to the allowlist for all ingresses. If not specified, all IP addresses are allowed."
  type        = list(string)
  default     = []
}

variable "enable_api_key_auth" {
  description = "Use api keys to authenticate api requests"
  type        = bool
  default     = true
}

variable "enable_additional_mongo_metrics" {
  description = "If enabled, mongo will expose additional collection-level metrics to the datadog agent"
  type        = bool
  default     = true
}

variable "model_test_job_config_map" {
  description = "The name of the configmap to create that will be used to inject env variables into model test jobs"
  type        = string
  default     = ""
}

variable "use_rmq_health" {
  description = "Whether to start the rmq-health service."
  type        = bool
  default     = true
}

variable "use_rmq_resource_cleaner" {
  description = "Whether to use the rmq resource cleaner given that the rmq-health service is used."
  type        = bool
  default     = true
}

variable "rmq_resource_cleaner_frequency" {
  description = "The frequency for running the rmq resource cleaner."
  type        = string
  default     = "5m"
}

variable "use_rmq_metrics_updater" {
  description = "Whether to use the rmq metrics updater given that the rmq-health service is used."
  type        = bool
  default     = true
}

variable "rmq_metrics_updater_frequency" {
  description = "The frequency for updating the rmq metrics."
  type        = string
  default     = "1s"
}

variable "separate_model_testing_group" {
  description = "Whether to force model testing jobs to run on dedicated model-testing nodes, using NodeSelectors"
  type        = bool
  default     = true
}

variable "create_scheduled_ct" {
  description = "Whether to deploy a RIME Scheduled CT Cron Job"
  type        = bool
  default     = false
}

variable "docker_registry" {
  description = "The name of the Docker registry that holds the chart images"
  type        = string
  default     = "docker.io"
}

variable "overwrite_license" {
  description = "Whether to use the license from the configured Secret Store to overwrite the cluster license. This variable is ignored during the first deployment."
  type        = bool
  default     = false
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
  Values produced by the terraform module will take precedence over these values.
  EOT
  type        = string
  default     = ""
}

variable "enable_external_agent" {
  description = <<EOT
  Whether or not to enable external agent access to your cluster. This will spin
  up an additional load balancer to handle grpc requests.
  EOT
  type        = bool
  default     = false
}
