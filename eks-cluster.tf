provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  }
}

#Permissions based off this guide: https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html
resource "aws_iam_policy" "node_ecr_policy" {
  count = var.allow_ecr_pull ? 1 : 0

  name = "eks_node_ecr_policy_${var.resource_name_suffix}"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
    ]
  })

  tags = var.tags
}

locals {
  managed_node_groups_launch_templates = {
    rime-worker-group = merge({
      name_prefix = "rime-worker-group"

      # required for most customizations to apply
      create_launch_template = true

      capacity_type    = "ON_DEMAND"
      instance_types   = var.server_worker_group_instance_types
      min_capacity     = var.server_worker_group_min_size
      desired_capacity = var.server_worker_group_desired_size
      max_capacity     = var.server_worker_group_max_size
      disk_encrypted   = true
      key_name         = var.node_ssh_key

      metadata_http_endpoint               = "enabled"
      metadata_http_tokens                 = "required"
      metadata_http_put_response_hop_limit = 2
      # Autoscaling applies automatically (no need for explicit tag)
      # https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
    }, var.server_node_groups_overrides),
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
      key_name         = var.node_ssh_key

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
  self_managed_groups_launch_templates = [
    merge({
      name                                     = "rime-worker-group"
      instance_type                            = var.server_worker_group_instance_types[0]
      override_instance_types                  = slice(var.server_worker_group_instance_types, 1, length(var.server_worker_group_instance_types))
      asg_min_size                             = var.server_worker_group_min_size
      asg_desired_capacity                     = var.server_worker_group_desired_size
      asg_max_size                             = var.server_worker_group_max_size
      root_encrypted                           = true
      on_demand_base_capacity                  = "100"
      on_demand_percentage_above_base_capacity = "100"
      key_name                                 = var.node_ssh_key

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
        }
      ]
    }, var.server_worker_groups_overrides),
    merge({
      name                    = "rime-worker-group-model-testing"
      instance_type           = var.model_testing_worker_group_instance_types[0]
      override_instance_types = slice(var.model_testing_worker_group_instance_types, 1, length(var.model_testing_worker_group_instance_types))
      asg_min_size            = var.model_testing_worker_group_min_size
      asg_desired_capacity    = var.model_testing_worker_group_desired_size
      asg_max_size            = var.model_testing_worker_group_max_size
      root_encrypted          = true
      key_name                = var.node_ssh_key

      metadata_http_endpoint               = "enabled"
      metadata_http_tokens                 = "required"
      metadata_http_put_response_hop_limit = 2
      # Mixed Instance Policy Configurations. May need to tune. Currently we either use all spot or all on-demand.
      # Mixed Instance Policy docs: https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_MixedInstancesPolicy.html
      on_demand_base_capacity                  = "0"
      on_demand_percentage_above_base_capacity = var.model_testing_worker_group_use_spot ? "0" : "100"
      spot_allocation_strategy                 = "lowest-price"

      kubelet_extra_args = "--node-labels=node.kubernetes.io/lifecycle=${var.model_testing_worker_group_use_spot ? "spot" : "normal"},dedicated=model-testing --register-with-taints=dedicated=model-testing:NoSchedule"

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
  ]
}

# Provisions an EKS cluster for RIME to be deployed onto.
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  // TODO(blaine): We have to peg our module because version 18.0.0 removed many inputs;
  // investigate how to migrate to 18.0.0 so that we're not using old modules.
  version = "17.24.0"

  count = var.create_eks ? 1 : 0

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
  node_groups                   = { for k, v in local.managed_node_groups_launch_templates : k => v if var.use_managed_node_group }
  worker_groups_launch_template = [for v in local.self_managed_groups_launch_templates : v if !var.use_managed_node_group]

  workers_additional_policies = var.allow_ecr_pull ? concat(var.eks_cluster_node_iam_policies, [aws_iam_policy.node_ecr_policy[0].arn]) : var.eks_cluster_node_iam_policies

  map_roles        = var.map_roles
  map_users        = var.map_users
  write_kubeconfig = false
}

data "aws_eks_cluster" "cluster" {
  name = var.create_eks ? module.eks[0].cluster_id : var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.create_eks ? module.eks[0].cluster_id : var.cluster_name
}

resource "kubernetes_namespace" "auto" {
  // Create for each non-default namespaces.
  for_each = { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace if k8s_namespace.namespace != "default" }

  metadata {
    name = each.key
    labels = {
      name = each.key
    }
  }

  depends_on = [
    module.eks
  ]
}

resource "kubernetes_secret" "docker-secrets" {
  for_each = { for k8s_namespace in concat(var.k8s_namespaces, [{
    namespace = "kube-system"
    primary   = false
  }]) : k8s_namespace.namespace => k8s_namespace }

  metadata {
    name      = var.rime_docker_secret_name
    namespace = each.key
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        for creds in local.json_secrets["docker-logins"] : creds["docker-server"] => merge(
          { for k, v in creds : k => v if v != null },
          { auth = base64encode("${creds["docker-username"]}:${creds["docker-password"]}") },
        )
      }
    })
  }
  depends_on = [kubernetes_namespace.auto]
  type       = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "docker-secrets-extras" {
  metadata {
    name      = var.rime_docker_secret_name
    namespace = "rime-extras"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        for creds in local.json_secrets["docker-logins"] : creds["docker-server"] => merge(
          { for k, v in creds : k => v if v != null },
          { auth = base64encode("${creds["docker-username"]}:${creds["docker-password"]}") },
        )
      }
    })
  }
  depends_on = [module.rime_extras_helm_release]
  type       = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "notifications-secrets" {
  // Only create if notifications secrets are configured
  for_each = lookup(local.json_secrets, "smtp_email", "") != "" ? { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace } : {}

  metadata {
    name      = "rime-notifications-secret"
    namespace = each.key
  }

  data = {
    smtp_email    = local.json_secrets["smtp_email"]
    smtp_password = local.json_secrets["smtp_password"]
    smtp_server   = local.json_secrets["smtp_server"]
    smtp_port     = local.json_secrets["smtp_port"]
  }
  depends_on = [kubernetes_namespace.auto]
}

resource "kubernetes_secret" "admin-secrets" {
  // Only create if admin user is configured
  for_each = lookup(local.json_secrets, "admin_username", "") != "" ? { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace } : {}

  metadata {
    name      = "rime-admin-secret"
    namespace = each.key
  }

  data = {
    admin-username = local.json_secrets["admin_username"]
    admin-password = local.json_secrets["admin_password"]
  }
  depends_on = [kubernetes_namespace.auto]
}

resource "kubernetes_secret" "oidc-secrets" {
  // Only create if oidc secrets are configured
  for_each = lookup(local.json_secrets, "oauth_well_known_url", "") != "" ? { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace } : {}

  metadata {
    name      = "rime-oidc-secret"
    namespace = each.key
  }

  // We only use oauth for oidc, hence why we call it oidc secrets
  data = {
    client_id      = local.json_secrets["oauth_client_id"]
    client_secret  = local.json_secrets["oauth_client_secret"]
    well_known_url = local.json_secrets["oauth_well_known_url"]
  }
  depends_on = [kubernetes_namespace.auto]
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

module "iam_assumable_role_with_oidc_for_ebs_controller" {
  count   = var.cluster_version == "1.23" ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role = true

  role_name        = "rime_ebs_${var.cluster_name}" # must be <= 64
  role_description = "Role to provision block storage for rime cluster."

  provider_url = var.create_eks ? replace(module.eks[0].cluster_oidc_issuer_url, "https://", "") : ""

  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]

  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:ebs-csi-controller-sa",
  ]

  tags = var.tags
}

resource "time_sleep" "wait_3_minutes" {
  count = var.create_eks ? 1 : 0
  depends_on = [
    module.eks
  ]
  create_duration = "3m"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count             = var.cluster_version == "1.23" ? 1 : 0
  cluster_name      = var.create_eks ? module.eks[0].cluster_id : ""
  addon_name        = "aws-ebs-csi-driver"
  resolve_conflicts = "OVERWRITE"
  depends_on = [
    time_sleep.wait_3_minutes
  ]
  service_account_role_arn = var.cluster_version == "1.23" ? module.iam_assumable_role_with_oidc_for_ebs_controller[0].this_iam_role_arn : ""
}
