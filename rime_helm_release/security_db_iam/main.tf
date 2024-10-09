data "aws_iam_policy_document" "security_db_gateway_access_policy_document" {
  version = "2012-10-17"

  statement {
    actions = [
      "execute-api:Invoke",
    ]

    resources = [
      "arn:aws:execute-api:us-west-2:746181457053:vq6w9d4yxd/*/GET/security_report",
      "arn:aws:execute-api:us-west-2:746181457053:vq6w9d4yxd/*/GET/gai_test_run/*",
    ]

  }

}

resource "aws_iam_policy" "security_db_gateway_access_policy" {
  name = "security_db_policy_${var.resource_name_suffix}_${var.namespace}"

  policy = data.aws_iam_policy_document.security_db_gateway_access_policy_document.json

  tags = var.tags
}

module "iam_assumable_role_with_oidc_for_api_gateway_access" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role      = true
  role_name        = "security_db_${var.resource_name_suffix}_${var.namespace}"
  role_description = "Role to access security DB's API gateway"

  provider_url = var.oidc_provider_url

  role_policy_arns = [
    aws_iam_policy.security_db_gateway_access_policy.arn,
  ]

  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    for service_account_name in var.service_account_names : "system:serviceaccount:${var.namespace}:${service_account_name}"
  ]

  tags = var.tags

}
