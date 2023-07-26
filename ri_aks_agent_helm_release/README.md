TODO
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 3.64.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_blob_storage_identity"></a> [azure\_blob\_storage\_identity](#module\_azure\_blob\_storage\_identity) | ./azure_blob_storage_identity | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.rime_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.auto](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.docker-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [local_file.terraform_provided_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_storage_account_name"></a> [azure\_storage\_account\_name](#input\_azure\_storage\_account\_name) | The name of the Azure storage account to use for the RIME backend. | `string` | n/a | yes |
| <a name="input_azure_storage_account_resource_group"></a> [azure\_storage\_account\_resource\_group](#input\_azure\_storage\_account\_resource\_group) | The name of the Azure storage account to use for the RIME backend. | `string` | n/a | yes |
| <a name="input_cp_namespace"></a> [cp\_namespace](#input\_cp\_namespace) | Namespace where the control plane helm chart is installed. Used to determine addresses. | `string` | `"default"` | no |
| <a name="input_cp_release_name"></a> [cp\_release\_name](#input\_cp\_release\_name) | Name of the control plane helm release to determine addresses. | `string` | `"rime"` | no |
| <a name="input_create_managed_helm_release"></a> [create\_managed\_helm\_release](#input\_create\_managed\_helm\_release) | Whether to deploy the RIME Agent Helm chart onto the provisioned infrastructure managed by Terraform.<br>  Changing the state of this variable will either install/uninstall the RIME deployment<br>  once the change is applied in Terraform. If you want to install the RIME package manually,<br>  set this to false and use both the custom values file and the terraform generated values YAML file to deploy the release<br>  on the provisioned infrastructure. | `bool` | `false` | no |
| <a name="input_datadog_tag_pod_annotation"></a> [datadog\_tag\_pod\_annotation](#input\_datadog\_tag\_pod\_annotation) | Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {"tag": "val"}. | `string` | `""` | no |
| <a name="input_docker_credentials"></a> [docker\_credentials](#input\_docker\_credentials) | Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:<br>  [{<br>    docker-server= "",<br>    docker-username="",<br>    docker-password="",<br>    docker-email=""<br>  }] | `list(map(string))` | n/a | yes |
| <a name="input_docker_registry"></a> [docker\_registry](#input\_docker\_registry) | The name of the Docker registry that holds the chart images | `string` | `"docker.io"` | no |
| <a name="input_docker_secret_name"></a> [docker\_secret\_name](#input\_docker\_secret\_name) | The name of the Kubernetes secret used to pull the Docker image for RIME's backend services. | `string` | `"rimecreds"` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | enable deployment of cert-manager | `bool` | `true` | no |
| <a name="input_enable_crossplane_tls"></a> [enable\_crossplane\_tls](#input\_enable\_crossplane\_tls) | enable tls for crossplane | `bool` | `true` | no |
| <a name="input_helm_values_output_dir"></a> [helm\_values\_output\_dir](#input\_helm\_values\_output\_dir) | The directory where to write the generated values YAML file used to configure the Helm release.<br>  For the give namespace `k8s_namespace`, a Helm chart "$helm\_values\_output\_dir/values\_$namespace.yaml"<br>  will be created. | `string` | `""` | no |
| <a name="input_manage_namespace"></a> [manage\_namespace](#input\_manage\_namespace) | Whether or not to manage the namespace we are installing into.<br>  This will create the namespace(if applicable), setup docker credentials as a<br>  kubernetes secret etc. Turn this flag off if you have trouble connecting to<br>  k8s from your terraform environment. | `bool` | `true` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The k8s namespace to install the rime-agent into | `string` | n/a | yes |
| <a name="input_oidc_issuer_url"></a> [oidc\_issuer\_url](#input\_oidc\_issuer\_url) | URL to the OIDC issuer for workload identity assumable roles used by K8s. | `string` | n/a | yes |
| <a name="input_override_values_file_path"></a> [override\_values\_file\_path](#input\_override\_values\_file\_path) | Optional file path to override values file for the rime-agent helm release. | `string` | `""` | no |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | A suffix to use with the names of resources created by this module. | `string` | n/a | yes |
| <a name="input_rime_docker_agent_image"></a> [rime\_docker\_agent\_image](#input\_rime\_docker\_agent\_image) | The name of the Docker image for the RIME agent, not including a tag. | `string` | `"robustintelligencehq/rime-agent"` | no |
| <a name="input_rime_docker_default_engine_image"></a> [rime\_docker\_default\_engine\_image](#input\_rime\_docker\_default\_engine\_image) | The name of the Docker image used as the default for the RIME engine, not including a tag. | `string` | `"robustintelligencehq/rime-testing-engine-dev"` | no |
| <a name="input_rime_repository"></a> [rime\_repository](#input\_rime\_repository) | Repository URL where to locate the requested RIME chart for the give `rime_version`. | `string` | n/a | yes |
| <a name="input_rime_version"></a> [rime\_version](#input\_rime\_version) | The version of the RIME software to be installed. | `string` | n/a | yes |
| <a name="input_separate_model_testing_group"></a> [separate\_model\_testing\_group](#input\_separate\_model\_testing\_group) | Whether to force model testing jobs to run on dedicated model-testing nodes, using NodeSelectors | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
