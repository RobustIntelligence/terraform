<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | > 2.1.0, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |
| <a name="requirement_onepassword"></a> [onepassword](#requirement\_onepassword) | 2.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.6.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | > 2.1.0, < 3.0.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0.0 |
| <a name="provider_onepassword"></a> [onepassword](#provider\_onepassword) | 2.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_blob_store"></a> [blob\_store](#module\_blob\_store) | ./blob_store | n/a |
| <a name="module_feature_flag_s3_iam"></a> [feature\_flag\_s3\_iam](#module\_feature\_flag\_s3\_iam) | ../rime_agent/s3_iam | n/a |
| <a name="module_image_registry"></a> [image\_registry](#module\_image\_registry) | ./image_registry | n/a |
| <a name="module_security_db_api_gateway_iam"></a> [security\_db\_api\_gateway\_iam](#module\_security\_db\_api\_gateway\_iam) | ./security_db_iam | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.rime](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_network_policy.rime-network-policy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_secret.docker-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.internal_agent_api_key_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.internal_firewall_agent_api_key_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.rime-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [local_file.helm_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [onepassword_item.admin_user_password](https://registry.terraform.io/providers/1Password/onepassword/2.1.0/docs/resources/item) | resource |
| [onepassword_item.support_user_password](https://registry.terraform.io/providers/1Password/onepassword/2.1.0/docs/resources/item) | resource |
| [random_password.admin_password](https://registry.terraform.io/providers/hashicorp/random/3.6.1/docs/resources/password) | resource |
| [random_password.support_user_password](https://registry.terraform.io/providers/hashicorp/random/3.6.1/docs/resources/password) | resource |
| [random_string.internal_agent_generated_api_key](https://registry.terraform.io/providers/hashicorp/random/3.6.1/docs/resources/string) | resource |
| [random_string.internal_firewall_agent_generated_api_key](https://registry.terraform.io/providers/hashicorp/random/3.6.1/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_cert_arn"></a> [acm\_cert\_arn](#input\_acm\_cert\_arn) | ARN for the acm cert to validate our domain. | `string` | `""` | no |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | The initial admin password for your installation. If not set, a random password will be generated. | `string` | `""` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The initial admin username for your installation. Must be a valid email. | `string` | n/a | yes |
| <a name="input_cloud_platform_config"></a> [cloud\_platform\_config](#input\_cloud\_platform\_config) | A configuration that is specific to the cloud platform being used | <pre>object({<br>    platform_type = string<br>    aws_config    = object({})<br>    gcp_config = object({<br>      location      = string<br>      project       = string<br>      node_sa_email = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_create_managed_helm_release"></a> [create\_managed\_helm\_release](#input\_create\_managed\_helm\_release) | Whether to deploy a RIME Helm chart onto the provisioned infrastructure managed by Terraform.<br>  Changing the state of this variable will either install/uninstall the RIME deployment<br>  once the change is applied in Terraform. If you want to install the RIME package manually,<br>  set this to false and use the generated values YAML file to deploy the release<br>  on the provisioned infrastructure. | `bool` | `false` | no |
| <a name="input_customer_name"></a> [customer\_name](#input\_customer\_name) | The name of the customer that is used in the licence file. This name should be unique for each rime instance since we generate the license based on the name. | `string` | n/a | yes |
| <a name="input_datadog_tag_pod_annotation"></a> [datadog\_tag\_pod\_annotation](#input\_datadog\_tag\_pod\_annotation) | Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {"tag": "val"}. | `string` | `""` | no |
| <a name="input_disable_vault_tls"></a> [disable\_vault\_tls](#input\_disable\_vault\_tls) | disable tls for vault | `bool` | `false` | no |
| <a name="input_docker_credentials"></a> [docker\_credentials](#input\_docker\_credentials) | Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:<br>  [{<br>    docker-server= "",<br>    docker-username="",<br>    docker-password="",<br>    docker-email=""<br>  }] | `list(map(string))` | n/a | yes |
| <a name="input_docker_image_names"></a> [docker\_image\_names](#input\_docker\_image\_names) | The configuration for the docker images used to run rime, each of which<br>  is in the docker registry specified by `docker_registry`. These image names<br>  serve the following purpose.<br>    * backend:            the image for RIME's backend services.<br>    * frontend:           the image for RIME's frontend services.<br>    * image\_builder:      the image used to build new RIME wheel images for managed images.<br>    * base\_rime\_image:    the base RIME wheel image upon which new managed images are built.<br>    * default\_rime\_image: the default RIME wheel image used for model tests. | <pre>object({<br>    backend            = string<br>    frontend           = string<br>    image_builder      = string<br>    base_rime_image    = string<br>    default_rime_image = string<br>  })</pre> | <pre>{<br>  "backend": "robustintelligencehq/rime-backend",<br>  "base_rime_image": "robustintelligencehq/rime-base-wheel",<br>  "default_rime_image": "robustintelligencehq/rime-testing-engine-dev",<br>  "frontend": "robustintelligencehq/rime-frontend",<br>  "image_builder": "robustintelligencehq/rime-image-builder"<br>}</pre> | no |
| <a name="input_docker_registry"></a> [docker\_registry](#input\_docker\_registry) | The name of the Docker registry that holds the chart images | `string` | `"docker.io"` | no |
| <a name="input_docker_secret_name"></a> [docker\_secret\_name](#input\_docker\_secret\_name) | The name of the Kubernetes secret used to pull the Docker image for RIME's backend services. | `string` | `"rimecreds"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The domain to use for all exposed rime services. | `string` | n/a | yes |
| <a name="input_enable_autorotate_tls"></a> [enable\_autorotate\_tls](#input\_enable\_autorotate\_tls) | enable auto rotation for tls | `bool` | `true` | no |
| <a name="input_enable_blob_store"></a> [enable\_blob\_store](#input\_enable\_blob\_store) | Whether to use blob store for the cluster. | `bool` | `true` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | enable deployment of cert-manager | `bool` | `true` | no |
| <a name="input_enable_crossplane_tls"></a> [enable\_crossplane\_tls](#input\_enable\_crossplane\_tls) | enable tls for crossplane | `bool` | `true` | no |
| <a name="input_enable_grpc_tls"></a> [enable\_grpc\_tls](#input\_enable\_grpc\_tls) | enable tls for grpc | `bool` | `true` | no |
| <a name="input_enable_ingress_nginx"></a> [enable\_ingress\_nginx](#input\_enable\_ingress\_nginx) | Whether or not to install ingress-nginx. Only turn this off if you have some other ingress controller installed. | `bool` | `true` | no |
| <a name="input_enable_mongo_tls"></a> [enable\_mongo\_tls](#input\_enable\_mongo\_tls) | enable tls for mongo | `bool` | `true` | no |
| <a name="input_enable_rest_tls"></a> [enable\_rest\_tls](#input\_enable\_rest\_tls) | enable tls for rest | `bool` | `true` | no |
| <a name="input_external_vault"></a> [external\_vault](#input\_external\_vault) | Whether to use external Vault. | `bool` | `false` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Whether or not to force destroy the blob store bucket | `bool` | `false` | no |
| <a name="input_helm_values_output_dir"></a> [helm\_values\_output\_dir](#input\_helm\_values\_output\_dir) | The directory where to write the generated values YAML file used to configure the Helm release.<br>  For the give namespace `k8s_namespace`, a Helm chart "$helm\_values\_output\_dir/values\_$namespace.yaml"<br>  will be created. | `string` | `""` | no |
| <a name="input_image_registry_config"></a> [image\_registry\_config](#input\_image\_registry\_config) | The configuration for the RIME Image Registry service, which manages custom images<br>  for running RIME stress tests with different Python model requirements:<br>    * enable:                       whether or not to enable the RIME Image Registry service.<br>    * repo\_base\_name:               the base name used for all repositories created<br>                                    and managed by the RIME Image Registry service. | <pre>object({<br>    enable         = bool<br>    repo_base_name = string<br>  })</pre> | <pre>{<br>  "enable": true,<br>  "repo_base_name": "rime-managed-images"<br>}</pre> | no |
| <a name="input_ingress_class_name"></a> [ingress\_class\_name](#input\_ingress\_class\_name) | The name of the ingress class to use for RIME services. If empty, ingress class will be ri-<namespace> | `string` | `""` | no |
| <a name="input_initialize_support_user"></a> [initialize\_support\_user](#input\_initialize\_support\_user) | enable support user initialization | `bool` | `true` | no |
| <a name="input_internal_agent_config"></a> [internal\_agent\_config](#input\_internal\_agent\_config) | Configuration for the internal agent. If disabled, no internal agent will be set up for this CP. | <pre>object({<br>    enable   = bool<br>    agent_id = string<br>  })</pre> | <pre>{<br>  "agent_id": "",<br>  "enable": false<br>}</pre> | no |
| <a name="input_internal_firewall_agent_config"></a> [internal\_firewall\_agent\_config](#input\_internal\_firewall\_agent\_config) | Configuration for the internal firewall agent. If disabled, no internal firewall agent will be set up for this CP. | <pre>object({<br>    enable   = bool<br>    agent_id = string<br>  })</pre> | <pre>{<br>  "agent_id": "",<br>  "enable": false<br>}</pre> | no |
| <a name="input_internal_lbs"></a> [internal\_lbs](#input\_internal\_lbs) | Whether or not the load balancers should be spun up as internal. | `bool` | `false` | no |
| <a name="input_ip_allowlist"></a> [ip\_allowlist](#input\_ip\_allowlist) | A set of CIDR routes to add to the allowlist for all ingresses. If not specified, all IP addresses are allowed. | `list(string)` | `[]` | no |
| <a name="input_isolate_namespace_traffic"></a> [isolate\_namespace\_traffic](#input\_isolate\_namespace\_traffic) | enable isolation of namespace pods and block all ingress from outside the namespace | `bool` | `false` | no |
| <a name="input_manage_namespace"></a> [manage\_namespace](#input\_manage\_namespace) | Whether or not to manage the namespace we are installing into.<br>  This will create the namespace(if applicable), setup docker credentials as a<br>  kubernetes secret etc. Turn this flag off if you have trouble connecting to<br>  k8s from your terraform environment. | `bool` | `true` | no |
| <a name="input_model_output_is_sensitive"></a> [model\_output\_is\_sensitive](#input\_model\_output\_is\_sensitive) | when true we consider customer LLM responses to be sensitive data | `bool` | `false` | no |
| <a name="input_mongo_db_size"></a> [mongo\_db\_size](#input\_mongo\_db\_size) | MongoDb volume size | `string` | `"32Gi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where the RIME Helm chart is to be installed. | `string` | n/a | yes |
| <a name="input_oidc_provider_url"></a> [oidc\_provider\_url](#input\_oidc\_provider\_url) | URL to the OIDC provider for IAM assumable roles used by K8s. | `string` | n/a | yes |
| <a name="input_openai_api_key"></a> [openai\_api\_key](#input\_openai\_api\_key) | The OpenAI API key to use for the RIME backend service. | `string` | `""` | no |
| <a name="input_override_values_file_path"></a> [override\_values\_file\_path](#input\_override\_values\_file\_path) | Optional file path to override values file for the rime helm release. | `string` | `""` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | helm release name | `string` | `"rime"` | no |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | A suffix to name the IAM policy and role with. | `string` | n/a | yes |
| <a name="input_rime_license"></a> [rime\_license](#input\_rime\_license) | Json Web Token containing Robust Intelligence license information. | `string` | `""` | no |
| <a name="input_rime_repository"></a> [rime\_repository](#input\_rime\_repository) | Repository URL where to locate the requested RIME chart for the given `rime_version`. | `string` | n/a | yes |
| <a name="input_rime_version"></a> [rime\_version](#input\_rime\_version) | The version of the RIME software to be installed. | `string` | n/a | yes |
| <a name="input_s3_license_enabled"></a> [s3\_license\_enabled](#input\_s3\_license\_enabled) | enable feature flag fetching jwt file from s3 | `bool` | `false` | no |
| <a name="input_separate_model_testing_group"></a> [separate\_model\_testing\_group](#input\_separate\_model\_testing\_group) | Whether to force model testing jobs to run on dedicated model-testing nodes, using NodeSelectors | `bool` | `true` | no |
| <a name="input_storage_class_name"></a> [storage\_class\_name](#input\_storage\_class\_name) | Name of storage class to use for persistent volumes | `string` | `"expandable-storage"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | n/a | yes |
| <a name="input_verbose"></a> [verbose](#input\_verbose) | Whether to use verbose mode for RIME application services. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_blob_store_bucket_arn"></a> [blob\_store\_bucket\_arn](#output\_blob\_store\_bucket\_arn) | n/a |
| <a name="output_blob_store_bucket_name"></a> [blob\_store\_bucket\_name](#output\_blob\_store\_bucket\_name) | n/a |
| <a name="output_dependency_link"></a> [dependency\_link](#output\_dependency\_link) | n/a |
<!-- END_TF_DOCS -->
