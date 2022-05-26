data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#We expect your aws account to have an aws secrets manager file with
data "aws_secretsmanager_secret_version" "rime-secrets" {
  secret_id = var.rime_secrets_name
}

locals {
  stripped_oidc_provider_url = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  json_secrets               = jsondecode(data.aws_secretsmanager_secret_version.rime-secrets.secret_string)
  registries                 = local.json_secrets["docker-logins"]
  create_route53             = lookup(var.dns_config, "create_route53", true)
  acm_domain                 = lookup(var.dns_config, "acm_domain", var.dns_config["rime_domain"])
  rime_domain                = var.dns_config["rime_domain"]
  all_k8s_namespaces         = { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace }
  create_lb_security_group   = length(var.lb_security_group_rules) > 0
  tags                       = merge({ ManagedBy = "Terraform" }, var.tags)

  // Settings for the ECR registry
  ecr_registry_arn     = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
  ecr_account_part_map = regex("^arn:aws:ecr:(?P<region>[\\w-]+):(?P<account_id>[0-9]{12})$", local.ecr_registry_arn)
  // For validating use_file_upload_service dependence on use_blob_store.
  // At this time, terraform do not yet support condition on another variable.
  // https://github.com/hashicorp/terraform/issues/25609.
  validate_file_upload_service = (
    !var.use_blob_store && var.use_file_upload_service
  ) ? tobool("use_blob_store must be true in order to use file upload service") : true
}

module "ecr_iam" {
  // Module's meta-arguments.
  // Note: if count is used here as a toggle for creating the module or not.
  source = "./modules/ecr_iam"
  count  = var.image_registry_config.enable ? 1 : 0

  // Module's arguments.
  ecr_registry_arn     = local.ecr_registry_arn
  k8s_namespaces       = var.k8s_namespaces
  oidc_provider_url    = local.stripped_oidc_provider_url
  repository_prefix    = var.image_registry_config.repository_prefix
  resource_name_suffix = var.resource_name_suffix
  tags                 = local.tags
}

module "s3_iam" {
  source = "./modules/s3_iam"

  for_each      = { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace }
  k8s_namespace = each.value

  oidc_provider_url              = local.stripped_oidc_provider_url
  resource_name_suffix           = var.resource_name_suffix
  s3_authorized_bucket_path_arns = concat(var.s3_authorized_bucket_path_arns, module.s3_blob_store[each.key].s3_blob_store_bucket_path_arns)

  tags = local.tags
}

module "route53" {
  source = "./modules/route53"

  count = local.create_route53 ? 1 : 0

  secondary_domains = [for k8s_namespace in var.k8s_namespaces : "${k8s_namespace.namespace}-${local.rime_domain}" if !k8s_namespace.primary]
  primary_domain    = local.rime_domain
  acm_domain        = local.acm_domain

  tags = local.tags
}

data "aws_acm_certificate" "this_zone_acm_certificate" {
  count = local.rime_domain != "" ? 1 : 0

  depends_on = [module.route53]
  domain     = local.acm_domain
  statuses   = ["PENDING_VALIDATION", "ISSUED"]
}

resource "aws_security_group" "internal_load_balancer_security_group" {
  count = local.create_lb_security_group ? 1 : 0

  name        = "internal_lb_sg_${var.cluster_name}"
  description = "Allow traffic into internal load balancers"
  vpc_id      = var.vpc_id

  tags = local.tags
}

resource "aws_security_group_rule" "internal_load_balancer_security_group_rules" {
  for_each = { for key, sg in var.lb_security_group_rules : key => sg }

  type                     = each.value["type"]
  from_port                = each.value["from_port"]
  to_port                  = each.value["to_port"]
  protocol                 = each.value["protocol"]
  description              = lookup(each.value, "description", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", [])
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", [])
  self                     = lookup(each.value, "self", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", [])
  source_security_group_id = lookup(each.value, "source_security_group_id", null)

  security_group_id = aws_security_group.internal_load_balancer_security_group[0].id
}

module "rime_helm_release" {
  source = "./modules/rime_helm_release"

  for_each      = { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace }
  name          = each.key
  k8s_namespace = each.key

  acm_cert_arn                = local.rime_domain != "" ? data.aws_acm_certificate.this_zone_acm_certificate[0].arn : ""
  admin_api_key               = local.json_secrets["admin_api_key"]
  create_managed_helm_release = var.create_managed_helm_release
  domain                      = each.value.primary ? local.rime_domain : "${each.key}-${local.rime_domain}"
  enable_vouch                = var.enable_vouch
  image_registry_config = {
    enable                       = var.image_registry_config.enable
    allow_external_custom_images = var.image_registry_config.allow_external_custom_images
    registry_id                  = var.image_registry_config.enable ? local.ecr_account_part_map["account_id"] : ""
    image_builder_role_arn       = var.image_registry_config.enable ? module.ecr_iam[0].ecr_image_builder_role_arn : ""
    repo_manager_role_arn        = var.image_registry_config.enable ? module.ecr_iam[0].ecr_repo_manager_role_arn : ""
    repository_prefix            = var.image_registry_config.enable ? var.image_registry_config.repository_prefix : ""
  }
  helm_values_output_dir            = var.helm_values_output_dir
  internal_lbs                      = var.internal_lbs
  load_balancer_security_groups_ids = local.create_lb_security_group ? [aws_security_group.internal_load_balancer_security_group[0].id] : []
  mongo_db_size                     = var.mongo_db_size
  oauth_config = {
    client_id     = local.json_secrets["oauth_client_id"]
    client_secret = local.json_secrets["oauth_client_secret"]
    auth_url      = local.json_secrets["oauth_auth_url"]
    token_url     = local.json_secrets["oauth_token_url"]
    user_info_url = local.json_secrets["oauth_user_info_url"]
  }
  rime_docker_backend_image       = var.rime_docker_backend_image
  rime_docker_frontend_image      = var.rime_docker_frontend_image
  rime_docker_image_builder_image = var.rime_docker_image_builder_image
  rime_docker_model_testing_image = var.rime_docker_model_testing_image
  rime_docker_secret_name         = var.rime_docker_secret_name
  rime_jwt                        = local.json_secrets["rime_jwt"]
  rime_repository                 = var.rime_repository
  rime_version                    = var.rime_version
  s3_reader_role_arn              = module.s3_iam[each.key].s3_reader_role_arn
  use_blob_store                  = var.use_blob_store
  s3_blob_store_role_arn          = var.use_blob_store ? module.s3_blob_store[each.key].s3_blob_store_role_arn : ""
  s3_blob_store_bucket_name       = var.use_blob_store ? module.s3_blob_store[each.key].s3_blob_store_bucket_name : ""
  use_file_upload_service         = var.use_file_upload_service
  user_pilot_flow                 = var.user_pilot_flow
  verbose                         = var.verbose
  vouch_whitelist_domains         = var.vouch_whitelist_domains
  ip_allowlist                    = var.ip_allowlist
  enable_api_key_auth             = var.enable_api_key_auth

  tags = local.tags

  depends_on = [kubernetes_namespace.auto]
}

module "rime_kube_system_helm_release" {
  source = "./modules/rime_kube_system_helm_release"

  cluster_name                = var.cluster_name
  create_managed_helm_release = var.create_managed_helm_release
  domains                     = [for k8s_namespace in var.k8s_namespaces : k8s_namespace.primary ? local.rime_domain : "${k8s_namespace.namespace}-${local.rime_domain}"]
  helm_values_output_dir      = var.helm_values_output_dir
  install_cluster_autoscaler  = var.install_cluster_autoscaler
  install_external_dns        = var.install_external_dns
  oidc_provider_url           = local.stripped_oidc_provider_url
  resource_name_suffix        = var.resource_name_suffix
  rime_repository             = var.rime_repository
  rime_version                = var.rime_version

  tags = local.tags

  depends_on = [module.eks]
}

module "rime_extras_helm_release" {
  source = "./modules/rime_extras_helm_release"

  create_managed_helm_release = var.create_managed_helm_release
  helm_values_output_dir      = var.helm_values_output_dir
  install_datadog             = var.install_datadog
  install_velero              = var.install_velero
  velero_backup_namespaces    = keys(local.all_k8s_namespaces)
  velero_backup_ttl           = var.velero_backup_ttl
  velero_backup_schedule      = var.velero_backup_schedule
  datadog_api_key             = lookup(local.json_secrets, "datadog-api-key", "")
  rime_user                   = local.json_secrets["rime-user"]
  rime_repository             = var.rime_repository
  rime_version                = var.rime_version
  oidc_provider_url           = local.stripped_oidc_provider_url
  resource_name_suffix        = var.resource_name_suffix

  tags = local.tags

  depends_on = [module.eks]
}

module "s3_blob_store" {
  source         = "./modules/s3_blob_store"
  use_blob_store = var.use_blob_store

  for_each             = { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace }
  k8s_namespace        = each.key
  oidc_provider_url    = local.stripped_oidc_provider_url
  resource_name_suffix = var.resource_name_suffix

  tags = var.tags
}
