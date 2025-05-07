TODO
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.20.0, < 4.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.6.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.20.0, < 4.0.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bedrock"></a> [bedrock](#module\_bedrock) | ./bedrock | n/a |
| <a name="module_blob_store"></a> [blob\_store](#module\_blob\_store) | ../rime_helm_release/blob_store | n/a |
| <a name="module_iam_assumable_role_with_oidc_for_log_archival"></a> [iam\_assumable\_role\_with\_oidc\_for\_log\_archival](#module\_iam\_assumable\_role\_with\_oidc\_for\_log\_archival) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| <a name="module_s3_iam"></a> [s3\_iam](#module\_s3\_iam) | ./s3_iam | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.log_archival_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [helm_release.rime_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.auto](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.docker-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.generative-model-testing-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.signing_key_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [local_file.terraform_provided_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_password.internal_agent_generated_api_key](https://registry.terraform.io/providers/hashicorp/random/3.6.1/docs/resources/password) | resource |
| [aws_iam_policy_document.s3_log_archival_access_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_id"></a> [agent\_id](#input\_agent\_id) | UUID of the agent. | `string` | n/a | yes |
| <a name="input_cp_release_name"></a> [cp\_release\_name](#input\_cp\_release\_name) | Name of the control plane helm release to determine addresses. | `string` | `"rime"` | no |
| <a name="input_create_managed_helm_release"></a> [create\_managed\_helm\_release](#input\_create\_managed\_helm\_release) | Whether to deploy the RIME Agent Helm chart onto the provisioned infrastructure managed by Terraform.<br>  Changing the state of this variable will either install/uninstall the RIME deployment<br>  once the change is applied in Terraform. If you want to install the RIME package manually,<br>  set this to false and use both the custom values file and the terraform generated values YAML file to deploy the release<br>  on the provisioned infrastructure. | `bool` | `false` | no |
| <a name="input_datadog_tag_pod_annotation"></a> [datadog\_tag\_pod\_annotation](#input\_datadog\_tag\_pod\_annotation) | Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {"tag": "val"}. | `string` | `""` | no |
| <a name="input_dependency_link"></a> [dependency\_link](#input\_dependency\_link) | The dependency link to the helm release. | `map(string)` | `{}` | no |
| <a name="input_docker_credentials"></a> [docker\_credentials](#input\_docker\_credentials) | Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:<br>  [{<br>    docker-server= "",<br>    docker-username="",<br>    docker-password="",<br>    docker-email=""<br>  }] | `list(map(string))` | n/a | yes |
| <a name="input_docker_registry"></a> [docker\_registry](#input\_docker\_registry) | The name of the Docker registry that holds the chart images | `string` | `"docker.io"` | no |
| <a name="input_docker_secret_name"></a> [docker\_secret\_name](#input\_docker\_secret\_name) | The name of the Kubernetes secret used to pull the Docker image for RIME's backend services. | `string` | `"rimecreds"` | no |
| <a name="input_enable_blob_store"></a> [enable\_blob\_store](#input\_enable\_blob\_store) | Whether to use blob store for the agent. | `bool` | `false` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | enable deployment of cert-manager | `bool` | `true` | no |
| <a name="input_enable_crossplane_tls"></a> [enable\_crossplane\_tls](#input\_enable\_crossplane\_tls) | enable tls for crossplane | `bool` | `true` | no |
| <a name="input_enable_support_bundle"></a> [enable\_support\_bundle](#input\_enable\_support\_bundle) | Whether to enable the support bundle for the rime-agent | `bool` | `true` | no |
| <a name="input_existing_api_key_secret_name"></a> [existing\_api\_key\_secret\_name](#input\_existing\_api\_key\_secret\_name) | Name of the k8s secret containing the API key for agent registration | `string` | n/a | yes |
| <a name="input_generative_model_testing_config"></a> [generative\_model\_testing\_config](#input\_generative\_model\_testing\_config) | The configuration for generative model testing for the RIME agent.<br>    * enable:                                 Whether or not to enable generative model testing.<br>    * huggingface\_api\_key:                    API key to HuggingFace for model servers.<br>    * rime\_docker\_detection\_engine\_image      Docker image for the detection server.<br>    * rime\_docker\_model\_server\_image          Docker image for the model servers.<br>    * rime\_docker\_firewall\_backend\_image      Docker image for the YARA server.<br>    * rime\_docker\_firewall\_image\_version      Docker image version to use for the GAI model testing images. | <pre>object({<br>    enable                             = bool<br>    huggingface_api_key                = optional(string, "")<br>    rime_docker_detection_engine_image = optional(string, "robustintelligencehq/ri-firewall")<br>    rime_docker_model_server_image     = optional(string, "robustintelligencehq/firewall-model-server")<br>    rime_docker_firewall_backend_image = optional(string, "robustintelligencehq/firewall-backend")<br>    rime_docker_firewall_image_version = optional(string, "latest")<br>  })</pre> | <pre>{<br>  "enable": false<br>}</pre> | no |
| <a name="input_helm_values_output_dir"></a> [helm\_values\_output\_dir](#input\_helm\_values\_output\_dir) | The directory where to write the generated values YAML file used to configure the Helm release.<br>  For the give namespace `k8s_namespace`, a Helm chart "$helm\_values\_output\_dir/values\_$namespace.yaml"<br>  will be created. | `string` | `""` | no |
| <a name="input_log_archival_config"></a> [log\_archival\_config](#input\_log\_archival\_config) | The configuration for RIME job log archival. This requires permissions to write to an s3 bucket.<br>    * enable:                 Whether or not to enable log archival.<br>    * bucket\_name:            The name of the bucket to store logs in.<br>    * endpoint:               The endpoint of the bucket to store logs in. For example, 's3.amazonaws.com'.<br>    * type:                   The type of storage to use. Currently, only 's3' is supported. | <pre>object({<br>    enable      = bool<br>    bucket_name = string<br>    endpoint    = string<br>    type        = string<br>  })</pre> | <pre>{<br>  "bucket_name": "",<br>  "enable": false,<br>  "endpoint": "s3.amazonaws.com",<br>  "type": "s3"<br>}</pre> | no |
| <a name="input_manage_namespace"></a> [manage\_namespace](#input\_manage\_namespace) | Whether or not to manage the namespace we are installing into.<br>  This will create the namespace(if applicable), setup docker credentials as a<br>  kubernetes secret etc. Turn this flag off if you have trouble connecting to<br>  k8s from your terraform environment. | `bool` | `true` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The k8s namespace to install the rime-agent into | `string` | n/a | yes |
| <a name="input_oidc_provider_url"></a> [oidc\_provider\_url](#input\_oidc\_provider\_url) | URL to the OIDC provider for IAM assumable roles used by K8s. | `string` | n/a | yes |
| <a name="input_override_values_file_path"></a> [override\_values\_file\_path](#input\_override\_values\_file\_path) | Optional file path to override values file for the rime-agent helm release. | `string` | `""` | no |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | A suffix to use with the names of resources created by this module. | `string` | n/a | yes |
| <a name="input_rime_docker_agent_image"></a> [rime\_docker\_agent\_image](#input\_rime\_docker\_agent\_image) | The name of the Docker image for the RIME agent, not including a tag. | `string` | `"robustintelligencehq/rime-agent"` | no |
| <a name="input_rime_docker_default_engine_image"></a> [rime\_docker\_default\_engine\_image](#input\_rime\_docker\_default\_engine\_image) | The name of the Docker image used as the default for the RIME engine, not including a tag. | `string` | `"robustintelligencehq/rime-testing-engine-dev"` | no |
| <a name="input_rime_repository"></a> [rime\_repository](#input\_rime\_repository) | Repository URL where to locate the requested RIME chart for the give `rime_version`. | `string` | n/a | yes |
| <a name="input_rime_version"></a> [rime\_version](#input\_rime\_version) | The version of the RIME software to be installed. | `string` | n/a | yes |
| <a name="input_s3_authorized_bucket_path_arns"></a> [s3\_authorized\_bucket\_path\_arns](#input\_s3\_authorized\_bucket\_path\_arns) | A list of all S3 bucket path arns of which RIME will be granted access to.<br>  Each path must be of the form:<br>      arn:aws:s3:::<BUCKET>/sub/path<br>  where <BUCKET> is the name of the S3 bucket and `sub/path` comprises<br>  some path within the bucket. You can also use wildcards '?' or '*' within<br>  the arn specification (e.g. 'arn:aws:s3:::datasets/*'). | `list(string)` | n/a | yes |
| <a name="input_separate_model_testing_group"></a> [separate\_model\_testing\_group](#input\_separate\_model\_testing\_group) | Whether to force model testing jobs to run on dedicated model-testing nodes, using NodeSelectors | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
