locals {
  node_pools = {
    ri-worker-group = merge({
      name = "riworkers"

      vnet_subnet_id         = var.vnet_subnet_id
      vm_size                = var.server_node_pool_vm_size
      enable_host_encryption = true

      enable_auto_scaling = true
      min_count           = var.server_node_pool_min_size
      max_count           = var.server_node_pool_max_size
      node_count          = var.server_node_pool_desired_size

      tags = var.tags
    }, var.server_node_pool_overrides),
    ri-worker-group-model-testing = merge({
      name = "rimodeltesting"

      priority               = var.model_testing_node_pool_use_spot ? "Spot" : "Regular"
      spot_max_price         = -1
      vnet_subnet_id         = var.vnet_subnet_id
      vm_size                = var.model_testing_node_pool_vm_size
      enable_host_encryption = true

      enable_auto_scaling = true
      min_count           = var.model_testing_node_pool_min_size
      max_count           = var.model_testing_node_pool_max_size
      node_count          = var.model_testing_node_pool_desired_size

      labels = "dedicated=model-testing"
      taints = ["dedicated=model-testing:NoSchedule"]

      tags = var.tags
    }, var.model_testing_node_pool_overrides)
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = var.cluster_name
  kubernetes_version  = var.cluster_version
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.cluster_name}-dns"

  network_profile {
    network_plugin = "azure"
    service_cidr   = var.service_cidr
    dns_service_ip = cidrhost(var.service_cidr, 10)
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled               = true
  role_based_access_control_enabled = true
  workload_identity_enabled         = var.workload_identity_enabled

  private_cluster_enabled = var.private_cluster_enabled

  # Default node pool for system resources
  default_node_pool {
    name                         = local.node_pools.ri-worker-group["name"]
    vm_size                      = local.node_pools.ri-worker-group["vm_size"]
    enable_auto_scaling          = local.node_pools.ri-worker-group["enable_auto_scaling"]
    enable_host_encryption       = local.node_pools.ri-worker-group["enable_host_encryption"]
    enable_node_public_ip        = lookup(local.node_pools.ri-worker-group, "enable_node_public_ip", false)
    max_count                    = local.node_pools.ri-worker-group["max_count"]
    max_pods                     = lookup(local.node_pools.ri-worker-group, "max_pods", null)
    min_count                    = local.node_pools.ri-worker-group["min_count"]
    node_labels                  = lookup(local.node_pools.ri-worker-group, "labels", {})
    node_taints                  = lookup(local.node_pools.ri-worker-group, "taints", [])
    only_critical_addons_enabled = lookup(local.node_pools.ri-worker-group, "only_critical_addons_enabled", null)
    orchestrator_version         = lookup(local.node_pools.ri-worker-group, "orchestrator_version", null)
    os_disk_size_gb              = lookup(local.node_pools.ri-worker-group, "os_disk_size_gb", 50)
    os_disk_type                 = lookup(local.node_pools.ri-worker-group, "os_disk_type", null)
    os_sku                       = lookup(local.node_pools.ri-worker-group, "os_sku", null)
    pod_subnet_id                = lookup(local.node_pools.ri-worker-group, "pod_subnet_id", null)
    proximity_placement_group_id = lookup(local.node_pools.ri-worker-group, "proximity_placement_group_id", null)
    scale_down_mode              = lookup(local.node_pools.ri-worker-group, "scale_down_mode", null)
    tags                         = merge(var.tags, local.node_pools.ri-worker-group["tags"])
    temporary_name_for_rotation  = lookup(local.node_pools.ri-worker-group, "temporary_name_for_rotation", null)
    type                         = lookup(local.node_pools.ri-worker-group, "type", null)
    ultra_ssd_enabled            = lookup(local.node_pools.ri-worker-group, "ultra_ssd_enabled", null)
    vnet_subnet_id               = var.vnet_subnet_id
    zones                        = lookup(local.node_pools.ri-worker-group, "zones", null)

    dynamic "kubelet_config" {
      for_each = lookup(local.node_pools.ri-worker-group, "kubelet_config", {})

      content {
        allowed_unsafe_sysctls    = kubelet_config.value.allowed_unsafe_sysctls
        container_log_max_line    = kubelet_config.value.container_log_max_line
        container_log_max_size_mb = kubelet_config.value.container_log_max_size_mb
        cpu_cfs_quota_enabled     = kubelet_config.value.cpu_cfs_quota_enabled
        cpu_cfs_quota_period      = kubelet_config.value.cpu_cfs_quota_period
        cpu_manager_policy        = kubelet_config.value.cpu_manager_policy
        image_gc_high_threshold   = kubelet_config.value.image_gc_high_threshold
        image_gc_low_threshold    = kubelet_config.value.image_gc_low_threshold
        pod_max_pid               = kubelet_config.value.pod_max_pid
        topology_manager_policy   = kubelet_config.value.topology_manager_policy
      }
    }
    dynamic "linux_os_config" {
      for_each = lookup(local.node_pools.ri-worker-group, "linux_os_config", {})

      content {
        swap_file_size_mb             = linux_os_config.value.swap_file_size_mb
        transparent_huge_page_defrag  = linux_os_config.value.transparent_huge_page_defrag
        transparent_huge_page_enabled = linux_os_config.value.transparent_huge_page_enabled

        dynamic "sysctl_config" {
          for_each = linux_os_config.value.sysctl_configs == null ? [] : linux_os_config.value.sysctl_configs

          content {
            fs_aio_max_nr                      = sysctl_config.value.fs_aio_max_nr
            fs_file_max                        = sysctl_config.value.fs_file_max
            fs_inotify_max_user_watches        = sysctl_config.value.fs_inotify_max_user_watches
            fs_nr_open                         = sysctl_config.value.fs_nr_open
            kernel_threads_max                 = sysctl_config.value.kernel_threads_max
            net_core_netdev_max_backlog        = sysctl_config.value.net_core_netdev_max_backlog
            net_core_optmem_max                = sysctl_config.value.net_core_optmem_max
            net_core_rmem_default              = sysctl_config.value.net_core_rmem_default
            net_core_rmem_max                  = sysctl_config.value.net_core_rmem_max
            net_core_somaxconn                 = sysctl_config.value.net_core_somaxconn
            net_core_wmem_default              = sysctl_config.value.net_core_wmem_default
            net_core_wmem_max                  = sysctl_config.value.net_core_wmem_max
            net_ipv4_ip_local_port_range_max   = sysctl_config.value.net_ipv4_ip_local_port_range_max
            net_ipv4_ip_local_port_range_min   = sysctl_config.value.net_ipv4_ip_local_port_range_min
            net_ipv4_neigh_default_gc_thresh1  = sysctl_config.value.net_ipv4_neigh_default_gc_thresh1
            net_ipv4_neigh_default_gc_thresh2  = sysctl_config.value.net_ipv4_neigh_default_gc_thresh2
            net_ipv4_neigh_default_gc_thresh3  = sysctl_config.value.net_ipv4_neigh_default_gc_thresh3
            net_ipv4_tcp_fin_timeout           = sysctl_config.value.net_ipv4_tcp_fin_timeout
            net_ipv4_tcp_keepalive_intvl       = sysctl_config.value.net_ipv4_tcp_keepalive_intvl
            net_ipv4_tcp_keepalive_probes      = sysctl_config.value.net_ipv4_tcp_keepalive_probes
            net_ipv4_tcp_keepalive_time        = sysctl_config.value.net_ipv4_tcp_keepalive_time
            net_ipv4_tcp_max_syn_backlog       = sysctl_config.value.net_ipv4_tcp_max_syn_backlog
            net_ipv4_tcp_max_tw_buckets        = sysctl_config.value.net_ipv4_tcp_max_tw_buckets
            net_ipv4_tcp_tw_reuse              = sysctl_config.value.net_ipv4_tcp_tw_reuse
            net_netfilter_nf_conntrack_buckets = sysctl_config.value.net_netfilter_nf_conntrack_buckets
            net_netfilter_nf_conntrack_max     = sysctl_config.value.net_netfilter_nf_conntrack_max
            vm_max_map_count                   = sysctl_config.value.vm_max_map_count
            vm_swappiness                      = sysctl_config.value.vm_swappiness
            vm_vfs_cache_pressure              = sysctl_config.value.vm_vfs_cache_pressure
          }
        }
      }
    }
    dynamic "upgrade_settings" {
      for_each = lookup(local.node_pools.ri-worker-group, "max_surge", null) == null ? [] : ["upgrade_settings"]

      content {
        max_surge = local.node_pools.ri-worker-group["max_surge"]
      }
    }
  }

  tags = var.tags
}
