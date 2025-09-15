data "aws_caller_identity" "current" {}

locals {
  hash_id = sha256("${data.aws_caller_identity.current.account_id}_${var.resource_name_suffix})_${var.namespace}")

  # Bounded by the bucket name length condition of <= 63 so it must be <= 53 as length(rime-blob-) = 10.
  # Because k8s_namespace is <= 12, and resource_name_suffix is <= 25, hash_id is truncated to length 14.
  bucket_suffix = "${substr(local.hash_id, 0, 14)}-${var.resource_name_suffix}-${var.namespace}"
}

resource "aws_s3_bucket" "s3_blob_store_bucket" {
  bucket        = "rime-blob-${local.bucket_suffix}" # must be <= 63
  force_destroy = var.force_destroy
  tags          = var.tags

  lifecycle {
    ignore_changes = [
      bucket,
      lifecycle_rule, # Linked to AWS Provider v3.75.0, can remove when upgraded to >= v4.0.0
    ]
  }
}

resource "aws_s3_bucket_versioning" "s3_blob_store_bucket" {
  bucket = aws_s3_bucket.s3_blob_store_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_blob_store_bucket" {
  bucket = aws_s3_bucket.s3_blob_store_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_archival_ttl" {
  bucket = aws_s3_bucket.s3_blob_store_bucket.id

  rule {
    expiration {
      days = 7
    }

    filter {
      prefix = "logs/"
    }
    id     = "logs"
    status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "s3_blob_store_bucket_access" {
  bucket = aws_s3_bucket.s3_blob_store_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "s3_blob_store_access_policy_document" {
  version = "2012-10-17"

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.s3_blob_store_bucket.arn,
    ]

  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.s3_blob_store_bucket.arn}/*",
    ]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:GetEbsDefaultKmsKeyId",
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:DetachVolume",
      "ec2:DescribeVolumes",
      "ec2:CreateSnapshot",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_blob_store_access_policy" {
  name = "rime_blob_policy_${local.bucket_suffix}" # must be <= 128

  policy = data.aws_iam_policy_document.s3_blob_store_access_policy_document.json

  tags = var.tags
}

module "iam_assumable_role_with_oidc_for_s3_blob_store" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role = true

  role_name        = "rime_blob_${local.bucket_suffix}" # must be <= 64
  role_description = "Role to access s3 bucket for blob store."

  provider_url = var.oidc_provider_url

  role_policy_arns = [
    aws_iam_policy.s3_blob_store_access_policy.arn,
  ]

  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    for service_account_name in var.service_account_names : "system:serviceaccount:${var.namespace}:${service_account_name}"
  ]

  tags = var.tags
}
