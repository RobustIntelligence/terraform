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
    openaiAPIKey          = var.openai_api_key
    huggingfaceAPIKey     = var.huggingface_api_key
    azuretextanalyticsKey = var.azure_text_analytics_key
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
    acm_cert_arn     = var.acm_cert_arn
    base_config_json = jsonencode(var.base_firewall_config)
    blob_store_config = {
      s3_bucket_name = module.blob_store.blob_store_bucket_name
      role_arn       = module.blob_store.blob_store_role_arn
    }
    ingress_class_name                       = var.ingress_class_name != "" ? var.ingress_class_name : "ri-${var.namespace}"
    domain                                   = var.domain
    enable_datadog_integration               = var.enable_datadog_integration
    file_storage_server_service_account_name = var.file_storage_server_service_account_name
    firewall_server_service_account_name     = var.firewall_server_service_account_name
    integration_secrets_name                 = kubernetes_secret.integration_secrets[0].metadata[0].name
    namespace                                = var.namespace
    pull_policy                              = var.ri_firewall_version == "latest" ? "Always" : "IfNotPresent"
    ri_firewall_version                      = var.ri_firewall_version
    datadog_tag_pod_annotation               = var.datadog_tag_pod_annotation
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

// Create blob store bucket and IAM permissions to upload to the blob store.
module "blob_store" {
  source = "../rime_helm_release/blob_store"

  namespace             = var.namespace
  oidc_provider_url     = var.oidc_provider_url
  resource_name_suffix  = var.resource_name_suffix
  service_account_names = [var.file_storage_server_service_account_name, var.firewall_server_service_account_name]
  force_destroy         = var.force_destroy
  tags                  = var.tags
}
