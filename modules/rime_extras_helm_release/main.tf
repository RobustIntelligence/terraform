locals {
  output_dir = length(var.helm_values_output_dir) == 0 ? "${path.cwd}" : var.helm_values_output_dir
}

# The YAML file created by instantiating `values_tmpl.yaml`.
resource "local_file" "rime_extras" {
  content = templatefile("${path.module}/values_tmpl.yaml", {
    install_datadog          = var.install_datadog
    datadog_api_key          = var.datadog_api_key
    datadog_user_tag         = var.rime_user
    datadog_rime_version_tag = var.rime_version
    docker_registry         = var.docker_registry
    docker_secret_name      = var.rime_docker_secret_name
    install_velero           = var.install_velero
    velero_s3_bucket_name    = var.install_velero ? aws_s3_bucket.velero_s3_bucket[0].bucket : ""
    velero_s3_region         = var.install_velero ? aws_s3_bucket.velero_s3_bucket[0].region : ""
    velero_s3_role_arn       = var.install_velero ? module.iam_assumable_role_with_oidc_for_velero[0].this_iam_role_arn : ""
    velero_backup_ttl        = var.velero_backup_ttl
    velero_backup_schedule   = var.velero_backup_schedule
    velero_backup_namespaces = indent(9, yamlencode(var.velero_backup_namespaces))
  })
  filename = format("%s/rime_extras_values.yaml", local.output_dir)
}

# The release of the RIME kube extras Helm chart for rime extra resources needed for our service to function
resource "helm_release" "rime_extras" {
  count = var.create_managed_helm_release ? 1 : 0

  # Chart information.
  repository = var.rime_repository
  chart      = "rime-extras"
  version    = var.rime_version

  name              = "rime-extras"
  namespace         = "rime-extras"
  dependency_update = true
  force_update      = false
  lint              = true
  recreate_pods     = false
  wait              = false

  values = [
    local_file.rime_extras.content
  ]

  depends_on = [
    kubernetes_namespace.rime_extras
  ]
}

resource "kubernetes_namespace" "rime_extras" {
  metadata {
    name = "rime-extras"
    labels = {
      name = "rime-extras"
    }
  }
}
