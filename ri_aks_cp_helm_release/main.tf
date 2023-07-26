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

// Create application secret used by the RIME control plane
resource "kubernetes_secret" "rime-secrets" {
  count = var.manage_namespace ? 1 : 0

  metadata {
    name      = "${var.release_name}-secrets-terraform"
    namespace = var.namespace
  }

  data = {
    adminUsername = var.admin_username
    adminPassword = var.admin_password
    rimeLicense   = var.rime_license
  }
  depends_on = [kubernetes_namespace.namespace]
}

// Create docker secret "rimecreds" in each namespace if we created the namespace
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
    docker_image_names      = var.docker_image_names
    docker_secret_name      = var.docker_secret_name
    certificate_secret_name = var.certificate_secret_name
    docker_registry         = var.docker_registry
    domain                  = var.domain == "" ? "placeholder" : var.domain
    disable_vault_tls       = var.disable_vault_tls
    enable_mongo_tls        = var.enable_mongo_tls
    enable_rest_tls         = var.enable_rest_tls
    enable_grpc_tls         = var.enable_grpc_tls
    enable_crossplane_tls   = var.enable_crossplane_tls
    enable_cert_manager     = var.enable_cert_manager
    enable_autorotate_tls   = var.enable_autorotate_tls
    external_vault          = var.external_vault
    existing_secret_name    = kubernetes_secret.rime-secrets[0].metadata[0].name

    internal_lbs                 = var.internal_lbs
    ip_allowlist                 = var.ip_allowlist
    mongo_db_size                = var.mongo_db_size
    storage_class_name           = var.storage_class_name != "" ? var.storage_class_name : "default"
    namespace                    = var.namespace
    pull_policy                  = var.rime_version == "latest" ? "Always" : "IfNotPresent"
    rime_license                 = var.rime_license
    verbose                      = var.verbose
    version                      = var.rime_version
    separate_model_testing_group = var.separate_model_testing_group
    release_name                 = var.release_name
    datadog_tag_pod_annotation   = var.datadog_tag_pod_annotation
  })
  filename = format("%s/values_%s.yaml", length(var.helm_values_output_dir) == 0 ? path.cwd : var.helm_values_output_dir, var.namespace)
}

# The release of the RIME Helm chart in a given k8s namespace.
resource "helm_release" "rime" {
  count = var.create_managed_helm_release ? 1 : 0

  # Chart information.
  repository = var.rime_repository
  chart      = "rime"
  version    = var.rime_version

  name              = var.release_name
  namespace         = var.namespace
  create_namespace  = !local.is_namespace_default
  dependency_update = true
  force_update      = false
  lint              = true
  recreate_pods     = false
  wait              = false

  values = [
    local_file.helm_values.content,
    length(var.override_values_file_path) > 0 ? file(var.override_values_file_path) : "",
  ]
  depends_on = [kubernetes_namespace.namespace]
}
