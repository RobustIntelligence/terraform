locals {
  managed_node_worker_group_launch_template_per_subnet = merge({
    name_prefix = "ri-firewall-worker-group"

    # required for most customizations to apply
    create_launch_template = true

    capacity_type    = "ON_DEMAND"
    instance_types   = var.server_worker_group_instance_types
    min_capacity     = ceil(var.server_worker_group_min_size / length(var.private_subnet_ids))
    desired_capacity = ceil(var.server_worker_group_desired_size / length(var.private_subnet_ids))
    max_capacity     = ceil(var.server_worker_group_max_size / length(var.private_subnet_ids))
    disk_encrypted   = true


    metadata_http_endpoint               = "enabled"
    metadata_http_tokens                 = "required"
    metadata_http_put_response_hop_limit = 2
    # Autoscaling applies automatically (no need for explicit tag)
    # https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
  }, var.server_node_groups_overrides)

  managed_node_worker_group_launch_templates = {
    for subnet in var.private_subnet_ids :
    format("ri-firewall-worker-group-%s", subnet) => merge(local.managed_node_worker_group_launch_template_per_subnet, { subnets = [subnet] })
  }

  # cluster autoscaler will take care of changing desired capacity as needed
  self_managed_worker_group_launch_template_per_subnet = merge({
    name                                     = "ri-firewall-worker-group"
    instance_type                            = var.server_worker_group_instance_types[0]
    override_instance_types                  = slice(var.server_worker_group_instance_types, 1, length(var.server_worker_group_instance_types))
    asg_min_size                             = ceil(var.server_worker_group_min_size / length(var.private_subnet_ids))
    asg_desired_capacity                     = ceil(var.server_worker_group_desired_size / length(var.private_subnet_ids))
    asg_max_size                             = ceil(var.server_worker_group_max_size / length(var.private_subnet_ids))
    root_encrypted                           = true
    on_demand_base_capacity                  = "100"
    on_demand_percentage_above_base_capacity = "100"
    metadata_http_endpoint                   = "enabled"
    metadata_http_tokens                     = "required"
    metadata_http_put_response_hop_limit     = 2

    tags = [
      {
        key                 = "k8s.io/cluster-autoscaler/enabled"
        value               = "TRUE",
        propagate_at_launch = true
      },
      {
        key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
        value               = "owned",
        propagate_at_launch = true
      }
    ]
  }, var.server_worker_groups_overrides)

  self_managed_worker_group_launch_templates = [
    for subnet in var.private_subnet_ids :
    merge(local.self_managed_worker_group_launch_template_per_subnet, { subnets = [subnet] })
  ]
}

resource "aws_kms_alias" "eks_key_alias" {
  name          = "alias/eks-${var.cluster_name}-secret-encryption"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_kms_key" "eks" {
  description             = "EKS cluster ${var.cluster_name} key"
  deletion_window_in_days = 30
  enable_key_rotation     = false
}

# Provisions an EKS cluster for RI Firewall to be deployed onto.
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  // TODO(blaine): We have to peg our module because version 18.0.0 removed many inputs;
  // investigate how to migrate to 18.0.0 so that we're not using old modules.
  version = "17.24.0"

  cluster_endpoint_private_access      = var.private_cluster_endpoint_enabled
  cluster_endpoint_public_access       = var.public_cluster_endpoint_enabled
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnets         = var.private_subnet_ids

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  tags = var.tags

  # Enable IAM roles for service accounts so we can assign IAM roles to
  # k8s service accounts for fine-grained access control. This is required for RIME to function.
  enable_irsa = true

  vpc_id = var.vpc_id

  # Only one of the below will apply based on var.use_managed_node_group
  # node_groups -> Managed Node Groups
  # worker_groups_launch_template -> Self-managed Node Groups
  # This creates one worker node group per subnet in var.private_subnet_ids by appending the default
  # template with an additional "subnets" field. We don't want to restrict subnet for the model testing
  # node group, so we don't append the "subnets" field to that node group.
  node_groups = { for k, v in local.managed_node_worker_group_launch_templates : k => v if var.use_managed_node_group }

  # This creates one worker group launch template per subnet in var.private_subnet_ids by appending the default
  # template with an additional "subnets" field. We don't want to restrict subnet for the model testing
  # node group, so we don't append the "subnets" field to that node group.
  worker_groups_launch_template = [for v in local.self_managed_worker_group_launch_templates : v if !var.use_managed_node_group]

  workers_additional_policies = var.eks_cluster_node_iam_policies

  map_roles        = var.map_roles
  map_users        = var.map_users
  write_kubeconfig = false
}

resource "aws_ec2_tag" "vpc_tags" {
  resource_id = var.vpc_id
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnet_cluster_tag" {
  for_each = toset(var.private_subnet_ids)

  resource_id = each.key
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_elb_tag" {
  for_each = toset(var.private_subnet_ids)

  resource_id = each.key
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}


resource "aws_ec2_tag" "public_subnet_cluster_tag" {
  for_each = toset(var.public_subnet_ids)

  resource_id = each.key
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_elb_tag" {
  for_each = toset(var.public_subnet_ids)

  resource_id = each.key
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}
