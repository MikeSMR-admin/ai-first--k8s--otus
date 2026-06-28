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
    iam_endpoint           = "iam.api.cloud.ru:443"
    compute_endpoint       = "compute.api.cloud.ru:443"
    baremetal_endpoint     = "baremetal.api.cloud.ru:443"
    mk8s_endpoint          = "mk8s.api.cloud.ru:443"
    vpc_endpoint           = "vpc.api.cloud.ru:443"
    magic_router_endpoint  = "magic-router.api.cloud.ru"
    dns_endpoint           = "dns.api.cloud.ru:443"
    nlb_endpoint           = "nlb.api.cloud.ru"
    kafka_endpoint         = "kafka.api.cloud.ru:443"
    redis_endpoint         = "redis.api.cloud.ru:443"
    object_storage_endpoint = "https://s3.cloud.ru"
  }
}

# ============================================================
#  Кластер (Control Plane)
# ============================================================
resource "cloudru_evolution_mk8s_cluster" "k8s" {
  name        = var.cluster_name
  project_id  = var.project_id

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
  }

  release_channel   = var.release_channel
  kube_api_internet = var.kube_api_internet

  logging_service {
    enabled = var.logging_service_enabled
    log_group_id     = var.logging_service_enabled ? var.log_group_id : null
    log_group_region = var.logging_service_enabled ? var.log_group_region : null
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
resource "cloudru_evolution_mk8s_node_group" "infra" {
  cluster_id = cloudru_evolution_mk8s_cluster.k8s.id
  project_id = var.project_id

  name       = "${var.cluster_name}-infra"
  flavor_id  = var.infra_node_flavor_id
  node_count = var.infra_node_count

  # Taint для предотвращения размещения обычных подов
  taints {
    key    = "node-role"
    value  = "infra"
    effect = "NoSchedule"
  }

  # Опционально: можно добавить labels для идентификации
  # labels = {
  #   "node-role.kubernetes.io/infra" = "true"
  # }

  timeouts {
    create = "20m"
    delete = "15m"
  }
}

# ============================================================
#  Группа воркер-нод (2 vCPU, 4 GB RAM)
# ============================================================
resource "cloudru_evolution_mk8s_node_group" "workers" {
  cluster_id = cloudru_evolution_mk8s_cluster.k8s.id
  project_id = var.project_id

  name       = "${var.cluster_name}-workers"
  flavor_id  = var.worker_node_flavor_id
  node_count = var.worker_node_count

  # Воркер-ноды без taint — обычные поды будут размещаться здесь

  timeouts {
    create = "20m"
    delete = "15m"
  }
}