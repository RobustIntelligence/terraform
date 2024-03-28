data "aws_partition" "current" {}

locals {
  managed_node_worker_group_launch_template_per_subnet = merge({
    name_prefix = "rime-worker-group"

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
    format("rime-worker-group-%s", subnet) => merge(local.managed_node_worker_group_launch_template_per_subnet, { subnets = [subnet] })
  }

  managed_node_worker_group_model_testing_launch_template = {
    rime-worker-group-model-testing = merge({
      name_prefix = "rime-worker-group-model-testing"

      # required for most customizations to apply
      create_launch_template = true

      capacity_type = var.model_testing_worker_group_use_spot ? "SPOT" : "ON_DEMAND"

      # allowing list specification instead of fixing to first element
      instance_types   = var.model_testing_worker_group_instance_types
      min_capacity     = var.model_testing_worker_group_min_size
      desired_capacity = var.model_testing_worker_group_desired_size
      max_capacity     = var.model_testing_worker_group_max_size
      disk_encrypted   = true

      metadata_http_endpoint               = "enabled"
      metadata_http_tokens                 = "required"
      metadata_http_put_response_hop_limit = 2

      kubelet_extra_args = "--node-labels=node.kubernetes.io/lifecycle=${var.model_testing_worker_group_use_spot ? "spot" : "normal"},dedicated=model-testing --register-with-taints=dedicated=model-testing:NoSchedule"

      # cannot further specify propagate_at_launch lke with self-managed
      additional_tags = {
        "k8s.io/cluster-autoscaler/node-template/label/dedicated" = "model-testing"
      }
      taints = [
        {
          key    = "dedicated"
          value  = "model-testing"
          effect = "NO_SCHEDULE"
        }
      ]

      # Autoscaling applies automatically (no need for explicit tag)
      # https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
    }, var.model_testing_node_groups_overrides)
  }

  # cluster autoscaler will take care of changing desired capacity as needed
  self_managed_worker_group_launch_template_per_subnet = merge({
    name                                     = "rime-worker-group"
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

  self_managed_worker_group_model_testing_launch_template = merge({
    name                    = "rime-worker-group-model-testing"
    instance_type           = var.model_testing_worker_group_instance_types[0]
    override_instance_types = slice(var.model_testing_worker_group_instance_types, 1, length(var.model_testing_worker_group_instance_types))
    asg_min_size            = var.model_testing_worker_group_min_size
    asg_desired_capacity    = var.model_testing_worker_group_desired_size
    asg_max_size            = var.model_testing_worker_group_max_size
    root_encrypted          = true
    # Mixed Instance Policy Configurations. May need to tune. Currently we either use all spot or all on-demand.
    # Mixed Instance Policy docs: https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_MixedInstancesPolicy.html
    on_demand_base_capacity                  = "0"
    on_demand_percentage_above_base_capacity = var.model_testing_worker_group_use_spot ? "0" : "100"
    spot_allocation_strategy                 = "lowest-price"
    kubelet_extra_args                       = "--node-labels=node.kubernetes.io/lifecycle=${var.model_testing_worker_group_use_spot ? "spot" : "normal"},dedicated=model-testing --register-with-taints=dedicated=model-testing:NoSchedule"

    metadata_http_endpoint               = "enabled"
    metadata_http_tokens                 = "required"
    metadata_http_put_response_hop_limit = 2

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
      },
      {
        key                 = "k8s.io/cluster-autoscaler/node-template/label/dedicated"
        value               = "model-testing",
        propagate_at_launch = true
      }
    ]
  }, var.model_testing_worker_groups_overrides)

  self_managed_worker_group_model_testing_large_instances = merge({
    name                    = "rime-worker-group-model-testing-large-instances"
    instance_type           = var.model_testing_worker_group_large_instance_types[0]
    override_instance_types = slice(var.model_testing_worker_group_large_instance_types, 1, length(var.model_testing_worker_group_large_instance_types))
    asg_min_size            = var.model_testing_worker_group_large_min_size
    asg_desired_capacity    = var.model_testing_worker_group_large_desired_size
    asg_max_size            = var.model_testing_worker_group_large_max_size
    root_encrypted          = true
    # Mixed Instance Policy Configurations. May need to tune. Currently we either use all spot or all on-demand.
    # Mixed Instance Policy docs: https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_MixedInstancesPolicy.html
    on_demand_base_capacity                  = "0"
    on_demand_percentage_above_base_capacity = var.model_testing_worker_group_use_spot ? "0" : "100"
    spot_allocation_strategy                 = "lowest-price"
    kubelet_extra_args                       = "--node-labels=node.kubernetes.io/lifecycle=${var.model_testing_worker_group_use_spot ? "spot" : "normal"},dedicated=model-testing --register-with-taints=dedicated=model-testing:NoSchedule"

    metadata_http_endpoint               = "enabled"
    metadata_http_tokens                 = "required"
    metadata_http_put_response_hop_limit = 2

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
      },
      {
        key                 = "k8s.io/cluster-autoscaler/node-template/label/dedicated"
        value               = "model-testing",
        propagate_at_launch = true
      }
    ]
  }, var.model_testing_worker_groups_large_overrides)

  # Used as a unique identifier for global resources
  vpc_id_hashed = sha256(var.vpc_id)
}

# Provisions an EKS cluster for RIME to be deployed onto.
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  // TODO(blaine): We have to peg our module because version 18.0.0 removed many inputs;
  // investigate how to migrate to 18.0.0 so that we're not using old modules.
  version = "17.24.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = !var.public_cluster_endpoint
  cluster_endpoint_public_access  = var.public_cluster_endpoint
  subnets                         = var.private_subnet_ids

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
  node_groups = { for k, v in merge(local.managed_node_worker_group_launch_templates, local.managed_node_worker_group_model_testing_launch_template) : k => v if var.use_managed_node_group }

  # This creates one worker group launch template per subnet in var.private_subnet_ids by appending the default
  # template with an additional "subnets" field. We don't want to restrict subnet for the model testing
  # node group, so we don't append the "subnets" field to that node group.
  worker_groups_launch_template = [for v in concat(local.self_managed_worker_group_launch_templates, [local.self_managed_worker_group_model_testing_launch_template, local.self_managed_worker_group_model_testing_large_instances]) : v if !var.use_managed_node_group]

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

#Storage class that allows expansion in case we need to resize db later. Used in mongo helm chart
resource "kubernetes_storage_class" "expandable_storage" {
  metadata {
    name = var.expandable_storage_class_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "kubernetes.io/aws-ebs"
  reclaim_policy      = "Delete"
  parameters = {
    type      = "gp2"
    fstype    = "ext4"
    encrypted = "true"
  }
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

module "iam_assumable_role_with_oidc_for_ebs_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role = true

  role_name        = "rime_ebs_${var.cluster_name}_${substr(local.vpc_id_hashed, 0, 10)}" # must be <= 64
  role_description = "Role to provision block storage for rime cluster."

  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    aws_iam_policy.kms_ebs_access_policy.arn,
  ]

  number_of_role_policy_arns = 2

  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:ebs-csi-controller-sa",
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "kms_ebs_access_policy_document" {
  version = "2012-10-17"

  statement {
    actions = [
      "kms:RevokeGrant",
      "kms:CreateGrant",
      "kms:ListGrants"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "kms_ebs_access_policy" {
  name = "rime_kms_ebs_policy_${var.cluster_name}_${substr(local.vpc_id_hashed, 0, 10)}" # must be <= 128

  policy = data.aws_iam_policy_document.kms_ebs_access_policy_document.json

  tags = var.tags
}

resource "time_sleep" "wait_3_minutes" {
  depends_on = [
    module.eks
  ]
  create_duration = "3m"
}

# Retrieving latest addon version per EKS version
data "aws_eks_addon_version" "ebs_csi_driver_latest" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = data.aws_eks_addon_version.ebs_csi_driver_latest.version
  resolve_conflicts = "OVERWRITE"
  depends_on = [
    time_sleep.wait_3_minutes
  ]
  service_account_role_arn = module.iam_assumable_role_with_oidc_for_ebs_controller.this_iam_role_arn
}

data "aws_eks_addon_version" "vpc_cni_latest" {
  addon_name         = "vpc-cni"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni_addon" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "vpc-cni"
  addon_version     = data.aws_eks_addon_version.vpc_cni_latest.version
  resolve_conflicts = "OVERWRITE"

  configuration_values = jsonencode({
    enableNetworkPolicy = var.enable_cni_network_policy ? "true" : "false"
    podAnnotations = {
      "prometheus.io/scrape" = "true"
    }
  })
}

data "aws_eks_addon_version" "coredns_latest" {
  addon_name         = "coredns"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "coredns_addon" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "coredns"
  addon_version     = data.aws_eks_addon_version.coredns_latest.version
  resolve_conflicts = "OVERWRITE"
}

data "aws_eks_addon_version" "kube_proxy_latest" {
  addon_name         = "kube-proxy"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "kube_proxy_addon" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "kube-proxy"
  addon_version     = data.aws_eks_addon_version.kube_proxy_latest.version
  resolve_conflicts = "OVERWRITE"
}

// Allows EKS worker nodes to access cloudwatch metrics, which is required for observability.
resource "aws_iam_role_policy" "cloudwatch_metrics_policy" {
  name = "cloudwatch-metrics-policy"
  role = module.eks.worker_iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "tag:GetResources"
        ],
        "Resource" : "*"
      }
    ]
  })
}
