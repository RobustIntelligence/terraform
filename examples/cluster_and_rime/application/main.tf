# ----------------------------------------------------------------------------------------------------------------------
# ROBUST INTELLIGENCE TERRAFORM DEPLOYMENT
#
# Pattern 2: Cluster + Application (Application)
# This main.tf deploys the Robust Intelligence application into the bootstrapped EKS cluster made by ../main.tf.
#
# Version 2.0.0
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = ""
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# DATA
# ----------------------------------------------------------------------------------------------------------------------
data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

# Example of using route53 for managed DNS (optional)
data "aws_route53_zone" "registered_domain_hosted_zone" {
  name = ""
}

# Example of using AWS Secrets Manager to manage the application secret
# For the application, this is needed for items like the license
data "aws_secretsmanager_secret_version" "rime-secrets" {
  secret_id = "rime-${local.infra_name}-secrets"
}

locals {
  # The namespace wherein you are deploying the RIME application.
  namespace = "default"

  # The version of Robust Intelligence that you are deploying
  rime_version = "2.0.0"

  # Generally used as a suffix for various Terraform resources
  infra_name = "acme"

  # The name of the K8s cluster for Robust Intelligence
  cluster_name = "rime-${local.infra_name}"

  # Uncomment if using DataDog (from the rime-extras Helm release)
  # (should correspond to the rime_extras_helm_release.rime_user value)
  datadog_tag_pod_annotation = "{\"user\":\"${local.namespace}\"}"

  # The Helm repository to use for Helm charts
  rime_repository = "https://robustintelligence.github.io/helm"

  # A local directory to store autogenerated Helm values
  helm_values_output_dir = "./rime_application_values"

  # The OIDC provider URL of the aforementioned cluster
  stripped_oidc_provider_url = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")

  # Specify a secret string value (by default, comes from AWS Secrets Manager)
  secrets = jsondecode(data.aws_secretsmanager_secret_version.rime-secrets.secret_string)

  tags = { ManagedBy = "Terraform" }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES
# ----------------------------------------------------------------------------------------------------------------------
module "rime_helm_release" {
  source    = "github.com/RobustIntelligence/terraform//rime_helm_release?ref=2.0.0"
  namespace = local.namespace

  release_name = "rime-${local.infra_name}"

  enable_blob_store = true

  domain       = ""
  acm_cert_arn = module.rime_acm_certs.acm_cert_arn

  image_registry_config = {
    enable         = true
    repo_base_name = "rime-managed-images"
  }

  cloud_platform_config = {
    platform_type = "aws"
    aws_config    = {}
    gcp_config    = null
  }

  docker_credentials = lookup(local.secrets, "docker-logins", [])
  rime_license       = lookup(local.secrets, "rime_jwt", "")
  admin_password     = lookup(local.secrets, "admin_password", "")
  admin_username     = lookup(local.secrets, "admin_username", "")

  rime_version                = local.rime_version
  oidc_provider_url           = local.stripped_oidc_provider_url
  rime_repository             = local.rime_repository
  helm_values_output_dir      = local.helm_values_output_dir
  create_managed_helm_release = true
  resource_name_suffix        = local.infra_name
  datadog_tag_pod_annotation  = local.datadog_tag_pod_annotation
  tags                        = local.tags
}

module "rime_agent_release" {
  source     = "github.com/RobustIntelligence/terraform//rime_agent?ref=2.0.0"
  depends_on = [module.rime_helm_release]
  namespace  = local.namespace

  s3_authorized_bucket_path_arns = [
    "${module.rime_helm_release.blob_store_bucket_arn}/*"
  ]

  cp_release_name  = "rime-${local.namespace}"
  cp_namespace     = local.namespace
  manage_namespace = false

  docker_credentials = lookup(local.secrets, "docker-logins", [])

  rime_version                = local.rime_version
  oidc_provider_url           = local.stripped_oidc_provider_url
  rime_repository             = local.rime_repository
  helm_values_output_dir      = local.helm_values_output_dir
  create_managed_helm_release = true
  resource_name_suffix        = local.infra_name
  datadog_tag_pod_annotation  = local.datadog_tag_pod_annotation
  tags                        = local.tags
}

# If using route53 for DNS, you will need to use this module to create the relevant certificate(s) in ACM.
module "rime_acm_certs" {
  source                    = "github.com/RobustIntelligence/terraform//rime_acm_certs?ref=2.0.0"
  registered_domain_zone_id = data.aws_route53_zone.registered_domain_hosted_zone.zone_id
  domain                    = ""
}
