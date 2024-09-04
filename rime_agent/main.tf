locals {
  tags       = merge({ ManagedBy = "Terraform" }, var.tags)
  output_dir = length(var.helm_values_output_dir) == 0 ? path.cwd : var.helm_values_output_dir

  # Service account names are used in both the helm chart to create the service account and s3_iam module to link S3 access via OIDC.
  # the service account name for a running model test job.
  model_test_job_service_account_name = "rime-agent-model-tester"
  # the service account name for the cross plane server.
  cross_plane_server_service_account_name = "rime-agent-cross-plane-server"
  # the service account name for the file server.
  file_server_service_account_name = "rime-agent-file-server"
}

// Creates S3 reader roles to be used by model testing jobs
// This module assumes that the service account be named "rime-model-tester" or "rime-<namespace>-model-tester" for
// non-primary namespaces.
module "s3_iam" {
  source = "./s3_iam"

  namespace                      = var.namespace
  oidc_provider_url              = var.oidc_provider_url
  resource_name_suffix           = "${var.resource_name_suffix}_agent"
  s3_authorized_bucket_path_arns = var.s3_authorized_bucket_path_arns
  service_account_names = [
    local.model_test_job_service_account_name,
    local.cross_plane_server_service_account_name,
  ]

  tags = local.tags
}


// Create blob store bucket and IAM permissions to upload to the blob store.
module "blob_store" {
  source = "../rime_helm_release/blob_store"

  count = var.enable_blob_store ? 1 : 0

  namespace             = var.namespace
  oidc_provider_url     = var.oidc_provider_url
  resource_name_suffix  = "agent-${var.resource_name_suffix}"
  service_account_names = [local.file_server_service_account_name]
  force_destroy         = true
  tags                  = var.tags
}

// Create namespace, only if enabled.
resource "kubernetes_namespace" "auto" {
  count = var.manage_namespace ? 1 : 0
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
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
  depends_on = [kubernetes_namespace.auto]
  type       = "kubernetes.io/dockerconfigjson"
}

// Create a secret containing integrations for generative model testing.
resource "kubernetes_secret" "generative-model-testing-secrets" {
  count = var.generative_model_testing_config.enable ? 1 : 0

  metadata {
    name      = "rime-agent-generative-model-testing-secrets"
    namespace = var.namespace
  }

  data = {
    huggingfaceAPIKey = var.generative_model_testing_config.huggingface_api_key
  }
  depends_on = [kubernetes_namespace.auto]
}

resource "local_file" "terraform_provided_values" {
  content = templatefile("${path.module}/values_tmpl.yaml", {
    image                     = var.rime_docker_agent_image
    version                   = var.rime_version
    default_rime_engine_image = var.rime_docker_default_engine_image
    s3_reader_role_arn        = module.s3_iam.s3_reader_role_arn
    docker_registry           = var.docker_registry
    image_pull_secret_name    = var.docker_secret_name
    enable_crossplane_tls     = var.enable_crossplane_tls
    enable_cert_manager       = var.enable_cert_manager

    generative_model_testing_config = {
      enable                 = var.generative_model_testing_config.enable
      secret_name            = var.generative_model_testing_config.enable ? kubernetes_secret.generative-model-testing-secrets[0].metadata[0].name : ""
      detection_engine_image = var.generative_model_testing_config.rime_docker_detection_engine_image
      model_server_image     = var.generative_model_testing_config.rime_docker_model_server_image
      firewall_version       = var.generative_model_testing_config.rime_docker_firewall_image_version
    }

    agent_manager_server_addr        = "${var.cp_release_name}-agent-manager-server.${var.cp_namespace}:5016"
    upload_server_addr               = "${var.cp_release_name}-upload-server.${var.cp_namespace}:5000"
    firewall_server_rest_addr        = "${var.cp_release_name}-firewall-server.${var.cp_namespace}:15002"
    data_collector_rest_addr         = "${var.cp_release_name}-data-collector-server.${var.cp_namespace}:15015"
    upload_server_rest_addr          = "${var.cp_release_name}-upload-server.${var.cp_namespace}:15001"
    dataset_manager_server_rest_addr = "${var.cp_release_name}-dataset-manager-server.${var.cp_namespace}:15009"
    # Address of the CP NGINX ingress controller service for the internal
    # agent to communicate with.
    cp_nginx_controller_rest_addr = "${var.cp_release_name}-ingress-nginx-controller"
    cp_domain_name                = var.cp_domain_name

    model_test_job_service_account_name     = local.model_test_job_service_account_name
    cross_plane_server_service_account_name = local.cross_plane_server_service_account_name
    datadog_tag_pod_annotation              = var.datadog_tag_pod_annotation

    log_archival_config = {
      enable      = var.log_archival_config.enable
      bucket_name = var.log_archival_config.bucket_name
      endpoint    = var.log_archival_config.endpoint
      type        = var.log_archival_config.type
      role_arn    = var.log_archival_config.enable ? module.iam_assumable_role_with_oidc_for_log_archival[0].this_iam_role_arn : ""
    }

    blob_store_config = {
      enable      = var.enable_blob_store
      bucket_name = var.enable_blob_store ? module.blob_store[0].blob_store_bucket_name : ""
      role_arn    = var.enable_blob_store ? module.blob_store[0].blob_store_role_arn : ""
    }

    separate_model_testing_group = var.separate_model_testing_group
  })
  filename = format("%s/rime_agent_values_terraform_%s.yaml", local.output_dir, var.namespace)
}
# The release of the RIME Helm chart in a given k8s namespace.
resource "helm_release" "rime_agent" {
  count = var.create_managed_helm_release ? 1 : 0

  # Chart information.
  repository = var.rime_repository
  chart      = "rime-agent"
  version    = var.rime_version

  name              = "rime-agent"
  namespace         = var.namespace
  create_namespace  = false
  dependency_update = true
  force_update      = false
  lint              = true
  recreate_pods     = false
  wait              = false
  atomic            = true

  values = [
    local_file.terraform_provided_values.content,
    length(var.override_values_file_path) > 0 ? file(var.override_values_file_path) : "",
  ]
}
