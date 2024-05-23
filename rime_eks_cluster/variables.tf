variable "cluster_name" {
  description = "Name of eks cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.25"
}

variable "public_cluster_endpoint_enabled" {
  description = "Whether to enable the EKS control plane's public cluster endpoint."
  type        = bool
  default     = true
}

variable "private_cluster_endpoint_enabled" {
  description = "Whether to enable the EKS control plane's private cluster endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks to allow public access to the EKS control plane."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_cluster_node_iam_policies" {
  description = "Policies to attach to eks worker nodes."
  type        = list(string)
  default     = []
}

variable "expandable_storage_class_name" {
  description = "By default, we create an expandable storage class. We allow the name of this storage class to be changed for legacy reasons."
  type        = string
  default     = "expandable-storage"
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. You will need to set this for any role you want to allow access to eks"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap. You will need to set this for any role you want to allow access to eks."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

variable "model_testing_worker_group_instance_types" {
  description = "Instance types for the model testing worker group."
  type        = list(string)
  default     = ["t3.xlarge", "t2.xlarge"]

  validation {
    condition     = length(var.model_testing_worker_group_instance_types) >= 1
    error_message = "Must specify at least one instance type."
  }
}

variable "model_testing_worker_group_min_size" {
  description = "Minimum size of the model testing worker group. Must be >= 0"
  type        = number
  default     = 0

  validation {
    condition     = var.model_testing_worker_group_min_size >= 0
    error_message = "Model testing worker group min size must be greater than or equal to 0."
  }
}

variable "model_testing_worker_group_desired_size" {
  description = <<EOT
  Desired size of the model testing worker group.
  If var.use_managed_node_group is true, must be >= 1; otherwise, must be >= 0.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.model_testing_worker_group_desired_size >= 0
    error_message = <<EOT
    Model testing worker group desired size must be greater than or equal to 0.
    If var.use_managed_node_group is true, must be >= 1.
    EOT
  }
}

variable "model_testing_worker_group_max_size" {
  description = "Maximum size of the model testing worker group. Must be >= min size. For best performance we recommend >= 10 nodes as the max size."
  type        = number
  default     = 10
}

variable "server_node_groups_overrides" {
  description = <<EOT
  A dictionary that specifies overrides for the server node group launch templates.
  See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/modules/node_groups/README.md for valid values.
  Only applies if using Managed node groups (var.use_managed_node_group = true).
  EOT
  type        = any
  default     = {}
}

variable "model_testing_worker_groups_overrides" {
  description = "A dictionary that specifies overrides for the model testing worker group launch templates. See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/locals.tf#L36 for valid values."
  type        = any
  default     = {}
}

variable "model_testing_node_groups_overrides" {
  description = <<EOT
  A dictionary that specifies overrides for the model testing node group launch templates.
  See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/modules/node_groups/README.md for valid values.
  Only applies if using Managed node groups (var.use_managed_node_group = true).
  EOT
  type        = any
  default     = {}
}

variable "model_testing_worker_group_use_spot" {
  description = "Use spot instances for model testing worker group."
  type        = bool
  default     = true
}

variable "model_testing_worker_group_root_volume_size" {
  description = "Root volume size in GB for the model testing worker group."
  type        = number
  default     = 100
}

variable "model_testing_worker_group_large_instance_types" {
  description = "Instance types for the large model testing worker group."
  type        = list(string)
  default     = ["m5.12xlarge", "m5a.12xlarge", "m5n.12xlarge", "m6i.12xlarge", "m6a.12xlarge", "m7i.12xlarge"]
  validation {
    condition     = length(var.model_testing_worker_group_large_instance_types) >= 1
    error_message = "Must specify at least one instance type."
  }
}

variable "model_testing_worker_group_large_min_size" {
  description = "Minimum size of the large model testing worker group. Must be >= 0"
  type        = number
  default     = 0

  validation {
    condition     = var.model_testing_worker_group_large_min_size >= 0
    error_message = "Large model testing worker group min size must be greater than or equal to 0."
  }
}

variable "model_testing_worker_group_large_desired_size" {
  description = <<EOT
  Desired size of the large model testing worker group.
  If var.use_managed_node_group is true, must be >= 1; otherwise, must be >= 0.
  EOT
  type        = number
  default     = 0

  validation {
    condition     = var.model_testing_worker_group_large_desired_size >= 0
    error_message = <<EOT
    Large model testing worker group desired size must be greater than or equal to 0.
    If var.use_managed_node_group is true, must be >= 1.
    EOT
  }
}

variable "model_testing_worker_group_large_max_size" {
  description = "Maximum size of the large model testing worker group. Must be >= min size. For best performance we recommend >= 10 nodes as the max size."
  type        = number
  default     = 10
}

variable "model_testing_worker_group_large_root_volume_size" {
  description = "Root volume size in GB for the large model testing worker group."
  type        = number
  default     = 100
}

variable "model_testing_worker_groups_large_overrides" {
  description = "A dictionary that specifies overrides for the large model testing worker group launch templates. See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/locals.tf#L36 for valid values."
  type        = any
  default     = {}
}

variable "private_subnet_ids" {
  description = "A list of private subnet ids to place the EKS cluster and workers within. Must be specified if create_eks is true"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "A list of public subnet ids for EKS cluster load balancers to work in"
  type        = list(string)
  default     = []
}

variable "server_worker_group_instance_types" {
  description = "Instance types for the server worker group."
  type        = list(string)
  default     = ["t3.xlarge"]

  validation {
    condition     = length(var.server_worker_group_instance_types) >= 1
    error_message = "Must specify at least one instance type."
  }
}

variable "server_worker_group_min_size" {
  description = "Minimum size of the server worker group. Must be >= 1"
  type        = number
  default     = 2

  validation {
    condition     = var.server_worker_group_min_size >= 1
    error_message = "Server worker group min size must be greater than or equal to 1."
  }
}

variable "server_worker_group_desired_size" {
  description = "Desired size of the server worker group. Must be >= 0"
  type        = number
  default     = 4

  validation {
    condition     = var.server_worker_group_desired_size >= 0
    error_message = "Server worker group desired size must be greater than or equal to 0."
  }
}

variable "server_worker_group_max_size" {
  description = "Maximum size of the server worker group. Must be >= min size. For best performance we recommend >= 10 nodes as the max size."
  type        = number
  default     = 10
}

variable "server_worker_group_root_volume_size" {
  description = "Root volume size in GB for the large server worker group."
  type        = number
  default     = 100
}


variable "server_worker_groups_overrides" {
  description = "A dictionary that specifies overrides for the server worker group launch templates. See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/locals.tf#L36 for valid values."
  type        = any
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC where the cluster and workers will be deployed. Must be specified if create_eks is true."
  type        = string
  default     = ""
}

variable "use_managed_node_group" {
  description = <<EOT
  Whether or not to use Managed node groups instead of Self-managed nodes for the cluster.
  https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
  https://docs.aws.amazon.com/eks/latest/userguide/worker.html
  EOT
  type        = bool
  default     = false
}

variable "enable_cni_network_policy" {
  description = "Boolen to enable network policy on the cluster. The aws cni plugin requires a min k8s version of 1.25 to enable this."
  type        = bool
  default     = false
}

variable "cluster_enabled_log_types" {
  description = "The list of log types to enable for the cluster. By default, all log types are enabled."
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "cluster_log_retention_in_days" {
  description = "Number of days to retain log events. Default retention - 90 days."
  type        = number
  default     = 90
}
