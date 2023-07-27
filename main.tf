data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#We expect your aws account to have an aws secrets manager file with
data "aws_secretsmanager_secret_version" "rime-secrets" {
  secret_id = var.rime_secrets_name
}

locals {
  stripped_oidc_provider_url = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  json_secrets               = jsondecode(data.aws_secretsmanager_secret_version.rime-secrets.secret_string)
  create_route53             = lookup(var.dns_config, "create_route53", true)
  acm_domain                 = lookup(var.dns_config, "acm_domain", var.dns_config["rime_domain"])
  rime_domain                = var.dns_config["rime_domain"]
  all_k8s_namespaces         = { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace }
  create_lb_security_group   = length(var.lb_security_group_rules) > 0
  tags                       = merge({ ManagedBy = "Terraform" }, var.tags)

  // Settings for the ECR registry
  ecr_registry_arn     = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
  ecr_account_part_map = regex("^arn:aws:ecr:(?P<region>[\\w-]+):(?P<account_id>[0-9]{12})$", local.ecr_registry_arn)

  // If no agent configs supplied, create agent configurations for same namespace as control planes (k8s_namespaces var)
  rime_agent_configs = (length(var.rime_agent_configs) == 0) ? {
    for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace =>
    {
      namespace               = k8s_namespace.namespace
      custom_values_file_path = ""
      cp_namespace            = k8s_namespace.namespace
      cp_release_name         = k8s_namespace.primary ? "rime" : "rime-${k8s_namespace.namespace}"
    }
  } : { for config in var.rime_agent_configs : config.namespace => config }
  // The name of the configmap the agent will use to load env vars into model test job container.
  // This name must be in sync between the controlplane (to use in job template) and agent (creates this configmap)
  model_test_job_config_map = "rime-agent-model-testing-conf"

  // Create a repository name that is resource specific.
  cluster_prefix_for_image_repo = join("/", [
    var.image_registry_config.repository_prefix,
    var.resource_name_suffix,
  ])
}

module "ecr_iam" {
  // Module's meta-arguments.
  // Note: if count is used here as a toggle for creating the module or not.
  source = "./modules/ecr_iam"
  count  = var.image_registry_config.enable ? 1 : 0

  // Module's arguments.
  // Note: the repository prefix for ECR is restricted to the path that is
  // specific to this cluster since this deployment only *owns* images at the
  // cluster level.
  ecr_registry_arn     = local.ecr_registry_arn
  k8s_namespaces       = var.k8s_namespaces
  oidc_provider_url    = local.stripped_oidc_provider_url
  repository_prefix    = local.cluster_prefix_for_image_repo
  resource_name_suffix = var.resource_name_suffix
  tags                 = local.tags
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

  depends_on  = [module.route53]
  domain      = local.acm_domain
  statuses    = ["PENDING_VALIDATION", "ISSUED"]
  most_recent = true
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
  source        = "./modules/rime_helm_release"
  release_name  = each.value.primary ? "rime" : "rime-${each.key}"
  for_each      = { for k8s_namespace in var.k8s_namespaces : k8s_namespace.namespace => k8s_namespace }
  name          = each.key
  k8s_namespace = each.key

  acm_cert_arn                = local.rime_domain != "" ? data.aws_acm_certificate.this_zone_acm_certificate[0].arn : ""
  create_managed_helm_release = var.create_managed_helm_release
  docker_registry             = var.docker_registry
  domain                      = each.value.primary ? local.rime_domain : "${each.key}-${local.rime_domain}"
  enable_external_agent       = var.enable_external_agent
  image_registry_config = {
    registry_type                = var.image_registry_config.enable ? "ecr" : null
    allow_external_custom_images = var.image_registry_config.allow_external_custom_images
    ecr_config = var.image_registry_config.enable ? {
      registry_id = local.ecr_account_part_map["account_id"]
      // The repository prefix used by each namespace is given an additional specifier
      // for the namespace to ensure that the image names of each namespace are unique.
      repository_prefix = join("/", [local.cluster_prefix_for_image_repo, each.key])
    } : null
    gar_config             = null
    image_builder_role_arn = var.image_registry_config.enable ? module.ecr_iam[0].ecr_image_builder_role_arn : ""
    repo_manager_role_arn  = var.image_registry_config.enable ? module.ecr_iam[0].ecr_repo_manager_role_arn : ""
  }
  helm_values_output_dir            = var.helm_values_output_dir
  internal_lbs                      = var.internal_lbs
  load_balancer_security_groups_ids = local.create_lb_security_group ? [aws_security_group.internal_load_balancer_security_group[0].id] : []
  mongo_db_size                     = var.mongo_db_size
  override_values_file_path         = var.rime_override_values_file_path
  rime_docker_backend_image         = var.rime_docker_backend_image
  rime_docker_frontend_image        = var.rime_docker_frontend_image
  rime_docker_image_builder_image   = var.rime_docker_image_builder_image
  rime_docker_managed_base_image    = var.rime_docker_managed_base_image
  rime_docker_model_testing_image   = var.rime_docker_model_testing_image
  rime_docker_secret_name           = var.rime_docker_secret_name
  rime_jwt                          = local.json_secrets["rime_jwt"]
  rime_repository                   = var.rime_repository
  rime_version                      = var.rime_version
  use_blob_store                    = var.use_blob_store
  s3_blob_store_role_arn            = var.use_blob_store ? module.s3_blob_store[each.key].s3_blob_store_role_arn : ""
  s3_blob_store_bucket_name         = var.use_blob_store ? module.s3_blob_store[each.key].s3_blob_store_bucket_name : ""
  use_file_upload_service           = var.use_file_upload_service
  user_pilot_flow                   = var.user_pilot_flow
  verbose                           = var.verbose
  ip_allowlist                      = var.ip_allowlist
  enable_api_key_auth               = var.enable_api_key_auth
  enable_additional_mongo_metrics   = var.enable_additional_mongo_metrics
  model_test_job_config_map         = local.model_test_job_config_map
  use_rmq_health                    = var.use_rmq_health
  use_rmq_resource_cleaner          = var.use_rmq_resource_cleaner
  rmq_resource_cleaner_frequency    = var.rmq_resource_cleaner_frequency
  use_rmq_metrics_updater           = var.use_rmq_metrics_updater
  rmq_metrics_updater_frequency     = var.rmq_metrics_updater_frequency
  overwrite_license                 = var.overwrite_license
  create_scheduled_ct               = var.create_scheduled_ct
  // Only use a separate model testing group if we are using an internal agent.
  // In external, we do not want nodeSelectors for jobs that are going to be run on a cluster we do not control.
  // TODO(andrew): RIME-10083 make agents configure node selectors instead of defining in the control plane
  separate_model_testing_group = var.include_internal_agent
  datadog_tag_pod_annotation   = var.datadog_tag_pod_annotation

  tags = local.tags

  depends_on = [kubernetes_namespace.auto, module.rime_kube_system_helm_release]
}

module "rime_kube_system_helm_release" {
  source = "./modules/rime_kube_system_helm_release"

  cluster_name                = var.cluster_name
  create_managed_helm_release = var.create_managed_helm_release
  domains                     = [for k8s_namespace in var.k8s_namespaces : k8s_namespace.primary ? local.rime_domain : "${k8s_namespace.namespace}-${local.rime_domain}"]
  docker_registry             = var.docker_registry
  helm_values_output_dir      = var.helm_values_output_dir
  install_cluster_autoscaler  = var.install_cluster_autoscaler
  install_external_dns        = var.install_external_dns
  oidc_provider_url           = local.stripped_oidc_provider_url
  resource_name_suffix        = var.resource_name_suffix
  rime_docker_secret_name     = var.rime_docker_secret_name
  rime_repository             = var.rime_repository
  rime_version                = var.rime_version

  tags = local.tags

  depends_on = [module.eks]
}

module "rime_extras_helm_release" {
  source = "./modules/rime_extras_helm_release"

  create_managed_helm_release = var.create_managed_helm_release
  docker_registry             = var.docker_registry
  helm_values_output_dir      = var.helm_values_output_dir
  install_datadog             = var.install_datadog
  install_velero              = var.install_velero
  velero_backup_namespaces    = keys(local.all_k8s_namespaces)
  velero_backup_ttl           = var.velero_backup_ttl
  velero_backup_schedule      = var.velero_backup_schedule
  datadog_api_key             = lookup(local.json_secrets, "datadog-api-key", "")
  rime_docker_secret_name     = var.rime_docker_secret_name
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
  k8s_namespace        = each.value
  oidc_provider_url    = local.stripped_oidc_provider_url
  resource_name_suffix = var.resource_name_suffix
  tags                 = var.tags
}


module "rime_agent" {
  source = "./modules/rime_agent"
  // If include_internal_agent is false, ignore agent configs and do not call rime_agent module.
  for_each = var.include_internal_agent ? { for config in local.rime_agent_configs : config.namespace => config } : {}

  // establishes dependence on eks module, which may have created the cluster.
  cluster_name            = data.aws_eks_cluster.cluster.name
  custom_values_file_path = each.value.custom_values_file_path
  k8s_namespace           = each.key
  resource_name_suffix    = var.resource_name_suffix
  rime_repository         = var.rime_repository
  rime_version            = var.rime_version
  rime_docker_agent_image = var.rime_docker_agent_image
  docker_registry         = var.docker_registry

  // have to authorize blob store buckets created by the CP namespace
  s3_authorized_bucket_path_arns = concat(var.s3_authorized_bucket_path_arns, module.s3_blob_store[each.value.cp_namespace].s3_blob_store_bucket_path_arns)
  create_managed_helm_release    = var.create_managed_helm_release
  helm_values_output_dir         = "${var.helm_values_output_dir}/agent"
  rime_secrets_name              = var.rime_secrets_name

  // only create namespaces if we are deploying into a separate namespace
  create_k8s_namespace = each.key != each.value.cp_namespace

  firewall_server_addr      = "${each.value.cp_release_name != "" ? each.value.cp_release_name : "rime"}-firewall-server.${each.value.cp_namespace}:5002"
  data_collector_addr       = "${each.value.cp_release_name != "" ? each.value.cp_release_name : "rime"}-data-collector-server.${each.value.cp_namespace}:5015"
  grpc_web_server_addr      = "${each.value.cp_release_name != "" ? each.value.cp_release_name : "rime"}-grpc-web-server.${each.value.cp_namespace}:5011"
  job_manager_server_addr   = "${each.value.cp_release_name != "" ? each.value.cp_release_name : "rime"}-upload-server.${each.value.cp_namespace}:5000"
  agent_manager_server_addr = "${each.value.cp_release_name != "" ? each.value.cp_release_name : "rime"}-agent-manager-server.${each.value.cp_namespace}:5016"
  upload_server_addr        = "${each.value.cp_release_name != "" ? each.value.cp_release_name : "rime"}-upload-server.${each.value.cp_namespace}:5000"
  request_queue_proxy_addr  = "${each.value.cp_release_name != "" ? each.value.cp_release_name : "rime"}-request-queue-proxy.${each.value.cp_namespace}:5014"

  model_test_job_config_map = local.model_test_job_config_map
  log_archival_config = {
    enable      = var.enable_log_archival && var.use_blob_store
    bucket_name = module.s3_blob_store[each.value.cp_namespace].s3_blob_store_bucket_name
  }
  oidc_provider_url          = local.stripped_oidc_provider_url
  datadog_tag_pod_annotation = var.datadog_tag_pod_annotation

  depends_on = [
    module.eks,
    module.rime_helm_release,
  ]
}
