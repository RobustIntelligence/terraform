<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 3.64.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.64.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.default](https://registry.terraform.io/providers/hashicorp/azurerm/3.64.0/docs/resources/kubernetes_cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of aks cluster. | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to use for the AKS cluster. | `string` | `"1.25"` | no |
| <a name="input_location"></a> [location](#input\_location) | Location of region where aks cluster will be created. | `string` | n/a | yes |
| <a name="input_model_testing_node_pool_desired_size"></a> [model\_testing\_node\_pool\_desired\_size](#input\_model\_testing\_node\_pool\_desired\_size) | Desired size of the model testing worker group.<br>  If var.use\_managed\_node\_group is true, must be >= 1; otherwise, must be >= 0. | `number` | `1` | no |
| <a name="input_model_testing_node_pool_max_size"></a> [model\_testing\_node\_pool\_max\_size](#input\_model\_testing\_node\_pool\_max\_size) | Maximum size of the model testing worker group. Must be >= min size. For best performance we recommend >= 10 nodes as the max size. | `number` | `10` | no |
| <a name="input_model_testing_node_pool_min_size"></a> [model\_testing\_node\_pool\_min\_size](#input\_model\_testing\_node\_pool\_min\_size) | Minimum size of the model testing worker group. Must be >= 0 | `number` | `0` | no |
| <a name="input_model_testing_node_pool_overrides"></a> [model\_testing\_node\_pool\_overrides](#input\_model\_testing\_node\_pool\_overrides) | A dictionary that specifies overrides for the model testing worker group launch templates. See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/locals.tf#L36 for valid values. | `any` | `{}` | no |
| <a name="input_model_testing_node_pool_use_spot"></a> [model\_testing\_node\_pool\_use\_spot](#input\_model\_testing\_node\_pool\_use\_spot) | Use spot instances for model testing worker group. | `bool` | `true` | no |
| <a name="input_model_testing_node_pool_vm_size"></a> [model\_testing\_node\_pool\_vm\_size](#input\_model\_testing\_node\_pool\_vm\_size) | VM size for the model testing worker group. | `string` | `"Standard_D4s_v3"` | no |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | Whether or not the cluster should be private. | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of resource group where aks cluster will be created. | `string` | n/a | yes |
| <a name="input_server_node_pool_desired_size"></a> [server\_node\_pool\_desired\_size](#input\_server\_node\_pool\_desired\_size) | Desired size of the server worker group. Must be >= 0 | `number` | `5` | no |
| <a name="input_server_node_pool_max_size"></a> [server\_node\_pool\_max\_size](#input\_server\_node\_pool\_max\_size) | Maximum size of the server worker group. Must be >= min size. For best performance we recommend >= 10 nodes as the max size. | `number` | `10` | no |
| <a name="input_server_node_pool_min_size"></a> [server\_node\_pool\_min\_size](#input\_server\_node\_pool\_min\_size) | Minimum size of the server worker group. Must be >= 1 | `number` | `4` | no |
| <a name="input_server_node_pool_overrides"></a> [server\_node\_pool\_overrides](#input\_server\_node\_pool\_overrides) | A dictionary that specifies overrides for the server worker group launch templates. See https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/locals.tf#L36 for valid values. | `any` | `{}` | no |
| <a name="input_server_node_pool_vm_size"></a> [server\_node\_pool\_vm\_size](#input\_server\_node\_pool\_vm\_size) | VM size for the server worker group. | `string` | `"Standard_D4s_v3"` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | (Optional) The Network Range used by the Kubernetes service. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | `{}` | no |
| <a name="input_vnet_subnet_id"></a> [vnet\_subnet\_id](#input\_vnet\_subnet\_id) | (Optional) The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_workload_identity_enabled"></a> [workload\_identity\_enabled](#input\_workload\_identity\_enabled) | Enable or Disable Workload Identity. Defaults to true. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
<!-- END_TF_DOCS -->
