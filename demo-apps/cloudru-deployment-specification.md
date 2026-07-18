# Спецификация развертывания микросервисного приложения Online Boutique в mk8s на cloud.ru

## 1. Введение

Данная спецификация описывает развертывание приложения **Online Boutique** - микросервисного e-commerce приложения, в кластере managed Kubernetes (mk8s) на платформе cloud.ru.

### 1.1 Обзор приложения

Online Boutique - это cloud-first микросервисное приложение, представляющее собой веб-платформу электронной коммерции, где пользователи могут просматривать товары, добавлять их в корзину и совершать покупки.

### 1.2 Архитектура приложения

Приложение состоит из 11 микросервисов, взаимодействующих через gRPC:

| Сервис | Язык | Описание | Порт |
|--------|------|----------|------|
| frontend | Go | HTTP-сервер для веб-интерфейса | 8080 |
| cartservice | C# | Хранение корзины в Redis | 7070 |
| productcatalogservice | Go | Каталог товаров | 3550 |
| currencyservice | Node.js | Конвертация валют | 7000 |
| paymentservice | Node.js | Обработка платежей | 50051 |
| shippingservice | Go | Расчет доставки | 50051 |
| emailservice | Python | Уведомления по email | 5000 |
| checkoutservice | Go | Оформление заказов | 5050 |
| recommendationservice | Python | Рекомендации товаров | 8080 |
| adservice | Java | Рекламные объявления | 9555 |
| loadgenerator | Python | Генерация нагрузки | - |

### 1.3 Компоненты инфраструктуры

- **redis-cart** - Redis-кэш для хранения корзин пользователей (встроенный)

## 2. Требования к инфраструктуре cloud.ru mk8s

### 2.1 Предварительные требования

- Кластер mk8s на cloud.ru уже развернут и настроен
- Поды имеют выход в интернет
- kubectl сконфигурирован для работы с кластером
- HELM чарт установлен

### 2.2 Рекомендуемые настройки кластера

- **Количество узлов**: минимум 3 узла (для HA)
- **Конфигурация узлов**: 
  - CPU: 4 vCPU
  - Memory: 8 GB RAM
  - Disk: 50 GB SSD
- **Сетевые настройки**:
  - Включенный CNI плагин (Cillium)
  - Внешний IP для LoadBalancer сервисов
  - Network Policies (опционально)
  - настроенный SNAT 

### 2.3 Ресурсные требования сервисов

| Сервис | CPU Request | CPU Limit | Memory Request | Memory Limit |
|--------|-------------|-----------|----------------|--------------|
| frontend | 100m | 200m | 64Mi | 128Mi |
| cartservice | 200m | 300m | 64Mi | 128Mi |
| productcatalogservice | 100m | 200m | 64Mi | 128Mi |
| currencyservice | 100m | 200m | 64Mi | 128Mi |
| paymentservice | 100m | 200m | 64Mi | 128Mi |
| shippingservice | 100m | 200m | 64Mi | 128Mi |
| emailservice | 100m | 200m | 64Mi | 128Mi |
| checkoutservice | 100m | 200m | 64Mi | 128Mi |
| recommendationservice | 100m | 200m | 220Mi | 450Mi |
| adservice | 200m | 300m | 180Mi | 300Mi |
| loadgenerator | 300m | 500m | 256Mi | 512Mi |
| redis-cart | 70m | 125m | 200Mi | 256Mi |

**Общая потребность в ресурсах (минимальная):**
- CPU: ~1.6 vCPU
- Memory: ~1.9 GB

## 3. Порядок развертывания

### 3.1 Подготовка

```bash
# Проверка подключения к кластеру
kubectl cluster-info

# Создание namespace для приложения
kubectl create namespace online-boutique
```

### 3.2 Развертывание Redis (StatefulSet)

```bash
# Применение ма��ифестов для Redis
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-cart
  namespace: online-boutique
spec:
  serviceName: redis-cart
  replicas: 1
  selector:
    matchLabels:
      app: redis-cart
  template:
    metadata:
      labels:
        app: redis-cart
    spec:
      containers:
      - name: redis
        image: redis:alpine@sha256:9d317178eceac8454a2284a9e6df2466b93c745529947f0cd42a0fa9609d7005
        ports:
        - containerPort: 6379
        resources:
          requests:
            cpu: 70m
            memory: 200Mi
          limits:
            cpu: 125m
            memory: 256Mi
        volumeMounts:
        - name: redis-data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cart
  namespace: online-boutique
spec:
  type: ClusterIP
  selector:
    app: redis-cart
  ports:
  - name: tcp-redis
    port: 6379
    targetPort: 6379
EOF
```

### 3.3 Развертывание микросервисов

#### 3.3.1 Сервисы с базовыми зависимостями

```bash
# Применение манифестов для всех сервисов
kubectl apply -f ./release/kubernetes-manifests.yaml -n online-boutique
```

Или пошаговое развертывание:

```bash
# 1. Сервисы без внешних зависимостей
kubectl apply -f kubernetes-manifests/productcatalogservice.yaml -n online-boutique
kubectl apply -f kubernetes-manifests/currencyservice.yaml -n online-boutique
kubectl apply -f kubernetes-manifests/shippingservice.yaml -n online-boutique
kubectl apply -f kubernetes-manifests/emailservice.yaml -n online-boutique
kubectl apply -f kubernetes-manifests/paymentservice.yaml -n online-boutique

# 2. Сервисы с зависимостями
kubectl apply -f kubernetes-manifests/recommendationservice.yaml -n online-boutique
kubectl apply -f kubernetes-manifests/adservice.yaml -n online-boutique

# 3. Сервисы с Redis
kubectl apply -f kubernetes-manifests/cartservice.yaml -n online-boutique

# 4. Главный сервис
kubectl apply -f kubernetes-manifests/checkoutservice.yaml -n online-boutique
kubectl apply -f kubernetes-manifests/frontend.yaml -n online-boutique

# 5. Генератор нагрузки (опционально)
kubectl apply -f kubernetes-manifests/loadgenerator.yaml -n online-boutique
```

### 3.4 Ожидание готовности подов

```bash
# Ожидание готовности всех подов
kubectl wait --for=condition=ready pods --all -n online-boutique --timeout=300s

# Проверка статуса подов
kubectl get pods -n online-boutique

# Проверка сервисов
kubectl get services -n online-boutique
```

### 3.5 Получение доступа к приложению

```bash
# Получение внешнего IP для frontend
kubectl get service frontend-external -n online-boutique -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Или через port-forward для тестирования
kubectl port-forward service/frontend-external 8080:80 -n online-boutique
```

## 4. Конфигурация Helm для cloud.ru

### 4.1 Установка Helm

```bash
# Установка Helm (если не установлен)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 4.2 Деплой через Helm

```bash
# Добавление репозитория (если требуется)
helm repo add online-boutique ./helm-chart

# Создание namespace
kubectl create namespace online-boutique

# Установка через Helm
helm install onlineboutique ./helm-chart \
  --namespace online-boutique \
  --set serviceAccounts.create=true \
  --set securityContext.enable=true \
  --set networkPolicies.create=false \
  --set opentelemetryCollector.create=false \
  --set googleCloudOperations.tracing=false \
  --set googleCloudOperations.profiler=false \
  --wait --timeout 300s
```

### 4.3 Пользовательские настройки values.yaml

Создайте файл `values-cloudru.yaml`:

```yaml
images:
  repository: us-central1-docker.pkg.dev/online-boutique-ci/microservices-demo
  tag: "v0.10.6"

serviceAccounts:
  create: true
  annotations: {}

securityContext:
  enable: true

adService:
  create: true
  resources:
    requests:
      cpu: 200m
      memory: 180Mi
    limits:
      cpu: 300m
      memory: 300Mi

cartService:
  create: true
  resources:
    requests:
      cpu: 200m
      memory: 64Mi
    limits:
      cpu: 300m
      memory: 128Mi

checkoutService:
  create: true
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

currencyService:
  create: true
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

emailService:
  create: true
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

frontend:
  create: true
  name: frontend
  externalService: true
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

loadGenerator:
  create: false  # Отключить для production
  resources:
    requests:
      cpu: 300m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

paymentService:
  create: true
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

productCatalogService:
  create: true
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

recommendationService:
  create: true
  resources:
    requests:
      cpu: 100m
      memory: 220Mi
    limits:
      cpu: 200m
      memory: 450Mi

shippingService:
  create: true
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

cartDatabase:
  type: redis
  connectionString: "redis-cart:6379"
  inClusterRedis:
    create: false  # Использовать внешний Redis
```

### 4.4 Использование внешнего Redis (опционально)

Для production рекомендуется использовать внешний Redis (Memorystore или внешний кластер):

```bash
# Создание внешнего Redis через cloud.ru
# (инструкция зависит от конкретных возможностей cloud.ru)

# Обновление пода cartservice с новым connection string
kubectl set env deployment/cartservice -n online-boutique \
  REDIS_ADDR=redis-external.cloudru.svc.cluster.local:6379
```

## 5. Мониторинг и логирование

### 5.1 Basic мониторинг

```bash
# Просмотр логов сервисов
kubectl logs -f deployment/frontend -n online-boutique
kubectl logs -f deployment/cartservice -n online-boutique

# Просмотр событий
kubectl get events -n online-boutique --sort-by='.lastTimestamp'
```

### 5.2 Интеграция с cloud.ru monitoring

Для интеграции с cloud.ru monitoring:
1. Настроить Prometheus Operator в кластере
2. Использовать ServiceMonitor манифесты для каждого сервиса
3. Настроить алертинг через Alertmanager

### 5.3 Логирование

```bash
# Настройка Fluentd/Fluent Bit для сбора логов
# Логи приложения пишутся в stdout/stderr

# Настройка логирования для каждого сервиса через env
kubectl set env deployment/frontend -n online-boutique \
  NODE_ENV=production
```

## 6. Безопасность

### 6.1 Рекомендуемые настройки безопасности

```yaml
# securityContext уже включен по умолчанию в манифестах:
securityContext:
  enable: true  # Запуск от нерутового пользователя (UID 1000)
  
# Дополнительные настройки:
networkPolicies:
  create: true  # Включить Network Policies

# Создание NetworkPolicy для ограничения трафика
```

### 6.2 Создание Network Policies

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: online-boutique
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

### 6.3 Подписи образов

Рекомендуется использовать подписанные образы:

```bash
# Проверка digest образов
docker pull us-central1-docker.pkg.dev/online-boutique-ci/microservices-demo/frontend:v0.10.6
docker inspect us-central1-docker.pkg.dev/online-boutique-ci/microservices-demo/frontend:v0.10.6
```

## 7. HA и отказоустойчивость

### 7.1 Рекомендации по HA

1. **Количество реплик**: Для production установить minReplicas=2 для каждого Deployment

```bash
# Пример для frontend
kubectl autoscale deployment frontend -n online-boutique \
  --min=2 --max=5 --cpu-percent=70
```

2. **Pod Disruption Budgets**:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: frontend-pdb
  namespace: online-boutique
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: frontend
```

3. **Распределение по зонам доступности**:

```yaml
# Добавить в spec подов:
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values: [frontend]
        topologyKey: topology.kubernetes.io/zone
```

## 8. Масштабирование

### 8.1 Horizontal Pod Autoscaler

```bash
# Автомасштабирование для основных сервисов
kubectl autoscale deployment frontend -n online-boutique --min=2 --max=10
kubectl autoscale deployment cartservice -n online-boutique --min=2 --max=5
kubectl autoscale deployment checkoutservice -n online-boutique --min=2 --max=5
```

### 8.2 Vertical Pod Autoscaler (опционально)

```bash
# Установка VPA
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/vpa-v0.9.2/vertical-pod-autoscaler.yaml

# Создание VPA для сервисов
```

## 9. Обновление и миграция

### 9.1 Обновление версии

```bash
# Обновление через Helm
helm upgrade onlineboutique ./helm-chart \
  --namespace online-boutique \
  --set images.tag="v0.11.0" \
  --wait --timeout 300s

# Или через kubectl с новыми манифестами
kubectl apply -f ./release/kubernetes-manifests.yaml -n online-boutique
```

### 9.2 Откат

```bash
# Откат через Helm
helm rollback onlineboutique -n online-boutique

# Или через kubectl
kubectl rollout undo deployment/frontend -n online-boutique
```

## 10. Удаление приложения

```bash
# Удаление через kubectl
kubectl delete namespace online-boutique

# Или через Helm
helm uninstall onlineboutique -n online-boutique

# Удаление Persistent Volume для Redis (если использовался)
kubectl delete pvc -n online-boutique redis-cart-0
```

## 11. Чеклист развертывания

- [ ] Кластер mk8s на cloud.ru развернут и доступен
- [ ] kubectl сконфигурирован для работы с кластером
- [ ] Создан namespace для приложения
- [ ] Развернут Redis (StatefulSet)
- [ ] Развернуты все микросервисы
- [ ] Все поды в статусе Running
- [ ] Frontend доступен через LoadBalancer IP
- [ ] Проверены логи всех сервисов
- [ ] Настроены мониторинг и алертинг
- [ ] Применены Network Policies (опционально)
- [ ] Настроены HPA для продакшена

## 12. Troubleshooting

### 12.1 Поды не запускаются

```bash
# Проверка событий
kubectl get events -n online-boutique --sort-by='.lastTimestamp'

# Проверка логов
kubectl logs <pod-name> -n online-boutique --previous
```

### 12.2 Проблемы с подключением к Redis

```bash
# Проверка доступности Redis
kubectl run -it --rm debug --image=busybox -n online-boutique -- sh
# Внутри контейнера:
nslookup redis-cart.online-boutique.svc.cluster.local
telnet redis-cart.online-boutique.svc.cluster.local 6379
```

### 12.3 Сервис недоступен

```bash
# Проверка сервиса
kubectl describe service frontend-external -n online-boutique

# Проверка endpoints
kubectl get endpoints frontend-external -n online-boutique

# Проверка ingress (если используется)
kubectl get ingress -n online-boutique
```

## 13. Дополнительные компоненты

### 13.1 Istio Service Mesh

```bash
# Установка Istio (если требуется)
# Применение istio-manifests
kubectl apply -f istio-manifests/
```

### 13.2 Google Cloud Operations

Для интеграции с Cloud Operations (если есть доступ):
- Включить tracing: `--set googleCloudOperations.tracing=true`
- Включить profiler: `--set googleCloudOperations.profiler=true`

### 13.3 OpenTelemetry Collector

```bash
# Установка OpenTelemetry Collector
kubectl apply -f ./helm-chart/templates/opentelemetry-collector.yaml
```

## 14. Планы масштабирования

### 14.1 Минимум 3 сервиса (требование задачи)

В приложении уже реализовано **11 микросервисов** плюс **Redis**:

1. **frontend** - веб-интерфейс
2. **cartservice** - корзина (с Redis)
3. **checkoutservice** - оформление заказов
4. **productcatalogservice** - каталог товаров
5. **currencyservice** - валюты
6. **paymentservice** - платежи
7. **shippingservice** - доставка
8. **emailservice** - уведомления
9. **recommendationservice** - рекомендации
10. **adservice** - реклама
11. **loadgenerator** - нагрузка

### 14.2 Компоненты СУБД и Kafka

#### СУБД:
- **Redis (встроенный)** - для хранения корзин пользователей
- Для production рекомендуется использовать **cloud.ru Memorystore** или внешний Redis кластер

#### Kafka:
- В текущей версии приложения **Kafka не используется**
- Для добавления Kafka потребуется:
  1. Установить Helm chart Kafka (Strimzi или Confluent)
  2. Модифицировать микросервисы для использования Kafka
  3. Настроить Producer/Consumer

## 15. Заключение

Приложение Online Boutique готово к развертыванию в mk8s на cloud.ru. Оно уже содержит все необходимые компоненты для production-развертывания:

- ✅ 11 микросервисов
- ✅ Redis для кэширования
- ✅ Helm чарты для упрощенного деплоя
- ✅ Kubernetes манифесты
- ✅ Terraform конфигурации (для GKE)
- ✅ Kustomize компоненты
- ✅ Документация
- ✅ Примеры интеграции с Istio, Cloud Operations и другими компонентами

Для развертывания достаточно следовать инструкциям в разделах 3-4 данной спецификации.
