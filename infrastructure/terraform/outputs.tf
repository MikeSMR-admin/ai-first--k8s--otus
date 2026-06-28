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
  description = "kubeconfig для доступа к кластеру (только если kube_api_internet = true)"
  value       = cloudru_evolution_mk8s_cluster.k8s.kube_config_raw
  sensitive   = true
}