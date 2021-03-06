locals {
  json_secrets               = jsondecode(data.aws_secretsmanager_secret_version.rime-secrets.secret_string)
  stripped_oidc_provider_url = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  tags                       = merge({ ManagedBy = "Terraform" }, var.tags)
  output_dir                 = length(var.helm_values_output_dir) == 0 ? path.cwd : var.helm_values_output_dir

  # the service account name for a running model test job.
  # This name is used in both the helm chart to create the service account and s3_iam module to link S3 access via OIDC.
  model_test_job_service_account_name = "rime-agent-model-tester"
}

data "aws_secretsmanager_secret_version" "rime-secrets" {
  secret_id = var.rime_secrets_name
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}


// Creates S3 reader roles to be used by model testing jobs
// This module assumes that the service account be named "rime-model-tester" or "rime-<namespace>-model-tester" for
// non-primary namespaces.
module "s3_iam" {
  source = "../s3_iam"

  k8s_namespace = {
    namespace : var.k8s_namespace
    primary : true
  }

  oidc_provider_url              = local.stripped_oidc_provider_url
  resource_name_suffix           = "${var.resource_name_suffix}_agent"
  s3_authorized_bucket_path_arns = var.s3_authorized_bucket_path_arns
  service_account_name           = local.model_test_job_service_account_name

  tags = local.tags
}

// Create namespace, only if enabled.
resource "kubernetes_namespace" "auto" {
  count = var.create_k8s_namespace ? 1 : 0
  metadata {
    name = var.k8s_namespace
    labels = {
      name = var.k8s_namespace
    }
  }
}

// Create secret "rimecreds" in each namespace if we created the namespace
resource "kubernetes_secret" "docker-secrets" {
  count = var.create_k8s_namespace ? 1 : 0
  metadata {
    name      = var.rime_docker_secret_name
    namespace = var.k8s_namespace
  }
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        for creds in local.json_secrets["docker-logins"] : creds["docker-server"] => merge(
          { for k, v in creds : k => v if v != null },
          { auth = base64encode("${creds["docker-username"]}:${creds["docker-password"]}") },
        )
      }
    })
  }
  depends_on = [kubernetes_namespace.auto]
  type       = "kubernetes.io/dockerconfigjson"
}


resource "local_file" "terraform_provided_values" {
  content = templatefile("${path.module}/values_terraform_tmpl.yaml", {
    image                               = var.rime_docker_agent_image
    version                             = var.rime_version
    s3_reader_role_arn                  = module.s3_iam.s3_reader_role_arn
    image_pull_secret_name              = var.rime_docker_secret_name
    redis_addr                          = var.redis_addr
    upload_server_addr                  = var.upload_server_addr
    firewall_server_addr                = var.firewall_server_addr
    job_manager_server_addr             = var.job_manager_server_addr
    model_test_job_service_account_name = local.model_test_job_service_account_name
    model_test_job_config_map           = var.model_test_job_config_map
  })
  filename = format("%s/rime_agent_values_terraform_%s.yaml", local.output_dir, var.k8s_namespace)
}
# The release of the RIME Helm chart in a given k8s namespace.
resource "helm_release" "rime_agent" {
  count = var.create_managed_helm_release ? 1 : 0

  # Chart information.
  repository = var.rime_repository
  chart      = "rime-agent"
  version    = var.rime_version

  name              = "rime-agent"
  namespace         = var.k8s_namespace
  create_namespace  = false
  dependency_update = true
  force_update      = false
  lint              = true
  recreate_pods     = false
  wait              = false
  atomic            = true

  values = [
    length(var.custom_values_file_path) > 0 ? file(var.custom_values_file_path) : "",
    local_file.terraform_provided_values.content,
  ]
}
