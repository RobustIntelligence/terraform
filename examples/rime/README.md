# Pattern 1: Application
This example contains a module to deploy the Robust Intelligence application into an existing EKS cluster. It is fully self-contained, with the exception of DNS configuration (an option exists to use AWS Route53 and ACM, but you are welcome to use your own provider).

Specific values have been annotated in-place in the `main.tf` files, and full coverage of a module's variables can be found in its README (e.g., [rime_helm_release](../../rime_helm_release/)).

---

## Prerequisites
1. Terraform with [backend configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration) (default uses [S3](https://aws.amazon.com/s3/), see "Terraform S3 Backend Configuration" below)
2. EKS Cluster x 1
    - Recommended: dedicated node group for model testing workloads
        - Taint: `dedicated=model-testing:NoSchedule`
        - (corresponding workload Tolerations can be specified via `separate_model_testing_group = true`)
    - (see [example from Pattern 2](../cluster_and_rime/) for standard EKS cluster specification)
3. DNS Provider (default configuration uses [route53](https://aws.amazon.com/route53/))
4. Secrets Provider (default configuration uses [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/))

<details>
<summary>Terraform S3 Backend Configuration</summary>

<br />

For the application module (`./backend.tf`):
```terraform
terraform {
  backend "s3" {
    region  = "<REGION>"
    bucket  = "rime-acme-tfstate"
    key     = "tfstates/rime/state-application.tfstate"
    encrypt = true
  }
}
```
</details>

## Note on Helm Release Modules
By default, each Helm release module (`*_helm_release`) will automatically install the Helm release; however, if you would like to install the release yourself, set `create_managed_helm_release = false`.

Additionally, all Helm values can be reconfigured using an overrides values.yaml file. To do so, specify values in a separate `values.yaml` file and indicate its path in the variable `override_values_file_path`.

The Robust Intelligence Helm Repository is viewable [here](https://github.com/RobustIntelligence/helm).

---

## Main Module
The full entrypoint template is viewable here: [`main.tf`](main.tf).

To deploy this module, run the following:
```bash
# in this directory
terraform init

terraform plan -out "rime-application.plan" | tee "rime-application-plan.txt"
less rime-application-plan.txt # proof-read the changes

terraform apply "rime-application.plan"
```

<details>
<summary><h3>Providers</h3></summary>

Be sure that the `aws` provider is correctly configured (at minimum, you'll need to specify your `region`).

Otherwise, you should not have to modify this section.

</details>

### Data Sources
1. **EKS Cluster**
    - Configure `cluster_name` in `locals` (see below) to specify your EKS Cluster.
2. [route53 Hosted Zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) (optional)
    - If using route53 for DNS resolution, be sure to specify the domain `name` in the provided section.
3. [AWS Secrets Manager Secret ID](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) (recommended)
    - By default, it's recommended to load your application secret in [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) to avoid specifying sensitive values in your Terraform configuration. See "Secrets Specification" below for the format of the secret.
4. `locals`
    - For convenience, shared variables are specified here. Must configure `cluster_name`, `rime_version` and `infra_name` at minimum.

<details>
<summary><b>Secrets Specification</b></summary>

The full secrets specification is listed below.

Note that in this sample template, only `rime_jwt`, `admin_username`, `admin_password`, and `docker-logins` are referenced; however, you are free to populate and reference additional values in your Terraform template as desired.

**Required Secrets**

- `rime_jwt`: Your RI product license (will be provided by your SA)
- `admin_username`: Email address of your main Administrator account
- `admin_password`: One-time password of your main Administrator account (will be reset on first login)
- `docker-logins`: Read credentials for the RI private container registry (will be provided by your SA)

**Optional Secrets**

- `oauth_client_id`, `oauth_client_secret`, and `oauth_well_known_url`: OIDC configuration for single sign-on
    - (search "SSO" at https://docs.rime.dev/)
- `smtp_email`, `smtp_password`, `smtp_server`, and `smtp_port`: SMTP configuration for email notifications
    - (search "Notifications" at https://docs.rime.dev/)
- `datadog-api-key` and `rime-user`: DataDog API Key (will be provided by your SA) and user tag for log filtering

```json
{
  "rime_jwt": "",
  "admin_username": "",
  "admin_password": "",
  "docker-logins": [
   {
     "docker-server": "",
     "docker-username": "",
     "docker-password": ""
   }
 ],
  "oauth_client_id": "",
  "oauth_client_secret": "",
  "oauth_well_known_url": "",
  "smtp_email": "",
  "smtp_password": "",
  "smtp_server": "",
  "smtp_port": "",
  "datadog-api-key": "",
  "rime-user": ""
}
```

</details>

### Submodules
#### `rime_helm_release`
This module creates a Helm release for the `rime` Helm chart. For more details on the underlying Helm chart, see the [Robust Intelligence Helm Repository](https://github.com/RobustIntelligence/helm).

For a full list of the possible values, see [rime_helm_release](../../rime_helm_release/).

1. Configure domain and ACM certificate.
    - `domain`: Your application domain (e.g., `acme.com`)
        - NOTE: By default, the application domain will take the form `rime.DOMAIN` (use Helm value overrides to modify this, if necessary).
    - `acm_cert_arn`: ARN for the ACM certificate used to validate the domain.
        - If using the `rime_acm_certs` module (see below), this should be autopopulated using `module.rime_acm_certs.acm_cert_arn`.
2. Configure the default Blob Storage.
    - `enable_blob_store`: Whether to create an S3 bucket with read and write access for the application. Note that this is only the default data source for the application (useful for validation), and more data sources can be integrated through the application.
3. Configure the Managed Images feature.
    - `image_registry_config.enable`: Whether to enable the feature.
    - `image_registry_config.repo_base_name`: A prefix to help identify ECR repositories managed by this feature.

#### `rime_agent_release`
This module creates a Helm release for the `rime-agent` Helm chart. For more details on the underlying Helm chart, see the [Robust Intelligence Helm Repository](https://github.com/RobustIntelligence/helm).

For a full list of the possible values, see [rime_agent](../../rime_agent/).

1. Configure the agent's access to S3 buckets (_read-only_ permissions).
    - `s3_authorized_bucket_path_arns`: A list of ARNs of the relevant S3 bucket(s).
        - By default, the S3 bucket created as part of the `rime_helm_release` module (see above) should be in this list.

#### `rime_acm_certs` (optional)
If using route53 for DNS, this module can automatically create and manage a TLS certificate for your domain via [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/).

1. Specify the `domain` you've configured in route53.
    - `domain`: Your application domain (e.g., `*.acme.com` or just `rime.acme.com`), to be used as the Common Name (CN) on the certificate.

---

## License

Copyright &copy; 2023 Robust Intelligence

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.

You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
