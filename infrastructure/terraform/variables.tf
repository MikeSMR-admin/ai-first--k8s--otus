# ============================================================
#  Обязательные переменные для провайдера
# ============================================================
variable "auth_key_id" {
  description = "Идентификатор ключа доступа"
  type        = string
  sensitive   = true
}

variable "auth_secret" {
  description = "Секретный ключ доступа"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "ID проекта в Cloud.ru"
  type        = string
  sensitive   = true
}

# ============================================================
#  Параметры кластера (обязательные)
# ============================================================
variable "cluster_name" {
  description = "Имя кластера (3–60 символов)"
  type        = string
}

variable "control_plane_version" {
  description = "Версия Kubernetes (например, v1.34.1)"
  type        = string
}

variable "cluster_sa_id" {
  description = "ID сервисного аккаунта для кластера (UUID)"
  type        = string
}

variable "master_count" {
  description = "Количество мастер-узлов (1 или 3+)"
  type        = number
  validation {
    condition     = var.master_count >= 1
    error_message = "master_count должен быть >= 1"
  }
}

variable "flavor_id" {
  description = "Flavor для мастер-узлов"
  type        = string
}

variable "control_plane_zones" {
  description = "Список зон доступности (например, ['ru-central1-a'])"
  type        = list(string)
}

# ============================================================
#  Сетевые параметры (обязательные)
# ============================================================
variable "network_plugin" {
  description = "CNI-плагин: cilium или calico"
  type        = string
  validation {
    condition     = contains(["cilium", "calico"], var.network_plugin)
    error_message = "Допустимо: cilium или calico"
  }
}

variable "private_vip_subnet_id" {
  description = "ID подсети для VIP (внутренний балансировщик)"
  type        = string
}

variable "pods_subnet_cidr" {
  description = "CIDR для подов"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_subnet_cidr" {
  description = "CIDR для сервисов"
  type        = string
  default     = "10.96.0.0/12"
}

# ============================================================
#  Опциональные параметры (доступность, сервисы)
# ============================================================
variable "release_channel" {
  description = "Канал обновлений"
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["RELEASE_CHANNEL_RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Допустимо: RELEASE_CHANNEL_RAPID, REGULAR, STABLE"
  }
}

variable "kube_api_internet" {
  description = "Публичный доступ к API-серверу"
  type        = bool
  default     = false
}

variable "logging_service_enabled" {
  description = "Включить централизованное логирование"
  type        = bool
  default     = false
}

variable "monitoring_service_enabled" {
  description = "Включить мониторинг (Prometheus/Grafana)"
  type        = bool
  default     = false
}

variable "audit_service_enabled" {
  description = "Включить аудит"
  type        = bool
  default     = false
}

variable "key_management_service_enabled" {
  description = "Включить шифрование с KMS"
  type        = bool
  default     = false
}

variable "log_group_id" {
  description = "ID группы логов (обязательно, если logging_service_enabled = true)"
  type        = string
  default     = ""
}

variable "log_group_region" {
  description = "Регион группы логов"
  type        = string
  default     = "ru-central-1"
}