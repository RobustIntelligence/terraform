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
    acm_cert_arn                    = var.acm_cert_arn
    docker_backend_image            = var.rime_docker_backend_image
    docker_secret_name              = var.rime_docker_secret_name
    docker_registry                 = var.docker_registry
    docker_frontend_image           = var.rime_docker_frontend_image
    docker_image_builder_image      = var.rime_docker_image_builder_image
    docker_managed_base_image       = var.rime_docker_managed_base_image
    docker_model_testing_image      = var.rime_docker_model_testing_image
    domain                          = var.domain == "" ? "placeholder" : var.domain
    image_registry_config           = var.image_registry_config
    jwt_secret                      = random_password.jwt_secret.result
    lb_security_groups              = length(local.load_balancer_security_groups) > 0 ? "service.beta.kubernetes.io/aws-load-balancer-extra-security-groups: \"${local.tags}\"" : ""
    lb_tags                         = length(local.tags) > 0 ? "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: \"${local.tags}\"" : ""
    lb_type                         = var.internal_lbs ? "internal" : "internet-facing"
    mongo_db_size                   = var.mongo_db_size
    mongo_storage_class             = local.mongo_storage_class
    namespace                       = var.k8s_namespace
    pull_policy                     = var.rime_version == "latest" ? "Always" : "IfNotPresent"
    rime_jwt                        = var.rime_jwt
    s3_blob_store_bucket_name       = var.use_blob_store ? var.s3_blob_store_bucket_name : ""
    s3_blob_store_role_arn          = var.use_blob_store ? var.s3_blob_store_role_arn : ""
    use_blob_store                  = var.use_blob_store
    use_file_upload_service         = var.use_file_upload_service
    user_pilot_flow                 = var.user_pilot_flow
    verbose                         = var.verbose
    version                         = var.rime_version
    ip_allowlist                    = var.ip_allowlist
    enable_api_key_auth             = var.enable_api_key_auth
    enable_additional_mongo_metrics = var.enable_additional_mongo_metrics
    model_test_job_config_map       = var.model_test_job_config_map
    use_rmq_health                  = var.use_rmq_health
    use_rmq_resource_cleaner        = var.use_rmq_resource_cleaner
    rmq_resource_cleaner_frequency  = var.rmq_resource_cleaner_frequency
    use_rmq_metrics_updater         = var.use_rmq_metrics_updater
    rmq_metrics_updater_frequency   = var.rmq_metrics_updater_frequency
    separate_model_testing_group    = var.separate_model_testing_group
    create_scheduled_ct             = var.create_scheduled_ct
    overwrite_license               = var.overwrite_license
    release_name                    = var.release_name
    datadog_tag_pod_annotation      = var.datadog_tag_pod_annotation
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
