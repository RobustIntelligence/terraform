<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | > 2.1.0, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | > 2.1.0, < 3.0.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.rime_extras](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.rime_extras](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.docker-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [local_file.rime_extras](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_managed_helm_release"></a> [create\_managed\_helm\_release](#input\_create\_managed\_helm\_release) | Whether to deploy a RIME Helm chart onto the provisioned infrastructure managed by Terraform.<br>  Changing the state of this variable will either install/uninstall the RIME deployment<br>  once the change is applied in Terraform. If you want to install the RIME package manually,<br>  set this to false and use the generated values YAML file to deploy the release<br>  on the provisioned infrastructure. | `bool` | `false` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | API key for the Datadog server that will be used by the Datadog Agent. | `string` | `""` | no |
| <a name="input_docker_credentials"></a> [docker\_credentials](#input\_docker\_credentials) | Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:<br>  [[{<br>    docker-server= "",<br>    docker-username="",<br>    docker-password="",<br>    docker-email=""<br>  }]] | `list(map(string))` | n/a | yes |
| <a name="input_docker_registry"></a> [docker\_registry](#input\_docker\_registry) | The name of the Docker registry that holds the chart images | `string` | `"docker.io"` | no |
| <a name="input_docker_secret_name"></a> [docker\_secret\_name](#input\_docker\_secret\_name) | The name of the Kubernetes secret used to pull the Docker image for RIME's backend services. | `string` | `"rimecreds"` | no |
| <a name="input_helm_values_output_dir"></a> [helm\_values\_output\_dir](#input\_helm\_values\_output\_dir) | The directory where to write the generated values YAML file used to configure the Helm release.<br>  A Helm chart "$helm\_values\_output\_dir/rime\_kube\_system\_values.yaml"<br>  will be created. | `string` | `""` | no |
| <a name="input_install_datadog"></a> [install\_datadog](#input\_install\_datadog) | Whether or not to install the Datadog Agent. | `bool` | `false` | no |
| <a name="input_manage_namespace"></a> [manage\_namespace](#input\_manage\_namespace) | Whether or not to manage the namespace we are installing into.<br>  This will create the namespace(if applicable), setup docker credentials as a<br>  kubernetes secret etc. Turn this flag off if you have trouble connecting to<br>  k8s from your terraform environment. | `bool` | `true` | no |
| <a name="input_override_values_file_path"></a> [override\_values\_file\_path](#input\_override\_values\_file\_path) | Optional file path to override values file for the rime-extras helm release. | `string` | `""` | no |
| <a name="input_rime_repository"></a> [rime\_repository](#input\_rime\_repository) | Repository URL where to locate the requested RIME chart for the give `rime_version`. | `string` | n/a | yes |
| <a name="input_rime_user"></a> [rime\_user](#input\_rime\_user) | User of the RIME deployment. | `string` | n/a | yes |
| <a name="input_rime_version"></a> [rime\_version](#input\_rime\_version) | The version of the RIME software to be installed. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
