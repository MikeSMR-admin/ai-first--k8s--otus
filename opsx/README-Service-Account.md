# Service Account Creation Script for cloud.ru

Этот скрипт автоматизирует создание сервисного аккаунта в cloud.ru и включает проверку существования аккаунта перед созданием.

## Возможности

- Проверка существования сервисного аккаунта по имени
- Создание нового сервисного аккаунта (если не существует)
- Назначение роли `platform.project.admin`
- Создание ключа доступа (access key) для сервисного аккаунта
- Сохранение учетных данных в защищенный файл

## Требования

- Bash (WSL для Windows)
- curl.exe (доступен в PATH)

## Использование

### Способ 1: Через переменные окружения

```bash
export SERVICE_ACCOUNT_NAME="my-service-account"
export PROJECT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AUTH_TOKEN="eyJhbGciOiJSUzI1NiIs..."

./create-service-account.sh
```

### Способ 2: Через аргументы командной строки

```bash
./create-service-account.sh \
  --name my-service-account \
  --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --token eyJhbGciOiJSUzI1NiIs...
```

### Способ 3: Смешанный

```bash
export SERVICE_ACCOUNT_NAME="my-service-account"
export PROJECT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

./create-service-account.sh --token eyJhbGciOiJSUzI1NiIs...
```

## Пример полного процесса

### 1. Получение токена доступа

Если у вас нет действующего токена, вы можете получить его через личный кабинет cloud.ru:

1. Войдите в личный кабинет cloud.ru
2. Перейдите в раздел "Управление доступом" → "Ключи доступа"
3. Создайте персональный ключ доступа
4. Используйте `keyId` и `secret` для получения токена:

```bash
curl.exe -s --location "https://iam.api.cloud.ru/api/v1/auth/token" ^
  --header "Content-Type: application/json" ^
  --data "{\"keyId\": \"<key_id>\", \"secret\": \"<secret>\"}"
```

### 2. Запуск скрипта

```bash
export PROJECT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AUTH_TOKEN="<полученный_токен>"

./create-service-account.sh --name my-service-account
```

## Результаты

Скрипт создаст:

1. Сервисный аккаунт с указанным именем
2. Назначит роль `platform.project.admin`
3. Создаст ключ доступа
4. Сохранит учетные данные в файл: `service-account-credentials-<имя_аккаунта>.txt`

### Пример файла учетных данных

```
Service Account Credentials
===========================
Service Account ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Key ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Secret: <секретный_ключ>
Created at: 2024-08-28T11:21:41.108344449Z
Expires at: 2025-08-28T11:21:41.108344449Z
```

## Безопасность

⚠️ **ВАЖНО**: Сохраняйте ��айл с учетными данными в безопасном месте. Не коммитьте его в репозиторий!

Рекомендации:
- Добавьте `service-account-credentials-*.txt` в `.gitignore`
- Используйте менеджер секретов (Vault, AWS Secrets Manager и т.д.)
- Регулярно обновляйте ключи доступа

## Ошибки и диагностика

### Токен истек

Если токен истек, скрипт выдаст ошибку. Получите новый токен и повторите попытку.

### Сервисный аккаунт уже существует

Если сервисный аккаунт с таким именем уже существует, скрипт:
- Использует существующий аккаунт
- Проверит назначенные роли
- Создаст ключ доступа, если его нет

### Ошибки API

Если возникает ошибка API, скрипт выведет сообщение об ошибке и ответ от сервера.

## Параметры API

- IAM API: `https://iam.api.cloud.ru/api/v1/`
- Создание SA: `POST /api/v1/service-accounts`
- Создание роли: `POST /api/v1/permissions`
- Создание ключа: `POST /api/v1/service-accounts/credentials/access-keys`
- Список SA: `GET /api/v1/service-accounts`

## Лицензия

MIT License
