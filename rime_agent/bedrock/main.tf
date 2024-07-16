data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "bedrock_access_policy_document" {
  statement {
    actions = [
      "bedrock:InvokeModel",
    ]

    resources = [
      "*", // Replace this with the ARN of your Bedrock model
    ]
  }
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/bedrock_access_${var.resource_name_suffix}_${var.namespace}", // Replace with the specific role ARN
    ]
  }
}

resource "aws_iam_policy" "bedrock_access_policy" {
  name   = "bedrock_policy_${var.resource_name_suffix}_${var.namespace}"
  policy = data.aws_iam_policy_document.bedrock_access_policy_document.json
  tags   = var.tags
}


module "iam_assumable_role_with_oidc_for_bedrock_access" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role      = true
  role_name        = "bedrock_access_${var.resource_name_suffix}_${var.namespace}"
  role_description = "Role to access models in Bedrock"

  provider_url = var.oidc_provider_url

  role_policy_arns = [
    aws_iam_policy.bedrock_access_policy.arn,
  ]

  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    for service_account_name in var.service_account_names : "system:serviceaccount:${var.namespace}:${service_account_name}"
  ]

  tags = var.tags
}
