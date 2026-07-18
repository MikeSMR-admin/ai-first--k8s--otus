# Kubernetes кластер на Cloud.ru (Terraform)

Этот каталог содержит Terraform конфигурацию для развертывания Kubernetes кластера в облаке Cloud.ru.

## Структура проекта

```
infrastructure/terraform/
├── main.tf               # Основная конфигурация ресурсов
├── variables.tf          # Определение переменных
├── outputs.tf            # Выходные значения
├── terraform.tfvars      # Значения переменных (содержит чувствительные данные)
├── .terraform.lock.hcl   # Блокировка версий провайдеров
└── terraform.tfstate     # Состояние инфраструктуры
```

## Требования

- Terraform v1.15.7+
- Учетные данные Cloud.ru (auth_key_id, auth_secret, project_id)
- Cloud.ru CLI (`cloudlogin`)

## Установка и настройка

### 1. Установка Terraform

Убедитесь, что Terraform установлен:

```bash
terraform version
```

### 2. Настройка доступа к Cloud.ru

#### Вариант A: Использование переменных окружения

```bash
export CLOUDRU_KEY_ID="ваш_key_id"
export CLOUDRU_SECRET_ID="ваш_secret_id"
```

#### Вариант B: Использование terraform.tfvars (не рекомендуется для продакшена)

Отредактируйте файл `terraform.tfvars` и укажите ваши credentials:

```hcl
auth_key_id  = "ваш_key_id"
auth_secret  = "ваш_secret"
project_id   = "ваш_project_id"
```

> ⚠️ **ВНИМАНИЕ**: Файл `terraform.tfvars` содержит чувствительные данные. Убедитесь, что он добавлен в `.gitignore`.

### 3. Инициализация Terraform

```bash
cd infrastructure/terraform
terraform init
```

### 4. Проверка конфигурации

```bash
terraform validate
```

### 5. Планирование развертывания

```bash
terraform plan
```

### 6. Применение изменений

```bash
terraform apply
```

Для автоматического подтверждения:

```bash
terraform apply -auto-approve
```

## Конфигурация кластера

### Node Pools

#### Инфра-ноды (infra)
- Роль: `node-role=infra`
- Taint: `EFFECT_NO_SCHEDULE`
- Назначение: Инфраструктурные компоненты (Ingress Controller, Monitoring, Logging)
- Конфигурация: 4 vCPU, 8 GB RAM

#### Воркер-ноды (workers)
- Роль: Приложения пользователей
- Taint: Отсутствуют
- Назначение: Запуск пользовательских приложений
- Конфигурация: 2 vCPU, 4 GB RAM

### Сетевая конфигурация

- CNI-плагин: Cilium
- CIDR для подов: `10.1.0.0/16`
- CIDR для сервисов: `10.96.0.0/12`
- Публичный доступ к API: Включен

## Управление кластером

### Просмотр состояния

```bash
terraform state list
terraform state show cloudru_evolution_mk8s_cluster.k8s
```

### Обновление конфигурации

1. Внесите изменения в файлы конфигурации
2. Выполните `terraform plan` для проверки изменений
3. Выполните `terraform apply` для применения изменений

### Удаление кластера

```bash
terraform destroy
```

Для автоматического подтверждения:

```bash
terraform destroy -auto-approve
```

## Подключение к кластеру

После развертывания кластера подключитесь с помощью `cloudlogin`:

```bash
cloudlogin kube config
kubectl cluster-info
kubectl get nodes
```

## Проверка развертывания

### Проверка узлов

```bash
kubectl get nodes
```

Ожидаемый вывод:

```
NAME                                      STATUS   ROLES    AGE   VERSION
vm-xxxxx                                  Ready    <none>   10m   v1.34.7
```

### Проверка node pools

```bash
kubectl get nodes -L node-role
```

## Troubleshooting

### Ошибка: quota_limit_exceeded

Если получаете ошибку превышения квот, проверьте использование ресурсов в консоли Cloud.ru и запросите увеличение квот.

### Ошибка: authentication failed

Убедитесь, что переменные окружения `CLOUDRU_KEY_ID` и `CLOUDRU_SECRET_ID` установлены корректно.

### Ошибка: subnet not found

Проверьте, что подсети (`private_vip_subnet_id`, `nodes_subnet_id`) существуют в указанной VPC.

## Дополнительная информация

- [Cloud.ru Documentation](https://cloud.ru/docs)
- [Terraform Provider for Cloud.ru](https://registry.terraform.io/providers/cloudru/cloudru/latest/docs)
- [Cloud.ru Managed Kubernetes](https://cloud.ru/services/managed_kubernetes.html)
