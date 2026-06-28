output "cluster_id" {
  description = "ID кластера"
  value       = cloudru_evolution_mk8s_cluster.k8s.id
}

output "cluster_name" {
  description = "Имя кластера"
  value       = cloudru_evolution_mk8s_cluster.k8s.name
}

output "cluster_status" {
  description = "Текущий статус кластера"
  value       = cloudru_evolution_mk8s_cluster.k8s.status
}

output "api_endpoint" {
  description = "Публичный или приватный эндпоинт API-сервера"
  value       = cloudru_evolution_mk8s_cluster.k8s.api_server_endpoint
}

output "kubeconfig" {
  description = "kubeconfig для доступа к кластеру"
  value       = cloudru_evolution_mk8s_cluster.k8s.kube_config_raw
  sensitive   = true
}

output "infra_node_group_id" {
  description = "ID группы инфра-нод"
  value       = cloudru_evolution_mk8s_node_group.infra.id
}

output "worker_node_group_id" {
  description = "ID группы воркер-нод"
  value       = cloudru_evolution_mk8s_node_group.workers.id
}