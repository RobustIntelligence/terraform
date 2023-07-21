output "s3_blob_store_role_arn" {
  value = var.use_blob_store ? module.iam_assumable_role_with_oidc_for_s3_blob_store[0].this_iam_role_arn : ""
}

output "s3_blob_store_bucket_name" {
  value = var.use_blob_store ? aws_s3_bucket.s3_blob_store_bucket[0].bucket : ""
}

output "s3_blob_store_bucket_path_arns" {
  value = var.use_blob_store ? ["${aws_s3_bucket.s3_blob_store_bucket[0].arn}/*"] : []
}
