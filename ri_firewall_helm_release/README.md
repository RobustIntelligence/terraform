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
| [helm_release.ri_firewall](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.docker-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.integration_secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [local_file.helm_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_cert_arn"></a> [acm\_cert\_arn](#input\_acm\_cert\_arn) | ARN for the ACM cert to validate our domain. | `string` | n/a | yes |
| <a name="input_azure_text_analytics_key"></a> [azure\_text\_analytics\_key](#input\_azure\_text\_analytics\_key) | Azure Text Analytics key for using the language service model resource. | `string` | n/a | yes |
| <a name="input_base_firewall_config"></a> [base\_firewall\_config](#input\_base\_firewall\_config) | Initial firewall system configuration.<br>  This includes information about which model provider (OpenAI or Azure OpenAI)<br>  we will use for evaluation.<br>  It has no customer configuration; the customer can configure certain fields<br>  later with an API call. | `any` | n/a | yes |
| <a name="input_create_managed_helm_release"></a> [create\_managed\_helm\_release](#input\_create\_managed\_helm\_release) | Whether to deploy a RI Firewall Helm chart onto the provisioned infrastructure managed by Terraform.<br>  Changing the state of this variable will either install/uninstall the RI Firewall deployment<br>  once the change is applied in Terraform. If you want to install the RI Firewall package manually,<br>  set this to false and use the generated values YAML file to deploy the release<br>  on the provisioned infrastructure. | `bool` | `false` | no |
| <a name="input_datadog_tag_pod_annotation"></a> [datadog\_tag\_pod\_annotation](#input\_datadog\_tag\_pod\_annotation) | Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {"tag": "val"}. | `string` | `""` | no |
| <a name="input_docker_credentials"></a> [docker\_credentials](#input\_docker\_credentials) | Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:<br>  [{<br>    docker-server= "",<br>    docker-username="",<br>    docker-password="",<br>    docker-email=""<br>  }] | `list(map(string))` | n/a | yes |
| <a name="input_docker_secret_name"></a> [docker\_secret\_name](#input\_docker\_secret\_name) | The name of the Kubernetes secret used to pull the Docker image for RIME's backend services. | `string` | `"rimecreds"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to use for the Firewall. | `string` | n/a | yes |
| <a name="input_enable_auth0"></a> [enable\_auth0](#input\_enable\_auth0) | Whether to enable auth0 for the firewall server. | `bool` | `true` | no |
| <a name="input_enable_datadog_integration"></a> [enable\_datadog\_integration](#input\_enable\_datadog\_integration) | Enable datadog integration. This integration allows customers to visualize the performance<br>  of AI Firewall in their Datadog account via metrics and dashboard. Enabling this flag requires: 1) A<br>  datadog agent to be installed on this cluster with the robustintelligencehq/datadog-agent-firewall-integration<br>  image using the rime-extras package and 2) The Robust intelligence AI Firewall integration installed<br>  in your Datadog account. | `bool` | `false` | no |
| <a name="input_huggingface_api_key"></a> [huggingface\_api\_key](#input\_huggingface\_api\_key) | HuggingFace API key for using tests that require downloading private models from HuggingFace. | `string` | n/a | yes |
| <a name="input_ingress_class_name"></a> [ingress\_class\_name](#input\_ingress\_class\_name) | The name of the ingress class to use for RI Firewall services. If empty, ingress class will be ri-<namespace> | `string` | `""` | no |
| <a name="input_manage_namespace"></a> [manage\_namespace](#input\_manage\_namespace) | Whether or not to manage the namespace we are installing into.<br>  This will create the namespace(if applicable), setup docker credentials as a<br>  kubernetes secret etc. Turn this flag off if you have trouble connecting to<br>  k8s from your terraform environment. | `bool` | `true` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where the RI Firewall Helm chart will be installed. | `string` | n/a | yes |
| <a name="input_openai_api_key"></a> [openai\_api\_key](#input\_openai\_api\_key) | OpenAI API key for using tests that rely on OpenAI models. | `string` | n/a | yes |
| <a name="input_override_values_file_path"></a> [override\_values\_file\_path](#input\_override\_values\_file\_path) | Optional file path to override values file for the ri firewall helm release.<br>  These values take precendence over values produced by the terraform module. | `string` | `""` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | helm release name. Must be set in a multitenant setting | `string` | `"ri-firewall"` | no |
| <a name="input_ri_firewall_repository"></a> [ri\_firewall\_repository](#input\_ri\_firewall\_repository) | Repository URL where to locate the requested RI Firewall chart for the given `ri_firewall_version`. | `string` | n/a | yes |
| <a name="input_ri_firewall_version"></a> [ri\_firewall\_version](#input\_ri\_firewall\_version) | The version of the RI Firewall software to be installed. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
