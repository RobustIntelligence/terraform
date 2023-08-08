# Robust Intelligence Terraform Modules
<picture>
 <source srcset="https://assets-global.website-files.com/62a7e9e01c9610dd11622fc6/62a8d4255468bd5859438043_logo-ri-white.svg">
 <img alt="Robust Intelligence Logo" src="YOUR-DEFAULT-IMAGE">
</picture>

<br />
<br />

The `rime` Terraform module creates all necessary resources for a Robust Intelligence K8s cluster.
Currently only AWS (EKS) is supported; however, active development for other major cloud providers is underway.

There are **six** submodules contained within:

#### Cluster
- [`rime_eks_cluster`](rime_eks_cluster/README.md)
    - The underlying EKS cluster and its associated resources.
- [`rime_kube_system_helm_release`](rime_kube_system_helm_release/README.md)
    - Select K8s services and CRDs for managing infrastructure.
- [`rime_extras_helm_release`](rime_extras_helm_release/README.md) (recommended)
    - Add-on services for backups and observability.

#### Application
- [`rime_helm_release`](rime_helm_release/README.md)
    - For deploying the core `rime` Helm chart and its necessary resources.
- [`rime_agent`](rime_agent/README.md)
    - For deploying the `rime-agent` Helm chart and its necessary resources.
- [`rime_acm_certs`](rime_acm_certs/README.md) (optional)
    - If using route53 for DNS, this module will create and validate an ACM certificate for your domain.

<!--- Uncomment this when the GCP Terraform modules are released. -->
<!--- - [`google_artifact_registry` -->
<!---     - Google Artifact Registry](https://cloud.google.com/artifact-registry/) configuration for the Managed Images feature -->

Detailed READMEs for each submodule are in the subfolders.

**For details of the underlying Helm charts used by these modules, see the [Robust Intelligence Helm Repository](https://github.com/RobustIntelligence/helm).**

# Usage

We provide standard usage patterns in the `examples/` directory of this repository.

### Pattern 1: Application only
In one module, deploy Robust Intelligence into a dedicated namespace of an existing Kubernetes cluster.
Note that this requires you to provide your own bootstrapped Kubernetes cluster (see [rime_eks_cluster](#rime_eks_cluster) and [rime_kube_system_helm_release](#rime_kube_system_helm_release) below for details).

**A template for this example is available at [`examples/rime`](examples/rime/).**

### Pattern 2: Cluster + Application
In one module, deploy a bootstrapped EKS cluster, and in a second module, deploy Robust Intelligence into a dedicated namespace.
This usage pattern is fully self-contained --- all Robust Intelligence dependencies can be handled with the provided modules.

**A template for this example is available at [`examples/cluster_and_rime`](examples/cluster_and_rime/).**

---

## Submodules

### `rime_eks_cluster`
Provisions an EKS cluster in the specified VPC and subnets, with [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) enabled.
Compute resources can be [Managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) or [Self-managed nodes](https://docs.aws.amazon.com/eks/latest/userguide/worker.html).

For more information on the `eks` Terraform module, please see the [module documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/17.24.0).

### `rime_kube_system_helm_release`
Creates a Helm release for supporting infrastructure services using the `rime-kube-system` [Helm chart](https://github.com/RobustIntelligence/helm).

Provisions the following K8s services for managing infrastructure:
- [Kubernetes Cluster Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html)
- [External DNS](https://github.com/kubernetes-sigs/external-dns)
- [Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
- [Metrics Server](https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html)
- [cert-manager](https://cert-manager.io/docs/)

These services are optional; however, they are strongly recommended (and in some cases, required).
Robust Intelligence cannot guarantee the same SLAs when omitting or replacing these services.

### `rime_extras_helm_release` (recommended)
Creates a Helm release for add-on external services using the `rime-extras` [Helm chart](https://github.com/RobustIntelligence/helm).

Provisions the following K8s services for additional functionality:
- [Datadog Agent](https://docs.datadoghq.com/agent/) (monitoring)
- [Velero](https://velero.io/) (disaster recovery)

These services are optional; however they are strongly recommended to optimize product experience.

### `rime_helm_release`
Creates a Helm release for the control plane using the `rime` [Helm chart](https://github.com/RobustIntelligence/helm).

Your Robust Intelligence representative will help you determine what configurations to use.

### `rime_agent`
Creates a Helm release for the data plane agent using the `rime-agent` [Helm chart](https://github.com/RobustIntelligence/helm).

Your Robust Intelligence representative will help you determine what configurations to use.

### `rime_acm_certs` (optional)
If using route53 for DNS, this module will create and validate an ACM certificate for your domain.

---

## License

Copyright &copy; 2023 Robust Intelligence

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.

You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
