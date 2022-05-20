locals {
  is_namespace_default          = (var.k8s_namespace == "default")
  output_dir                    = length(var.helm_values_output_dir) == 0 ? "${path.cwd}" : var.helm_values_output_dir
  mongo_storage_class           = local.is_namespace_default ? "mongo-storage" : "mongo-storage-${var.k8s_namespace}"
  tags                          = join(",", [for key, value in var.tags : "${key}=${value}"])
  load_balancer_security_groups = join(",", var.load_balancer_security_groups_ids)
}

resource "random_password" "jwt_secret" {
  length  = 64
  lower   = true
  number  = true
  special = true
  upper   = true
}

#Storage class that allows expansion in case we need to resize db later. Used in mongo helm chart
resource "kubernetes_storage_class" "mongo_storage" {
  metadata {
    name = local.mongo_storage_class
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

# The YAML file created by instantiating `values_tmpl.yaml`.
resource "local_file" "helm_values" {
  content = templatefile("${path.module}/values_tmpl.yaml", {
    acm_cert_arn                  = var.acm_cert_arn
    api_key                       = var.admin_api_key
    docker_backend_image          = var.rime_docker_backend_image
    docker_backend_secret_name    = var.rime_docker_secret_name
    docker_frontend_image         = var.rime_docker_frontend_image
    docker_image_builder_image    = var.rime_docker_image_builder_image
    docker_model_testing_image    = var.rime_docker_model_testing_image
    domain                        = var.domain == "" ? "placeholder" : var.domain
    enable_firewall               = var.enable_firewall
    enable_vouch                  = var.enable_vouch
    image_registry_config         = var.image_registry_config
    jwt_secret                    = random_password.jwt_secret.result
    lb_security_groups            = length(local.load_balancer_security_groups) > 0 ? "service.beta.kubernetes.io/aws-load-balancer-extra-security-groups: \"${local.tags}\"" : ""
    lb_tags                       = length(local.tags) > 0 ? "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: \"${local.tags}\"" : ""
    lb_type                       = var.internal_lbs ? "internal": "internet-facing"
    mongo_db_size                 = var.mongo_db_size
    mongo_storage_class           = local.mongo_storage_class
    namespace                     = var.k8s_namespace
    oauth_client_id               = var.oauth_config.client_id
    oauth_client_secret           = var.oauth_config.client_secret
    oauth_auth_url                = var.oauth_config.auth_url
    oauth_token_url               = var.oauth_config.token_url
    oauth_user_info_url           = var.oauth_config.user_info_url
    pull_policy                   = var.rime_version == "latest" ? "Always" : "IfNotPresent"
    rime_jwt                      = var.rime_jwt
    datadog_frontend_client_token = var.datadog_frontend_client_token
    s3_role_arn                   = var.s3_reader_role_arn
    use_blob_store                = var.use_blob_store
    use_file_upload_service       = var.use_file_upload_service
    s3_blob_store_role_arn        = var.use_blob_store ? var.s3_blob_store_role_arn : ""
    s3_blob_store_bucket_name     = var.use_blob_store ? var.s3_blob_store_bucket_name : ""
    version                       = var.rime_version
    verbose                       = var.verbose
    vouch_whitelist_domains       = var.vouch_whitelist_domains
  })
  filename = format("%s/values_%s.yaml", local.output_dir, var.k8s_namespace)
}

# The release of the RIME Helm chart in a given k8s namespace.
resource "helm_release" "rime" {
  count = var.create_managed_helm_release ? 1 : 0

  # Chart information.
  repository = var.rime_repository
  chart      = "rime"
  version    = var.rime_version

  name              = "rime"
  namespace         = var.k8s_namespace
  create_namespace  = !local.is_namespace_default
  dependency_update = true
  force_update      = false
  lint              = true
  recreate_pods     = false
  wait              = false

  values = [
    local_file.helm_values.content
  ]

  depends_on = [kubernetes_storage_class.mongo_storage]
}
