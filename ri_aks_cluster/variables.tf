variable "cluster_name" {
  description = "Name of aks cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the AKS cluster."
  type        = string
  default     = "1.25"
}

variable "location" {
  description = "Location of region where aks cluster will be created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of resource group where aks cluster will be created."
  type        = string
}

variable "model_testing_node_pool_vm_size" {
  description = "VM size for the model testing worker group."
  type        = string
  default     = "Standard_D4s_v3"
}

variable "model_testing_node_pool_min_size" {
  description = "Minimum size of the model testing worker group. Must be >= 0"
  type        = number
  default     = 0

  validation {
    condition     = var.model_testing_node_pool_min_size >= 0
    error_message = "Model testing worker group min size must be greater than or equal to 0."
  }
}

variable "model_testing_node_pool_desired_size" {
  description = <<EOT
  Desired size of the model testing worker group.
  If var.use_managed_node_group is true, must be >= 1; otherwise, must be >= 0.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.model_testing_node_pool_desired_size >= 0
    error_message = <<EOT
    Model testing worker group desired size must be greater than or equal to 0.
    If var.use_managed_node_group is true, must be >= 1.
    EOT
  }
}

variable "model_testing_node_pool_max_size" {
  description = "Maximum size of the model testing worker group. Must be >= min size. For best performance we recommend >= 10 nodes as the max size."
  type        = number
  default     = 10
}

variable "model_testing_node_pool_overrides" {
  description = "A dictionary that specifies overrides for the model testing worker group launch templates. See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/locals.tf#L36 for valid values."
  type        = any
  default     = {}
}

variable "model_testing_node_pool_use_spot" {
  description = "Use spot instances for model testing worker group."
  type        = bool
  default     = true
}

variable "service_cidr" {
  description = "(Optional) The Network Range used by the Kubernetes service. Changing this forces a new resource to be created."
  type        = string
  default     = null
}


variable "private_cluster_enabled" {
  description = "Whether or not the cluster should be private."
  type        = bool
  default     = false
}

variable "vnet_subnet_id" {
  description = "(Optional) The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "server_node_pool_vm_size" {
  description = "VM size for the server worker group."
  type        = string
  default     = "Standard_D4s_v3"
}

variable "server_node_pool_min_size" {
  description = "Minimum size of the server worker group. Must be >= 1"
  type        = number
  default     = 4

  validation {
    condition     = var.server_node_pool_min_size >= 1
    error_message = "Server worker group min size must be greater than or equal to 1."
  }
}

variable "server_node_pool_desired_size" {
  description = "Desired size of the server worker group. Must be >= 0"
  type        = number
  default     = 5

  validation {
    condition     = var.server_node_pool_desired_size >= 0
    error_message = "Server worker group desired size must be greater than or equal to 0."
  }
}

variable "server_node_pool_max_size" {
  description = "Maximum size of the server worker group. Must be >= min size. For best performance we recommend >= 10 nodes as the max size."
  type        = number
  default     = 10
}

variable "server_node_pool_overrides" {
  description = "A dictionary that specifies overrides for the server worker group launch templates. See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/locals.tf#L36 for valid values."
  type        = any
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default     = {}
}

variable "workload_identity_enabled" {
  description = "Enable or Disable Workload Identity. Defaults to true."
  type        = bool
  default     = true
}
