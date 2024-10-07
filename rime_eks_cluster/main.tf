data "aws_partition" "current" {}

locals {
  # Following block used to migrate from v17 to v18 of the terraform-aws-eks module, see: https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1744#issuecomment-1008529086
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks.cluster_id
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks.cluster_id
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })

  current_auth_configmap = yamldecode(module.eks.aws_auth_configmap_yaml)
  updated_auth_configmap_data = {
    data = {
      mapRoles = yamlencode(
        distinct(concat(
          yamldecode(local.current_auth_configmap.data.mapRoles), var.map_roles, )
      ))
      mapUsers = yamlencode(var.map_users)
    }
  }

  managed_node_worker_group_launch_template_per_subnet = merge({
    iam_role_use_name_prefix = false
    # required for most customizations to apply
    create_launch_template = true

    capacity_type  = "ON_DEMAND"
    instance_types = var.server_worker_group_instance_types
    min_size       = ceil(var.server_worker_group_min_size / length(var.private_subnet_ids))
    desired_size   = ceil(var.server_worker_group_desired_size / length(var.private_subnet_ids))
    max_size       = ceil(var.server_worker_group_max_size / length(var.private_subnet_ids))

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = var.server_worker_group_root_volume_size
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
        }
      }
    }

    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
    }
  }, var.server_node_groups_overrides)
  managed_node_worker_group_launch_templates = {
    for subnet in var.private_subnet_ids :
    format("%s", subnet) => merge(local.managed_node_worker_group_launch_template_per_subnet, { subnet_ids = [subnet] })
  }

  managed_node_worker_group_model_testing_launch_template = {
    model-testing = merge({

      # required for most customizations to apply
      create_launch_template = true

      capacity_type = var.model_testing_worker_group_use_spot ? "SPOT" : "ON_DEMAND"

      # allowing list specification instead of fixing to first element
      instance_types = var.model_testing_worker_group_instance_types
      min_size       = var.model_testing_worker_group_min_size
      desired_size   = var.model_testing_worker_group_desired_size
      max_size       = var.model_testing_worker_group_max_size

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.model_testing_worker_group_root_volume_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      additional_tags = {
        "k8s.io/cluster-autoscaler/node-template/label/dedicated" = "model-testing"
      }
      labels = {
        "dedicated" = "model-testing"
      }
      taints = [
        {
          key    = "dedicated"
          value  = "model-testing"
          effect = "NO_SCHEDULE"
        }
      ]
    }, var.model_testing_node_groups_overrides)
  }

  managed_node_worker_group_model_testing_large_launch_template = {
    model-testing-large = merge({
      # required for most customizations to apply
      create_launch_template = true

      capacity_type = var.model_testing_worker_group_use_spot ? "SPOT" : "ON_DEMAND"

      # allowing list specification instead of fixing to first element
      instance_types = var.model_testing_worker_group_large_instance_types
      min_size       = var.model_testing_worker_group_large_min_size
      desired_size   = var.model_testing_worker_group_large_desired_size
      max_size       = var.model_testing_worker_group_large_max_size

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.model_testing_worker_group_large_root_volume_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      additional_tags = {
        "k8s.io/cluster-autoscaler/node-template/label/dedicated" = "model-testing"
      }
      labels = {
        "dedicated" = "model-testing"
      }
      taints = [
        {
          key    = "dedicated"
          value  = "model-testing"
          effect = "NO_SCHEDULE"
        }
      ]
    }, var.model_testing_worker_groups_large_overrides)
  }
  # Used as a unique identifier for global resources
  vpc_id_hashed = sha256(var.vpc_id)
}

resource "aws_iam_policy" "ri_product_usage_data_bucket_access_policy" {
  name        = "ri_product_usage_data_bucket_policy_${var.cluster_name}"
  description = "Policy to allow writing to the product usage data bucket"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : [
          "arn:aws:s3:::ri-product-usage-data",
          "arn:aws:s3:::ri-product-usage-data/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ri_prometheus_read_role_access_policy" {
  name        = "ri_prometheus_read_role_access_policy_${var.cluster_name}"
  description = "Policy to allow assuming the prometheus_read_role"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AssumePrometheusRole",
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : "arn:aws:iam::746181457053:role/prometheus_read_role"
      }
    ]
  })
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

# Provisions an EKS cluster for RIME to be deployed onto.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  cluster_endpoint_private_access      = var.private_cluster_endpoint_enabled
  cluster_endpoint_public_access       = var.public_cluster_endpoint_enabled
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  subnet_ids                           = var.private_subnet_ids

  prefix_separator                   = ""
  iam_role_name                      = var.cluster_name
  cluster_security_group_name        = var.cluster_name
  cluster_security_group_description = "EKS cluster security group."

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

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

  # eks_managed_node_groups -> Managed Node Groups
  # This creates one worker node group per subnet in var.private_subnet_ids by appending the default
  # template with an additional "subnets" field. We don't want to restrict subnet for the model testing
  # node group, so we don't append the "subnets" field to that node group.
  eks_managed_node_groups = { for k, v in merge(local.managed_node_worker_group_launch_templates, local.managed_node_worker_group_model_testing_launch_template, local.managed_node_worker_group_model_testing_large_launch_template) : k => v }

  eks_managed_node_group_defaults = {
    iam_role_additional_policies = concat(var.eks_cluster_node_iam_policies, [aws_iam_policy.ri_product_usage_data_bucket_access_policy.arn, aws_iam_policy.ri_prometheus_read_role_access_policy.arn])
  }

  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}

resource "null_resource" "patch_aws_auth_configmap" {
  triggers = {
    cmd_patch = "kubectl patch configmap/aws-auth -n kube-system --type merge -p '${chomp(jsonencode(local.updated_auth_configmap_data))}' --kubeconfig <(echo $KUBECONFIG | base64 --decode)"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = self.triggers.cmd_patch
    environment = {
      KUBECONFIG = base64encode(local.kubeconfig)
    }
  }
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
  for_each = module.eks.eks_managed_node_groups
  name     = "cloudwatch-metrics-policy"
  role     = each.value.iam_role_name

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

# Tags for the ASG to support cluster-autoscaler scale up from 0
locals {
  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  cluster_autoscaler_label_tags = merge([
    for name, group in module.eks.eks_managed_node_groups : {
      for label_name, label_value in coalesce(group.node_group_labels, {}) : "${name}|label|${label_name}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/label/${label_name}",
        value             = label_value,
      }
    }
  ]...)

  cluster_autoscaler_taint_tags = merge([
    for name, group in module.eks.eks_managed_node_groups : {
      for taint in coalesce(group.node_group_taints, []) : "${name}|taint|${taint.key}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}"
        value             = "${taint.value}:${local.taint_effects[taint.effect]}"
      }
    }
  ]...)

  cluster_autoscaler_asg_tags = merge(local.cluster_autoscaler_label_tags, local.cluster_autoscaler_taint_tags)
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_label_tags" {
  for_each = local.cluster_autoscaler_asg_tags

  autoscaling_group_name = each.value.autoscaling_group

  tag {
    key   = each.value.key
    value = each.value.value

    propagate_at_launch = false
  }
}
