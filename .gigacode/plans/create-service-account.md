# План создания сервисного аккаунта в cloud.ru

## Задача
Создать сервисный аккаунт для работы с Kubernetes кластером в cloud.ru через API.

## Статус токена
Уже есть действующий токен в файле `opsx/cloud-ru-token.txt`

## Шаги выполнения

### 1. Извлечь projectID из токена
- Декодировать JWT токен
- Получить projectID из полей токена (поле `resource_access` или аналогичное)

### 2. Создать сервисный аккаунт
- Отправить POST запрос на `https://iam.api.cloud.ru/api/v1/service-accounts`
- Тело запроса:
  ```json
  {
    "name": "otus-k8s-service-account",
    "description": "Сервисный аккаунт для работы с Kubernetes кластером",
    "projectId": "<полученный projectId>"
  }
  ```

### 3. Назначить роль сервисному аккаунту
- Отправить POST запрос на `https://iam.api.cloud.ru/api/v1/permissions`
- Тело запроса:
  ```json
  {
    "role": "platform.project.admin",
    "objectId": "<projectId>",
    "objectType": "resource",
    "subjectId": "<id созданного SA>",
    "subjectType": "service_account",
    "expiresAt": "2027-06-17T00:00:00.000Z"
  }
  ```

### 4. Сохранить результаты
- Сохранить ID сервисного аккаунта и ключи доступа в `opsx/service-account-result.json`

## Ожидаемые результаты
- Сервисный аккаунт создан и активен
- Назначена роль platform.project.admin
- Данные сохранены в файл для последующего использования
