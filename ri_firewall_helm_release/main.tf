locals {
  is_namespace_default = (var.namespace == "default")
  output_dir           = length(var.helm_values_output_dir) == 0 ? path.root : var.helm_values_output_dir
  # Service account name for the nginx deployment to authenticate against an S3 bucket containing maxmind geolocation data.
  nginx_geoip2_service_account_name = "ri-${var.namespace}-nginx-geoip2"
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
    yaraGithubAppPem  = var.yara_github_app_pem
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
    acm_cert_arn                         = var.acm_cert_arn
    ingress_class_name                   = var.ingress_class_name != "" ? var.ingress_class_name : "ri-${var.namespace}"
    domain                               = var.domain
    enable_datadog_integration           = var.enable_datadog_integration
    enable_logscale_logging              = var.enable_logscale_logging
    integration_secrets_name             = kubernetes_secret.integration_secrets[0].metadata[0].name
    namespace                            = var.namespace
    pull_policy                          = var.ri_firewall_version == "latest" ? "Always" : "IfNotPresent"
    ri_firewall_version                  = var.ri_firewall_version
    datadog_tag_pod_annotation           = var.datadog_tag_pod_annotation
    enable_auth0                         = var.enable_auth0
    firewall_enable_yara                 = var.firewall_enable_yara
    yara_auto_update_enabled             = var.yara_auto_update_enabled
    yara_rule_repo_ref                   = var.yara_rule_repo_ref
    yara_pattern_update_frequency        = var.yara_pattern_update_frequency
    enable_register_firewall_agent       = var.enable_register_firewall_agent
    agent_id                             = var.agent_id
    platform_address                     = var.platform_address
    api_key                              = var.api_key
    validate_response_visibility_control = var.validate_response_visibility_control
    nginx_geoip2_service_account_name    = local.nginx_geoip2_service_account_name
    geoip2_service_account_role_arn      = module.nginx_geoip2_iam.nginx_geoip2_role_arn
  })
  filename = format("%s/firewall_values_terraform_%s.yaml", local.output_dir, var.namespace)
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
  timeout           = 600

  values = [
    local_file.helm_values.content,
    length(var.override_values_file_path) > 0 ? file(var.override_values_file_path) : "",
  ]

  depends_on = [kubernetes_namespace.namespace]
}

// Creates IRSA roles to be used by the nginx deployment to authenticate against an S3 bucket containing maxmind geolocation data.
module "nginx_geoip2_iam" {
  source = "../rime_networking/nginx_geoip2_iam"

  namespace            = var.namespace
  oidc_provider_url    = var.oidc_provider_url
  resource_name_suffix = var.namespace

  service_account_names = [
    local.nginx_geoip2_service_account_name
  ]
}
