locals {
  is_namespace_default = (var.namespace == "default")
}

resource "kubernetes_namespace" "namespace" {
  // Create for each non-default namespaces.
  count = local.is_namespace_default || !var.manage_namespace ? 0 : 1

  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

resource "kubernetes_secret" "integration_secrets" {
  count = var.manage_namespace ? 1 : 0

  metadata {
    name      = "${var.release_name}-secrets-terraform"
    namespace = var.namespace
  }

  data = {
    huggingfaceAPIKey = var.huggingface_api_key
  }
  depends_on = [kubernetes_namespace.namespace]
}

resource "kubernetes_secret" "docker-secrets" {
  count = var.manage_namespace ? 1 : 0
  metadata {
    name      = var.docker_secret_name
    namespace = var.namespace
  }
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        for creds in var.docker_credentials :
        creds["docker-server"] => merge(
          { for k, v in creds : k => v if v != null },
          { auth = base64encode("${creds["docker-username"]}:${creds["docker-password"]}") },
        )
      }
    })
  }
  type       = "kubernetes.io/dockerconfigjson"
  depends_on = [kubernetes_namespace.namespace]
}


# The YAML file created by instantiating `values_tmpl.yaml`.
resource "local_file" "helm_values" {
  content = templatefile("${path.module}/values_tmpl.yaml", {
    acm_cert_arn                  = var.acm_cert_arn
    ingress_class_name            = var.ingress_class_name != "" ? var.ingress_class_name : "ri-${var.namespace}"
    domain                        = var.domain
    enable_datadog_integration    = var.enable_datadog_integration
    enable_logscale_logging       = var.enable_logscale_logging
    integration_secrets_name      = kubernetes_secret.integration_secrets[0].metadata[0].name
    namespace                     = var.namespace
    pull_policy                   = var.ri_firewall_version == "latest" ? "Always" : "IfNotPresent"
    ri_firewall_version           = var.ri_firewall_version
    datadog_tag_pod_annotation    = var.datadog_tag_pod_annotation
    enable_auth0                  = var.enable_auth0
    firewall_enable_yara          = var.firewall_enable_yara
    yara_github_read_token        = var.yara_github_read_token
    yara_auto_update_enabled      = var.yara_auto_update_enabled
    yara_rule_repo_ref            = var.yara_rule_repo_ref
    yara_pattern_update_frequency = var.yara_pattern_update_frequency
    firewall_log_user_data        = var.log_user_data
  })
  filename = format("%s/values_%s.yaml", path.cwd, var.namespace)
}

resource "helm_release" "ri_firewall" {
  count = var.create_managed_helm_release ? 1 : 0

  repository = var.ri_firewall_repository
  chart      = "ri-firewall"
  version    = var.ri_firewall_version

  name      = var.release_name
  namespace = var.namespace

  dependency_update = true
  create_namespace  = !local.is_namespace_default
  lint              = true
  wait              = false

  values = [
    local_file.helm_values.content,
    length(var.override_values_file_path) > 0 ? file(var.override_values_file_path) : "",
  ]

  depends_on = [kubernetes_namespace.namespace]
}
