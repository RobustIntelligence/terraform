resource "aws_s3_bucket" "velero_s3_bucket" {
  count  = var.install_velero ? 1 : 0
  bucket = "rime-velero-backup-${var.resource_name_suffix}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "velero_s3_bucket_access" {
  count  = var.install_velero ? 1 : 0
  bucket = aws_s3_bucket.velero_s3_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "velero_s3_access_policy_document" {
  count   = var.install_velero ? 1 : 0
  version = "2012-10-17"

  statement {
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    resources = [
      "${aws_s3_bucket.velero_s3_bucket[0].arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.velero_s3_bucket[0].arn}",
    ]
  }
}

resource "aws_iam_policy" "velero_s3_access_policy" {
  count = var.install_velero ? 1 : 0
  name  = "velero_s3_access_policy_${var.resource_name_suffix}"

  policy = data.aws_iam_policy_document.velero_s3_access_policy_document[0].json

  tags = var.tags
}

module "iam_assumable_role_with_oidc_for_velero" {
  count = var.install_velero ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role = true

  role_name        = "velero-backup_${var.resource_name_suffix}"
  role_description = "Role to access s3 bucket for velero backup."

  provider_url = var.oidc_provider_url

  role_policy_arns = [
    aws_iam_policy.velero_s3_access_policy[0].arn,
  ]

  number_of_role_policy_arns = 1

  tags = merge({ Role = "velero_backup_${var.resource_name_suffix}" }, var.tags)
}
