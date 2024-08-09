<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | > 2.1.0, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | > 2.1.0, < 3.0.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.2 |

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
| [null_resource.create_firewall_agent](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [local_file.agent_override_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_cert_arn"></a> [acm\_cert\_arn](#input\_acm\_cert\_arn) | ARN for the ACM cert to validate the Firewall domain. | `string` | n/a | yes |
| <a name="input_agent_id"></a> [agent\_id](#input\_agent\_id) | The ID of the agent being deployed. Not required if `create_firewall_agent` is true. | `string` | `""` | no |
| <a name="input_agent_override_values_file"></a> [agent\_override\_values\_file](#input\_agent\_override\_values\_file) | The file where agent override values are stored. | `string` | `"./agent_override_values.yaml"` | no |
| <a name="input_api_key"></a> [api\_key](#input\_api\_key) | The single-use API key to register the agent. Not required if `create_firewall_agent` is true. | `string` | `""` | no |
| <a name="input_control_plane_cluster_name"></a> [control\_plane\_cluster\_name](#input\_control\_plane\_cluster\_name) | The name of the cluster where the Control Plane is deployed. | `string` | `""` | no |
| <a name="input_control_plane_namespace"></a> [control\_plane\_namespace](#input\_control\_plane\_namespace) | The name of the namespace where the Control Plane is deployed. | `string` | `""` | no |
| <a name="input_create_firewall_agent"></a> [create\_firewall\_agent](#input\_create\_firewall\_agent) | Whether to create a new firewall agent. | `bool` | `false` | no |
| <a name="input_create_managed_helm_release"></a> [create\_managed\_helm\_release](#input\_create\_managed\_helm\_release) | Whether to deploy a RI Firewall Helm chart onto the provisioned infrastructure managed by Terraform.<br>  Changing the state of this variable will either install/uninstall the RI Firewall deployment<br>  once the change is applied in Terraform. If you want to install the RI Firewall package manually,<br>  set this to false and use the generated values YAML file to deploy the release<br>  on the provisioned infrastructure. | `bool` | `false` | no |
| <a name="input_datadog_tag_pod_annotation"></a> [datadog\_tag\_pod\_annotation](#input\_datadog\_tag\_pod\_annotation) | Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {"tag": "val"}. | `string` | `""` | no |
| <a name="input_dependency_link"></a> [dependency\_link](#input\_dependency\_link) | The dependency link to the helm release. | `map(string)` | `{}` | no |
| <a name="input_docker_credentials"></a> [docker\_credentials](#input\_docker\_credentials) | Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:<br>  [{<br>    docker-server= "",<br>    docker-username="",<br>    docker-password="",<br>    docker-email=""<br>  }] | `list(map(string))` | n/a | yes |
| <a name="input_docker_secret_name"></a> [docker\_secret\_name](#input\_docker\_secret\_name) | The name of the Kubernetes secret used to pull the Docker images for the Firewall. | `string` | `"rimecreds"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to use for the Firewall. | `string` | n/a | yes |
| <a name="input_enable_auth0"></a> [enable\_auth0](#input\_enable\_auth0) | Whether to enable auth0 for the Firewall. | `bool` | `true` | no |
| <a name="input_enable_datadog_integration"></a> [enable\_datadog\_integration](#input\_enable\_datadog\_integration) | Enable Datadog integration. This integration allows customers to visualize the performance<br>  of RI Firewall in their Datadog account via metrics and dashboard. Enabling this flag requires: 1) A<br>  Datadog agent to be installed on this cluster with the robustintelligencehq/datadog-agent-firewall-integration<br>  image using the rime-extras package and 2) The Robust intelligence Firewall integration installed<br>  in your Datadog account. | `bool` | `false` | no |
| <a name="input_enable_logscale_logging"></a> [enable\_logscale\_logging](#input\_enable\_logscale\_logging) | Enable logging firewall validation logs to logscale(crowdstrike). This integration allows customers to visualize the performance<br>  of RI Firewall in their logscale account via dashboard. Enabling this flag requires: 1) A<br>  Logscale agent to be installed using the rime-extras package and 2) The Robust intelligence Firewall integration installed<br>  in your logscale account. | `bool` | `false` | no |
| <a name="input_enable_register_firewall_agent"></a> [enable\_register\_firewall\_agent](#input\_enable\_register\_firewall\_agent) | Whether to enable the register firewall agent job. | `bool` | `false` | no |
| <a name="input_firewall_enable_yara"></a> [firewall\_enable\_yara](#input\_firewall\_enable\_yara) | Whether to enable firewall rules to call into the YARA service. | `bool` | `true` | no |
| <a name="input_helm_values_output_dir"></a> [helm\_values\_output\_dir](#input\_helm\_values\_output\_dir) | The directory where to write the generated values YAML file used to configure the Helm release.<br>  For the give namespace `k8s_namespace`, a Helm chart "$helm\_values\_output\_dir/values\_$namespace.yaml"<br>  will be created. | `string` | `""` | no |
| <a name="input_huggingface_api_key"></a> [huggingface\_api\_key](#input\_huggingface\_api\_key) | HuggingFace API key to Robust Intelligence's private HuggingFace repo. | `string` | n/a | yes |
| <a name="input_ingress_class_name"></a> [ingress\_class\_name](#input\_ingress\_class\_name) | The name of the ingress class to use for RI Firewall services. If empty, ingress class will be ri-<namespace> | `string` | `""` | no |
| <a name="input_manage_namespace"></a> [manage\_namespace](#input\_manage\_namespace) | Whether or not to manage the namespace we are installing into.<br>  This will create the namespace(if applicable), setup docker credentials as a<br>  Kubernetes secret etc. Turn this flag off if you have trouble connecting to<br>  k8s from your Terraform environment. | `bool` | `true` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where the RI Firewall Helm chart will be installed. | `string` | n/a | yes |
| <a name="input_override_values_file_path"></a> [override\_values\_file\_path](#input\_override\_values\_file\_path) | Optional file path to override values file for the RI Firewall Helm release.<br>  These values take precedence over values produced by the Terraform module. | `string` | `""` | no |
| <a name="input_platform_address"></a> [platform\_address](#input\_platform\_address) | The URL of the control plane. For example https://my_firewall.firewall.rbst.io. | `string` | `""` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Helm release name. Required only in a multi-tenant setting | `string` | `"ri-firewall"` | no |
| <a name="input_ri_firewall_repository"></a> [ri\_firewall\_repository](#input\_ri\_firewall\_repository) | Repository URL where to locate the requested RI Firewall Helm chart for the given `ri_firewall_version`. | `string` | n/a | yes |
| <a name="input_ri_firewall_version"></a> [ri\_firewall\_version](#input\_ri\_firewall\_version) | The version of the RI Firewall to be installed. | `string` | n/a | yes |
| <a name="input_validate_response_visibility_control"></a> [validate\_response\_visibility\_control](#input\_validate\_response\_visibility\_control) | Control for which part of the Validate response appears in stdout and the API.<br>  `firewall_request_*` controls the visibility of the raw user request to the firewall.<br>  `rule_eval_metadata_*` controls the visibility of internal evaluation metadata such as<br>    model scores and model versions. | <pre>object({<br>    firewall_request_enable_stdout_logging         = bool<br>    firewall_request_enable_api_response           = bool<br>    rule_evaluation_metadata_enable_stdout_logging = bool<br>    rule_evaluation_metadata_enable_api_response   = bool<br>  })</pre> | <pre>{<br>  "firewall_request_enable_api_response": false,<br>  "firewall_request_enable_stdout_logging": false,<br>  "rule_evaluation_metadata_enable_api_response": false,<br>  "rule_evaluation_metadata_enable_stdout_logging": true<br>}</pre> | no |
| <a name="input_yara_auto_update_enabled"></a> [yara\_auto\_update\_enabled](#input\_yara\_auto\_update\_enabled) | Whether to allow yara server to periodically update its rules via a pull mechanism. | `bool` | `true` | no |
| <a name="input_yara_github_app_pem"></a> [yara\_github\_app\_pem](#input\_yara\_github\_app\_pem) | Base64 encoded private key to authenticate the hotfixyara server with Github as an app. | `string` | n/a | yes |
| <a name="input_yara_pattern_update_frequency"></a> [yara\_pattern\_update\_frequency](#input\_yara\_pattern\_update\_frequency) | The cron frequency at which yara server should update its rules. If empty and yara\_auto\_update\_enabled is true, the default frequency is every hour. | `string` | `""` | no |
| <a name="input_yara_rule_repo_ref"></a> [yara\_rule\_repo\_ref](#input\_yara\_rule\_repo\_ref) | The revision of the YARA rule git repo to pull at server initialization. If empty, the latest release will be used. | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
