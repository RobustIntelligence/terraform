data "aws_caller_identity" "current" {}

locals {
  # Bounded by the bucket name length condition of <= 63 so it must be <= 53 as length(rime-blob-) = 10.
  # Because k8s_namespace is <= 12, and resource_name_suffix is <= 25, hash_id is truncated to length 14.
  bucket_suffix = "${substr(local.hash_id, 0, 14)}-${var.k8s_namespace}-${var.resource_name_suffix}"
}

data "aws_iam_policy_document" "s3_log_archival_access_policy_document" {
  count   = var.log_archival_config.enable ? 1 : 0
  version = "2012-10-17"

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.log_archival_config.bucket_name}",
    ]

  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${var.log_archival_config.bucket_name}/*",
    ]
  }

}

resource "aws_iam_policy" "log_archival_access_policy" {
  count = var.log_archival_config.enable ? 1 : 0
  name  = "rime_log_archival_${local.bucket_suffix}" # must be <= 128

  policy = data.aws_iam_policy_document.s3_log_archival_access_policy_document[0].json

  tags = var.tags
}

module "iam_assumable_role_with_oidc_for_log_archival" {
  count   = var.log_archival_config.enable ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role = true

  role_name        = "rime_log_archival_${local.bucket_suffix}" # must be <= 64
  role_description = "Role to access s3 bucket for log archival."

  provider_url = var.oidc_provider_url

  role_policy_arns = [
    aws_iam_policy.log_archival_access_policy[0].arn,
  ]

  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${var.k8s_namespace}:rime-agent-job-monitor",
  ]

  tags = var.tags
}
