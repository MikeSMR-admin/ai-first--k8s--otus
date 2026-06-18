# Сервисный аккаунт для Kubernetes в cloud.ru

## Создание сервисного аккаунта

Этот проект содержит автоматизированные тесты для создания и проверки сервисного аккаунта в cloud.ru через IAM API.

## Структура проекта

```
ai-first--k8s--otus/
├── auth--cloud-ru--for-api/          # Скрипты аутентификации и работы с cloud.ru API
│   ├── config--env.sh               # Конфигурация (KEY_ID, SECRET, PROJECT_ID)
│   ├── get-token--script.sh         # Получение IAM токена
│   ├── create-sa--script.sh         # Создание сервисного аккаунта
│   ├── delete-sa--script.sh         # Удаление сервисного аккаунта
│   └── menu--script.sh              # Меню для взаимодействия
├── tests/
│   └── service-account/             # Автотесты сервисного аккаунта
│       ├── 01-create-sa-test.sh     # Тест создания SA
│       ├── 02-get-sa-test.sh        # Тест получения SA
│       ├── 03-check-role-test.sh    # Тест проверки роли
│       ├── run-all-tests.sh         # Скрипт запуска всех тестов
│       ├── utils.sh                 # Утилиты для тестов
│       └── README.md                # Документация по тестам
├── specs/
│   └── service-account-api.json     # OpenAPI спецификация
├── docs/
│   └── cloud-ru/                    # Официальная документация cloud.ru
└── opsx/
    └── cloud-ru-token.txt           # Токен доступа (если есть)
```

## Быстрый старт

### 1. Настройка

Убедитесь, что в файле `auth--cloud-ru--for-api/config--env.sh` заданы правильные значения:

```bash
export KEY_ID="ваш_key_id"
export SECRET="ваш_secret"
export PROJECT_ID="ваш_project_id"
export SA_NAME="имя_сервисного_аккаунта"
export SA_DESCRIPTION="описание"
```

### 2. Запуск тестов

```bash
cd tests/service-account
./run-all-tests.sh
```

### 3. Проверка результатов

Результаты сохраняются в `tests/service-account/results/`:

```bash
cat results/create-sa-result.txt
cat results/get-sa-result.txt
cat results/role-result.txt
```

## Тесты

### Тест 1: Создание SA
Проверяет:
- HTTP-статус 200/201
- Присутствие обязательных полей (id, name, email, enabled)
- Правильный формат email
- SA активен

### Тест 2: Получение SA
Проверяет:
- HTTP-статус 200
- Присутствие объекта service_account
- Правильность всех полей
- ID и имя совпадают

### Тест 3: Проверка роли
Проверяет:
- HTTP-статус 200
- Роль `platform.project.admin` назначена
- Правильные значения всех полей роли

## OpenAPI спецификация

Спецификация API находится в `specs/service-account-api.json` и включает:

- POST /service-accounts - создание SA
- GET /service-accounts/{id} - получение SA
- GET /permissions - получение разрешений

## Документация cloud.ru

- [Создать сервисный аккаунт в cloud.ru](docs/cloud-ru/Создать%20сервисный%20аккаунт%20в%20cloud.ru.md)
- [Просмотреть сервисный аккаунт в cloud.ru](docs/cloud-ru/Просмотреть%20сервисный%20аккаунт%20в%20cloud.ru.md)
- [Аутентификация в API Managed Kubernetes](docs/cloud-ru/Аутентификация%20в%20API%20Managed%20Kubernetes.md)
- [Управление доступом в Managed Kubernetes](docs/cloud-ru/Управление%20доступом%20в%20Managed%20Kubernetes.md)

## Удаление сервисного аккаунта

Для удаления созданного SA обновите переменную `SA_ID_TO_DELETE` в `config--env.sh` и выполните:

```bash
cd auth--cloud-ru--for-api
source config--env.sh
./delete-sa--script.sh
```

## Интеграция с CI/CD

Добавьте в ваш CI/CD пайплайн:

```yaml
- name: Setup environment
  run: |
    source auth--cloud-ru--for-api/config--env.sh

- name: Run service account tests
  run: |
    cd tests/service-account
    ./run-all-tests.sh
```

## Поддержка

Для вопросов и предложений создайте issue в репозитории проекта.
