terraform {
  required_providers {
    cloudru = {
      source  = "cloud.ru/cloudru/cloud"
      version = "2.0.0"
    }
  }
}

provider "cloudru" {
  project_id  = var.project_id
  auth_key_id = var.auth_key_id
  auth_secret = var.auth_secret
  region      = "ru-central-1"

  endpoints = {
    iam_endpoint            = "iam.api.cloud.ru:443"
    compute_endpoint        = "compute.api.cloud.ru:443"
    baremetal_endpoint      = "baremetal.api.cloud.ru:443"
    mk8s_endpoint           = "mk8s.api.cloud.ru:443"
    vpc_endpoint            = "vpc.api.cloud.ru:443"
    magic_router_endpoint   = "magic-router.api.cloud.ru"
    dns_endpoint            = "dns.api.cloud.ru:443"
    nlb_endpoint            = "nlb.api.cloud.ru"
    kafka_endpoint          = "kafka.api.cloud.ru:443"
    redis_endpoint          = "redis.api.cloud.ru:443"
    object_storage_endpoint = "https://s3.cloud.ru"
  }
}

# ============================================================
#  Кластер (Control Plane)
# ============================================================
resource "cloudru_evolution_mk8s_cluster" "k8s" {
  name       = var.cluster_name
  project_id = var.project_id

  control_plane_version = var.control_plane_version

  identity_configuration {
    cluster_sa_id = var.cluster_sa_id
  }

  sizing_configuration {
    master_count = var.master_count
    flavor_id    = var.master_flavor_id
  }

  control_plane_zones = var.control_plane_zones

  network_configuration_request {
    network_plugin        = var.network_plugin
    private_vip_subnet_id = var.private_vip_subnet_id
    pods_subnet_cidr      = var.pods_subnet_cidr
    services_subnet_cidr  = var.services_subnet_cidr
    kube_api_internet     = var.kube_api_internet # публичный доступ к API
  }

  release_channel = var.release_channel

  logging_service {
    enabled      = var.logging_service_enabled
    log_group_id = var.logging_service_enabled ? var.log_group_id : null
  }

  monitoring_service {
    enabled = var.monitoring_service_enabled
  }

  audit_service {
    enabled = var.audit_service_enabled
  }

  key_management_service {
    enabled = var.key_management_service_enabled
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "20m"
  }
}

# ============================================================
#  Группа инфра-нод (4 vCPU, 8 GB RAM) с taint
# ============================================================
resource "cloudru_evolution_mk8s_node_pool" "infra" {
  cluster_id = cloudru_evolution_mk8s_cluster.k8s.id
  name       = "${var.cluster_name}-infra"

  machine_configuration_request {
    flavor_id = var.infra_node_flavor_id
    # disk можно не указывать, будет использоваться размер по умолчанию (10 ГБ)
  }

  scale_policy {
    fixed_scale {
      count = var.infra_node_count
    }
  }

  network_configuration_request {
    nodes_subnet_id = var.nodes_subnet_id
    # security_group_id можно не указывать — создастся автоматически
  }

  taints {
    taints {
      key    = "node-role"
      value  = "infra"
      effect = "NO_SCHEDULE"
    }
  }

  update_configuration {
    strategy = "ROLLING_UPDATE"
    rolling_update_policy {
      max_unavailable = 1
      max_surge       = 1
    }
  }

  timeouts {
    create = "20m"
    delete = "15m"
  }
}

# ============================================================
#  Группа воркер-нод (2 vCPU, 4 GB RAM) — без taint
# ============================================================
resource "cloudru_evolution_mk8s_node_pool" "workers" {
  cluster_id = cloudru_evolution_mk8s_cluster.k8s.id
  name       = "${var.cluster_name}-workers"

  machine_configuration_request {
    flavor_id = var.worker_node_flavor_id
  }

  scale_policy {
    fixed_scale {
      count = var.worker_node_count
    }
  }

  network_configuration_request {
    nodes_subnet_id = var.nodes_subnet_id
  }

  update_configuration {
    strategy = "ROLLING_UPDATE"
    rolling_update_policy {
      max_unavailable = 1
      max_surge       = 1
    }
  }

  timeouts {
    create = "20m"
    delete = "15m"
  }
}