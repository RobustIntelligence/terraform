<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.20.0, < 4.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.9.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.20.0, < 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 17.24.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_tag.private_subnet_cluster_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.private_subnet_elb_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.public_subnet_cluster_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.public_subnet_elb_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.vpc_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of EKS cluster. | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to use for the EKS cluster. | `string` | `"1.23"` | no |
| <a name="input_eks_cluster_node_iam_policies"></a> [eks\_cluster\_node\_iam\_policies](#input\_eks\_cluster\_node\_iam\_policies) | Policies to attach to EKS worker nodes. | `list(string)` | `[]` | no |
| <a name="input_map_roles"></a> [map\_roles](#input\_map\_roles) | Additional IAM roles to add to the aws-auth configmap. You will need to set this for any role you want to allow access to EKS | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_map_users"></a> [map\_users](#input\_map\_users) | Additional IAM users to add to the aws-auth configmap. You will need to set this for any role you want to allow access to EKS. | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | A list of private subnet ids to place the EKS cluster and workers within. Must be specified if create\_eks is true | `list(string)` | `[]` | no |
| <a name="input_public_cluster_endpoint"></a> [public\_cluster\_endpoint](#input\_public\_cluster\_endpoint) | Whether or not there should be a public cluster endpoint. | `bool` | `true` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | A list of public subnet ids for EKS cluster load balancers to work in | `list(string)` | `[]` | no |
| <a name="input_server_node_groups_overrides"></a> [server\_node\_groups\_overrides](#input\_server\_node\_groups\_overrides) | A dictionary that specifies overrides for the server node group launch templates.<br>  See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/modules/node_groups/README.md for valid values.<br>  Only applies if using Managed node groups (var.use\_managed\_node\_group = true). | `any` | `{}` | no |
| <a name="input_server_worker_group_desired_size"></a> [server\_worker\_group\_desired\_size](#input\_server\_worker\_group\_desired\_size) | Desired size of the server worker group. Must be >= 0 | `number` | `2` | no |
| <a name="input_server_worker_group_instance_types"></a> [server\_worker\_group\_instance\_types](#input\_server\_worker\_group\_instance\_types) | Instance types for the server worker group. | `list(string)` | <pre>[<br>  "t3.xlarge"<br>]</pre> | no |
| <a name="input_server_worker_group_max_size"></a> [server\_worker\_group\_max\_size](#input\_server\_worker\_group\_max\_size) | Maximum size of the server worker group. Must be >= min size. For best performance we recommend >= 10 nodes as the max size. | `number` | `10` | no |
| <a name="input_server_worker_group_min_size"></a> [server\_worker\_group\_min\_size](#input\_server\_worker\_group\_min\_size) | Minimum size of the server worker group. Must be >= 0 | `number` | `1` | no |
| <a name="input_server_worker_groups_overrides"></a> [server\_worker\_groups\_overrides](#input\_server\_worker\_groups\_overrides) | A dictionary that specifies overrides for the server worker group launch templates. See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/locals.tf#L36 for valid values. | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | `{}` | no |
| <a name="input_use_managed_node_group"></a> [use\_managed\_node\_group](#input\_use\_managed\_node\_group) | Whether or not to use Managed node groups instead of Self-managed nodes for the cluster.<br>  https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html<br>  https://docs.aws.amazon.com/eks/latest/userguide/worker.html | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC where the cluster and workers will be deployed. Must be specified if create\_eks is true. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
<!-- END_TF_DOCS -->
