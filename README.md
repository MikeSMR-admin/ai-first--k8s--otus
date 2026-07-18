# AI First Kubernetes Solution - Проект Otus

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Kubernetes](https://img.shields.io/badge/kubernetes-v1.34-blue.svg)](https://kubernetes.io)
[![Terraform](https://img.shields.io/badge/Terraform-v1.15-blue.svg)](https://www.terraform.io)

## 📦 Репозиторий

Этот проект хранится в публичном репозитории: [https://github.com/MikeSMR-admin/ai-first--k8s--otus.git](https://github.com/MikeSMR-admin/ai-first--k8s--otus.git). Код проекта доступен в ветке main.

## 📋 Содержание

- [Обзор](#обзор)
- [Архитектура](#архитектура)
- [Требования](#требования)
- [Структура проекта](#структура-проекта)
- [Установка](#установка)
- [Использование](#использование)
- [Мониторинг и логирование](#мониторинг-и-логирование)
- [Очистка](#очистка)
- [Устранение неполадок](#устранение-неполадок)
- [Вклад в проект](#вклад-в-проект)
- [Лицензия](#лицензия)

## 📖 Обзор

Этот проект демонстрирует готовую к продакшену инфраструктуру Kubernetes со следующими компонентами:

- **Кластер Kubernetes**: Управляемый Kubernetes на Cloud.ru с отдельными группами узлов для различных workload-ов
- **Инфраструктурные сервисы**: Встроенные сервисы мониторинга и логирования Cloud.ru
- **Пример приложения**: Online Boutique — микросервисное приложение для электронной коммерции
- **Метод развертывания**: Helm-чарты для развертывания приложения

### Основные возможности

- ✅ Развертывание инфраструктуры на основе Terraform
- ✅ Разделенные группы узлов (master, infra, workers)
- ✅ Cilium CNI для сетевого взаимодействия
- ✅ Развертывание приложения через Helm
- ✅ Встроенные сервисы мониторинга и логирования Cloud.ru
- ✅ Безопасное управление конфигурацией

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloud.ru VPC                              │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Kubernetes Cluster                        │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  Control Plane (Master Node)                    │  │  │
│  │  │  - API Server, Scheduler, Controller Manager    │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                        │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  Группа узлов: Infra (node-role=infra)          │  │  │
│  │  │  - Taint: EFFECT_NO_SCHEDULE                     │  │  │
│  │  │  - 2 узла, 4 vCPU, 8 GB RAM                      │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                        │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  Группа узлов: Workers (без taint)              │  │  │
│  │  │  - 3 узла, 2 vCPU, 4 GB RAM                      │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Сервисы Cloud.ru                                      │  │
│  │  - Мониторинг (Prometheus/Grafana)                   │  │
│  │  - Служба логирования                                 │  │
│  │  - VPC сеть с CNI Cilium                             │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Конфигурация групп узлов

| Группа | Роль | Узлы | vCPU | RAM | Taint |
|--------|------|------|------|-----|-------|
| Master | Control Plane | 1 | 4 | 8 GB | Только системные |
| Infra | Инфраструктурн��е сервисы | 2 | 4 | 8 GB | node-role=infra |
| Workers | Пользовательские приложения | 3 | 2 | 4 GB | Нет |

## ✅ Требования

### Необходимые инструменты

- [Terraform](https://www.terraform.io/downloads.html) v1.15.7+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.34+
- [Helm](https://helm.sh/docs/intro/install/) v3.8+
- [Cloud.ru CLI](https://cloud.ru/docs) (для получения kubeconfig)

### Настройка Cloud.ru

1. **Создайте аккаунт Cloud.ru** на [cloud.ru](https://cloud.ru)

2. **Создайте учетные данные API**:
   - Перейдите в [Консоль Cloud.ru](https://cloud.ru)
   - Перейдите в IAM → Keys (Ключи)
   - Создайте новый ключ для доступа Terraform

3. **Создайте сервисный аккаунт** для кластера Kubernetes:
   - Перейдите в IAM → Service Accounts (Сервисные аккаунты)
   - Создайте новый сервисный аккаунт
   - Назначьте необходимые роли (MK8S Admin, VPC Admin)

4. **Настройте сетевую инфраструктуру VPC**:
   - Создайте VPC с публичными и приватными подсетями
   - Запишите ID подсетей для конфигурации Terraform

### Конфигурация Terraform

Создайте файл `terraform.tfvars` в `infrastructure/terraform/`:

```hcl
auth_key_id      = "ваш_auth_key_id"
auth_secret      = "ваш_auth_secret"
project_id       = "ваш_project_id"

cluster_name              = "production-cluster"
control_plane_version     = "v1.34.1"
cluster_sa_id             = "ваш_service_account_id"
master_count              = 1
master_flavor_id          = "ваш_master_flavor_id"

infra_node_flavor_id      = "ваш_infra_flavor_id"
infra_node_count          = 2
worker_node_flavor_id     = "ваш_worker_flavor_id"
worker_node_count         = 3

private_vip_subnet_id     = "ваш_vip_subnet_id"
nodes_subnet_id           = "ваш_nodes_subnet_id"
pods_subnet_cidr          = "10.1.0.0/16"
services_subnet_cidr      = "10.96.0.0/12"

monitoring_service_enabled = true
logging_service_enabled    = true
log_group_id              = "ваш_log_group_id"
```

## 📁 Структура проекта

```
ai-first--k8s--otus/
├── infrastructure/
│   └── terraform/              # Конфигурация Terraform
│       ├── main.tf            # Основные определения ресурсов
│       ├── variables.tf       # Входные переменные
│       ├── outputs.tf         # Выходные значения
│       ├── env-example        # Пример окружения (не для продакшена)
│       ├── .terraform.lock.hcl # Файл блокировки провайдеров
│       └── README.md          # Документация Terraform
├── demo-apps/
│   ├── helm-chart/            # Helm-чарт для Online Boutique
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── templates/
│   │   └── README.md
│   └── kubernetes-manifests/  # Сырые манифесты Kubernetes
│       ├── kustomization.yaml
│       ├── adservice.yaml
│       ├── cartservice.yaml
│       └── ...
├── kubernetes/                # Оверлеи Kubernetes (если есть)
├── scripts/                   # Скрипты развертывания
│   └── install-osconfig.ps1   # Установка агента osconfig
├── docs/                      # Документация (опционально)
├── README.md                  # Этот файл
└── CHANGELOG.md               # Журнал изменений
```

## 🚀 Установка

### Шаг 1: Развертывание кластера Kubernetes с помощью Terraform

```bash
# Перейдите в директорию Terraform
cd infrastructure/terraform

# Инициализируйте Terraform
terraform init

# Валидируйте конфигурацию
terraform validate

# Запланируйте развертывание
terraform plan

# Примените конфигурацию
terraform apply
```

### Шаг 2: Настройка kubectl

```bash
# Получите kubeconfig с помощью Cloud.ru CLI
cloudlogin kube config

# Проверьте подключение
kubectl cluster-info
kubectl get nodes
```

### Шаг 3: Развертывание Online Boutique с помощью Helm

```bash
# Перейдите в директорию demo-apps
cd ../demo-apps/helm-chart

# Добавьте репозиторий чарта Online Boutique
helm repo add onlineboutique https://googlecloudplatform.github.io/microservices-demo/

# Создайте пространство имен
kubectl create namespace online-boutique

# Установите Online Boutique
helm install onlineboutique onlineboutique/onlineboutique \
    --namespace online-boutique \
    --create-namespace \
    --wait

# Или используйте локальный чарт
helm install onlineboutique . \
    --namespace online-boutique \
    --create-namespace \
    --wait
```

### Шаг 4: Проверка развертывания

```bash
# Проверьте статус подов
kubectl get pods -n online-boutique

# Проверьте сервисы
kubectl get services -n online-boutique
```

## 🎯 Использование

### Доступ к приложению

После развертывания приложение Online Boutique будет доступно из браузера по адресу:

🌐 **http://demoxy.ru/**

> **Примечание**: Для доступа по доменному имени необходимо настроить Ingress-контроллер (например, nginx-ingress или встроенный от Cloud.ru) и DNS-запись для домена demoxy.ru. Требуется создать A-запись, указывающую на публичный IP-адрес Ingress-контроллера.

### Общие операции

```bash
# Просмотр всех подов
kubectl get pods -n online-boutique

# Просмотр логов
kubectl logs -n online-boutique -l app=frontend -f

# Масштабирование развертывания
kubectl scale deployment frontend -n online-boutique --replicas=3

# Обновление конфигурации
helm upgrade onlineboutique onlineboutique/onlineboutique \
    --namespace online-boutique \
    --set frontend.replicaCount=3
```

### Доступные сервисы

| Сервис | Порт | Описание |
|--------|------|----------|
| frontend | 80 | Веб-интерфейс |
| adservice | 9555 | Сервис рекламы |
| cartservice | 7070 | Сервис корзины покупок |
| checkoutservice | 5050 | Сервис оформления заказа |
| currencyservice | 7000 | Сервис конвертации валют |
| emailservice | 8080 | Сервис email |
| paymentservice | 50051 | Сервис оплаты |
| productcatalogservice | 3550 | Сервис каталога товаров |
| recommendationservice | 8080 | Сервис рекомендаций |
| shippingservice | 50051 | Сервис доставки |

## 📊 Мониторинг и логирование

### Встроенные сервисы Cloud.ru

Этот проект использует встроенные сервисы мониторинга и логирования Cloud.ru:

#### Мониторинг
- **Сервис**: Мониторинг Cloud.ru
- **Функции**:
  - Метрики CPU и памяти
  - Мониторинг сетевого трафика
  - Пользовательские алерты
  - Дашборды Grafana (если включено)

#### Логирование
- **Сервис**: Служба логирования Cloud.ru
- **Функции**:
  - Централизованный сбор логов
  - Поиск и фильтрация логов
  - Политики хранения логов
  - Интеграция с мониторингом

### Доступ к мониторингу

1. Перейдите в Консоль Cloud.ru
2. Перейдите к вашему кластеру Kubernetes
3. Нажмите на вкладку "Мониторинг"
4. Просмотрите метрики и настройте алерты

### Доступ к логам

1. Перейдите в Консоль Cloud.ru
2. Перейдите к вашему кластеру Kubernetes
3. Нажмите на вкладку "Логирование"
4. Выполните поиск и фильтрацию логов

## 🧹 Очистка

### Удаление приложения

```bash
# Удалите Helm-чарт
helm uninstall onlineboutique -n online-boutique

# Удалите пространство имен
kubectl delete namespace online-boutique
```

### Удаление кластера Kubernetes

```bash
# Перейдите в директорию Terraform
cd infrastructure/terraform

# Уничтожьте все ресурсы
terraform destroy

# Подтвердите вводом 'yes'
```

### Очистка локальных файлов

```bash
# Удалите состояние Terraform
rm -rf .terraform/
rm -rf .terraform.lock.hcl
rm -rf terraform.tfstate
rm -rf terraform.tfstate.backup
```

## 🔧 Устранение неполадок

### Распространенные проблемы

#### Проблемы Terraform

**Ошибка: authentication failed**
- Убедитесь, что `auth_key_id` и `auth_secret` верны
- Проверьте, что сервисный аккаунт имеет необходимые права

**Ошибка: quota_limit_exceeded**
- Запросите увеличение квот в Консоли Cloud.ru
- Уменьшите количество узлов в `terraform.tfvars`

**Ошибка: subnet not found**
- Проверьте ID подсетей в `terraform.tfvars`
- Убедитесь, что подсети существуют в той же VPC

#### Проблемы Kubernetes

**Поды зависли в состоянии Pending**
```bash
# Проверьте статус узлов
kubectl get nodes

# Проверьте проблемы с планированием
kubectl describe pod <имя-пода> -n online-boutique
```

**Сервисы недоступны**
```bash
# Проверьте эндпоинты сервисов
kubectl get endpoints -n online-boutique

# Проверьте детали сервиса
kubectl describe service frontend -n online-boutique
```

**Установка Helm не удалась**
```bash
# Проверьте статус релиза Helm
helm list -n online-boutique

# Проверьте историю Helm
helm history onlineboutique -n online-boutique

# Откатите при необходимости
helm rollback onlineboutique -n online-boutique
```

### Логи и диагностика

```bash
# Проверьте события кластера
kubectl get events -n online-boutique --sort-by='.lastTimestamp'

# Проверьте логи подов
kubectl logs -n online-boutique -l app=frontend --tail=100 -f

# Проверьте состояния узлов
kubectl describe nodes
```

## 🤝 Вклад в проект

Вклад приветствуется! Пожалуйста, следуйте этим шагам:

1. Сделайте форк репозитория
2. Создайте ветку функции (`git checkout -b feature/amazing-feature`)
3. Закоммитьте изменения (`git commit -m 'Добавить amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

### Руководство по разработке

- Следуйте best practices Kubernetes
- Используйте правильные соглашения об именах
- Документируйте все изменения
- Тщательно тестируйте перед слиянием

## 📄 Лицензия

Этот проект лицензирован по лицензии Apache 2.0 - см. файл [LICENSE](LICENSE) для подробной информации.

## 📞 Поддержка

Для поддержки откройте issue в репозитории GitHub или свяжитесь с мейнтейнерами.

---

*Этот проект создан в рамках курса Otus AI First Kubernetes.*
