resource "cloudru_evolution_mk8s_cluster" "resource_cluster" {
  name       = "cloudru-example-cluster"
  project_id = "00000000-0000-0000-0000-000000000000"

  logging_service = {
    enabled      = true
    log_group_id = "00000000-0000-0000-0000-000000000000"
  }

  monitoring_service = {
    enabled = true
  }
  # Варианты значений параметра release_channel:
  # RELEASE_CHANNEL_RAPID, RELEASE_CHANNEL_REGULAR, RELEASE_CHANNEL_STABLE
  release_channel = "RELEASE_CHANNEL_REGULAR"

  audit_service = {
    enabled = true
  }

  identity_configuration = {
    cluster_sa_id = "00000000-0000-0000-0000-000000000000"
  }

  key_management_service = {
    enabled = true
    kek_id  = "00000000-0000-0000-0000-000000000000"
  }
  control_plane_zones   = ["00000000-0000-0000-0000-000000000000"]
  control_plane_version = "v1.34.1"

  sizing_configuration = {
    master_count = 1
    flavor_id    = "00000000-0000-0000-0000-000000000000"
  }

  network_configuration_request = {
    services_subnet_cidr = "10.96.0.0/12"
    pods_subnet_cidr     = "10.1.0.0/16"
    kube_api_internet    = true

    network_plugin = {
      # Нужно заполнить одно из значений - cilium, calico.

      cilium = {
        enabled = true
        # Нужно заполнить одно из значений - version, app_version.
        version     = "1.16.7-sbc.3"
        app_version = "v1.16.7"
      }

      calico = {
        enabled = true
        # Нужно заполнить одно из значений - version, app_version.
        version     = "3.29.3-sbc.1"
        app_version = "v3.29.3"
      }
    }
    private_vip_subnet_id = "00000000-0000-0000-0000-000000000000"
  }

  bootstrap_managed_addons = {
    horizontal_pod_autoscaling = {
      enabled = true
    }

    persistent_disk_csi_driver = {
      enabled = true
    }

    kube_proxy = {
      enabled = true
    }

    coredns = {
      enabled = true
    }
  }
}