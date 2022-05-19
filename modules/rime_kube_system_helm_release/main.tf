data "aws_region" "current" {}

locals {
  output_dir = length(var.helm_values_output_dir) == 0 ? "${path.cwd}" : var.helm_values_output_dir
}

# The YAML file created by instantiating `values_tmpl.yaml`.
resource "local_file" "rime_kube_system" {
  content = templatefile("${path.module}/values_tmpl.yaml", {
    cluster_name                = var.cluster_name
    cluster_autoscaler_role_arn = var.install_cluster_autoscaler ? module.iam_assumable_role_with_oidc_for_autoscaler[0].this_iam_role_arn : ""
    dns_role_arn                = var.install_external_dns ? module.iam_assumable_role_with_oidc_for_route53[0].this_iam_role_arn : ""
    domains                     = var.domains
    install_cluster_autoscaler  = var.install_cluster_autoscaler
    install_external_dns        = var.install_external_dns
    install_lb_controller       = var.install_lb_controller
    install_metrics_server      = var.install_metrics_server
    lb_controller_role_arn      = module.iam_assumable_role_with_oidc_for_load_balancer_controller.this_iam_role_arn
    region                      = data.aws_region.current.name
  })
  filename = format("%s/rime_kube_system_values.yaml", local.output_dir)
}

# The release of the RIME kube system Helm chart for kube system resources needed for our service to function
resource "helm_release" "rime_kube_system" {
  count = var.create_managed_helm_release ? 1 : 0

  # Chart information.
  repository = var.rime_repository
  chart      = "rime-kube-system"
  version    = var.rime_version

  # App configuration
  # The app name needs to be distinct for each namespace due to conflicts with
  # the naming of ClusterRoles for external-dns and nginx.
  # Each app is named with a suffix of its namespace except for the default namespace.
  name              = "rime-kube-system"
  namespace         = "kube-system"
  dependency_update = true
  force_update      = false
  lint              = true
  recreate_pods     = false
  wait              = false

  values = [
    local_file.rime_kube_system.content
  ]
}
