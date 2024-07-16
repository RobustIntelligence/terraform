locals {
  is_namespace_default = (var.namespace == "default")
  tags                 = join(",", [for key, value in var.tags : "${key}=${value}"])

  # Service account names are used in both the helm chart to create the service account and s3_iam module to link S3 access via OIDC.
  # the service account name for the feature flag server to fetch licences.
  feature_flag_service_account_name           = "rime-${var.namespace}-feature-flag-server"
  storage_manager_server_service_account_name = "rime-${var.namespace}-storage-manager-server"


  # Secret name for the internal agent temporary API key used for registration.
  # This secret will only be created if the internal agent is enabled for this CP.
  # The secret will expire shortly after the agent is created; it is only
  # used to bootstrap the signing key for the agent.
  internal_agent_api_key_secret_name = "${var.release_name}-internal-agent-api-key"
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

resource "kubernetes_network_policy" "rime-network-policy" {
  count = var.isolate_namespace_traffic ? 1 : 0
  metadata {
    name      = "rime-${var.namespace}-network-policy"
    namespace = var.namespace
  }

  spec {
    // Applies to all pods in the namespace var.namespace
    pod_selector {}

    policy_types = ["Ingress", "Egress"]

    ingress {
      // whitelist ingress flows from any pod in var.namespace
      from {
        pod_selector {}
      }

      // whitelist ingress flows over the internet
      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }

    egress {
      // whitelist egress flows to any pod in var.namespace
      to {
        pod_selector {}
      }
      // whitelist egress flows to Kubernetes DNS
      to {
        namespace_selector {}
        pod_selector {
          match_labels = {
            "k8s-app" = "kube-dns"
          }
        }
      }
      // whitelist egress flows over the internet
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.namespace]
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
    rimeLicense   = var.s3_license_enabled ? "" : var.rime_license
    openaiApiKey  = var.openai_api_key
  }
  depends_on = [kubernetes_namespace.namespace]
}

# Generate a random API key for the internal agent.
# The control plane init cluster metadata will create a temporary record for the
# API key that expires after a few days.
# It should be enough time for the internal agent to successfully register its
# sigining key, then it will use that instead.
resource "random_string" "internal_agent_generated_api_key" {
  length = 16

  // This changes the generated API key each time the agent changes.
  // This is important, because if the internal agent install fails - we should
  // create a new internal agent.
  // This allows a new API key to be issued that doesn't clash with the old
  // one.
  keepers = {
    agent_id = var.internal_agent_config.agent_id
  }
}

resource "kubernetes_secret" "internal_agent_api_key_secret" {
  count = var.manage_namespace && var.internal_agent_config.enable ? 1 : 0

  metadata {
    name      = local.internal_agent_api_key_secret_name
    namespace = var.namespace
  }

  data = {
    api-key = random_string.internal_agent_generated_api_key.result
  }
  depends_on = [kubernetes_namespace.namespace]
}

// Create blob store bucket and IAM permissions to upload to the blob store.
module "blob_store" {
  source = "./blob_store"

  count = var.enable_blob_store ? 1 : 0

  namespace            = var.namespace
  oidc_provider_url    = var.oidc_provider_url
  resource_name_suffix = var.resource_name_suffix
  service_account_names = (local.is_namespace_default ?
    ["rime-${var.resource_name_suffix}-dataset-manager-server"] :
    ["rime-${var.namespace}-dataset-manager-server"]
  )
  force_destroy = var.force_destroy
  tags          = var.tags
}

// Create permissions to push and manage images in ECR
module "image_registry" {
  source = "./image_registry"

  count = var.image_registry_config.enable ? 1 : 0

  cloud_platform_config = var.cloud_platform_config

  namespace             = var.namespace
  oidc_provider_url     = var.oidc_provider_url
  image_registry_config = var.image_registry_config
  resource_name_suffix  = var.resource_name_suffix
  tags                  = var.tags
}

// Create secret "rimecreds" in each namespace if we created the namespace
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
    acm_cert_arn = var.acm_cert_arn

    blob_store_config = {
      enable         = var.enable_blob_store
      s3_bucket_name = var.enable_blob_store ? module.blob_store[0].blob_store_bucket_name : ""
      role_arn       = var.enable_blob_store ? module.blob_store[0].blob_store_role_arn : ""
    }

    customer_name         = var.customer_name
    docker_image_names    = var.docker_image_names
    docker_secret_name    = var.docker_secret_name
    docker_registry       = var.docker_registry
    domain                = var.domain == "" ? "placeholder" : var.domain
    disable_vault_tls     = var.disable_vault_tls
    enable_mongo_tls      = var.enable_mongo_tls
    enable_rest_tls       = var.enable_rest_tls
    enable_grpc_tls       = var.enable_grpc_tls
    enable_crossplane_tls = var.enable_crossplane_tls
    enable_cert_manager   = var.enable_cert_manager
    enable_autorotate_tls = var.enable_autorotate_tls
    enable_ingress_nginx  = var.enable_ingress_nginx
    external_vault        = var.external_vault
    existing_secret_name  = kubernetes_secret.rime-secrets[0].metadata[0].name
    feature_flag_config = {
      s3_license_enabled       = var.s3_license_enabled
      s3_bucket_name           = "rime-customer-licenses"
      s3_bucket_region         = "us-west-1"
      service_account_role_arn = var.s3_license_enabled ? module.feature_flag_s3_iam.s3_reader_role_arn : ""
    }
    security_db_service_account_role_arn = module.security_db_api_gateway_iam.security_db_gateway_role_arn
    ingress_class_name                   = var.ingress_class_name != "" ? var.ingress_class_name : "ri-${var.namespace}"
    image_registry_config                = var.image_registry_config.enable ? module.image_registry[0].image_registry_config : null
    internal_agent_config = {
      enable              = var.internal_agent_config.enable
      agent_id            = var.internal_agent_config.agent_id
      api_key_secret_name = local.internal_agent_api_key_secret_name
      secret_key_path     = "api-key"
    }
    ip_allowlist                 = var.ip_allowlist
    lb_tags                      = length(local.tags) > 0 ? "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: \"${local.tags}\"" : ""
    lb_type                      = var.internal_lbs ? "internal" : "internet-facing"
    mongo_db_size                = var.mongo_db_size
    openai_api_key               = var.openai_api_key
    storage_class_name           = var.storage_class_name != "" ? var.storage_class_name : "default"
    namespace                    = var.namespace
    pull_policy                  = var.rime_version == "latest" ? "Always" : "IfNotPresent"
    rime_license                 = var.s3_license_enabled ? "" : var.rime_license
    verbose                      = var.verbose
    version                      = var.rime_version
    separate_model_testing_group = var.separate_model_testing_group
    release_name                 = var.release_name
    datadog_tag_pod_annotation   = var.datadog_tag_pod_annotation
    model_output_is_sensitive    = var.model_output_is_sensitive
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
  timeout           = 600

  values = [
    local_file.helm_values.content,
    length(var.override_values_file_path) > 0 ? file(var.override_values_file_path) : "",
  ]
  depends_on = [kubernetes_namespace.namespace]
}

// Creates S3 reader roles to be used by feature-flag server to fetch the
// licences from s3 bucket
module "feature_flag_s3_iam" {
  source = "../rime_agent/s3_iam"

  namespace            = var.namespace
  oidc_provider_url    = var.oidc_provider_url
  resource_name_suffix = "${var.resource_name_suffix}_feature_flag"
  s3_authorized_bucket_path_arns = [
    "arn:aws:s3:::rime-customer-licenses/*"
  ]
  service_account_names = [
    local.feature_flag_service_account_name,
    local.storage_manager_server_service_account_name,
  ]

  tags = var.tags
}

// Creates API gateway invoking roles to be used by web server (results reader is the service is on
// the web server) to fetch results from the security DB.
module "security_db_api_gateway_iam" {
  source = "./security_db_iam"

  namespace            = var.namespace
  oidc_provider_url    = var.oidc_provider_url
  resource_name_suffix = "${var.resource_name_suffix}_web_server"
  service_account_names = [
    "rime-${var.namespace}-web-server",
  ]

  tags = var.tags
}
