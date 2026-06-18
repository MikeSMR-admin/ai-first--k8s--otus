# План создания документации проекта ai-first--k8s--otus

## Описание задачи
Создать каталог `./docs` и файл `README.md` с кратким описанием проекта.

## Проект
**ai-first--k8s--otus** - учебный проект по развертыванию кластера, инфраструктурных компонентов Kubernetes и приложения-примера, применяя AI-first подход.

## Содержание README.md

### 1. ОбOverview
- Учебный проект по развертыванию managed Kubernetes кластера в cloud.ru
- Применение AI-first подхода
- Приложение-пример: Online Boutique (microservices-demo)

### 2. Архитектура решения
- Managed Kubernetes кластер (Terraform)
- Ingress-контроллер (nginx) с публичным IP и HTTPS
- Мониторинг: Prometheus + Grafana
- Логирование: Loki + Promtail
- CI/CD: GitHub Actions

### 3. Структура проекта
- `authentication--cloud-ru--for-api/` - скрипты для доступа к cloud.ru API
- `opsx/` - конфигурация проекта
- `docs/` - документация

### 4. Технологический стек
- Terraform, Kubernetes, Helm, GitHub Actions
- Prometheus, Grafana, Loki, Nginx Ingress

### 5. Быстрый старт
- Предварительные требования
- Основные шаги развертывания

## План выполнения
1. Создать каталог ./docs
2. Создать файл ./docs/README.md с описанием проекта
3. Проверить созданный файл
