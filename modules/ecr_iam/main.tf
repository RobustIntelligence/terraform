# This policy depends on the set of S3 paths that our service needs access to
# supplied by the inputs to our terraform module.
#
# For an example of such a policy;
# see: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition_operators.html#Conditions_String
#
# For specification of the bucket ARNs;
# see: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_resource.html
data "aws_iam_policy_document" "eks_ecr_repo_management_policy_document" {
  # Add a policy statement that provides management actions for all
  # repositories owned by RIME.
  statement {
    # For a list of all permissions see:
    # https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonelasticcontainerregistry.html
    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeImages",
      "ecr:PutLifecyclePolicy",
      "ecr:ListImages",
    ]

    # Policy restricted to only ECR repositories owned by RIME.
    resources = ["${var.ecr_registry_arn}:repository/${var.repository_prefix}/*"]
  }

  # Add a policy statement that provides the ability to get authorization
  # tokens on any resources.
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_ecr_repo_management_policy" {
  name = "eks_ecr_repo_management_policy_${var.resource_name_suffix}"

  policy = data.aws_iam_policy_document.eks_ecr_repo_management_policy_document.json

  tags = var.tags
}

module "iam_assumable_role_with_oidc_for_ecr_repo_management" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role      = true
  role_name        = "eks_ecr_repo_manager_${var.resource_name_suffix}"
  role_description = "Role to manage repositories in ECR."

  provider_url = var.oidc_provider_url

  role_policy_arns = [
    aws_iam_policy.eks_ecr_repo_management_policy.arn,
  ]

  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    for n in var.k8s_namespaces : n.primary ? "system:serviceaccount:${n.namespace}:rime-repo-manager" : "system:serviceaccount:${n.namespace}:rime-${n.namespace}-repo-manager"
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "eks_ecr_image_builder_policy_document" {
  # Add a policy statement that provides push and pull actions for images within all
  # repositories owned by RIME enabling newly built images to be pushed to the repo.
  statement {
    # For a list of all permissions see:
    # https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonelasticcontainerregistry.html
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    # Policy restricted to only ECR repositories owned by RIME.
    resources = ["${var.ecr_registry_arn}:repository/${var.repository_prefix}/*"]
  }

  # Add a policy statement that provides the ability to get authorization
  # tokens on any resources.
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_ecr_image_builder_policy" {
  name = "eks_ecr_image_builder_policy_${var.resource_name_suffix}"

  policy = data.aws_iam_policy_document.eks_ecr_image_builder_policy_document.json

  tags = var.tags
}

module "iam_assumable_role_with_oidc_for_ecr_image_builder" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role      = true
  role_name        = "eks_ecr_image_builder_${var.resource_name_suffix}"
  role_description = "Role to build new images within RIME's managed repositories."

  provider_url = var.oidc_provider_url

  role_policy_arns = [
    aws_iam_policy.eks_ecr_image_builder_policy.arn,
  ]

  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    for n in var.k8s_namespaces : n.primary ? "system:serviceaccount:${n.namespace}:rime-image-pusher" : "system:serviceaccount:${n.namespace}:rime-${n.namespace}-image-pusher"
  ]

  tags = var.tags
}
