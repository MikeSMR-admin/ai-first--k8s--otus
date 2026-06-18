Просмотреть сервисный аккаунт
Эта статья полезна?


Получить информацию о сервисном аккаунте можно в личном кабинете или через API-запрос.


Личный кабинет

API
Чтобы посмотреть информацию по сервисному аккаунту через API, нужно сначала назначить ему роль с помощью метода POST /api/v1/permissions, а затем выполнить запрос:


curl --location 'https://iam.api.cloud.ru/api/v1/service-accounts/<id>' \
     --header 'accept: application/json' \
     --header 'Authorization: Bearer <аутентификационный токен>'

Где:

id — идентификатор сервисного аккаунта.

Пример ответа


{
  "service_account": {
      "id": "id <сервисного аккаунта>",
      "namespace_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
      "name": "SA2_test_public_api",
      "email": "SA2_test_public_api@xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx.iam.cloud.ru",
      "description": "тестовый сервисный аккаунт для публичного API",
      "use_refresh_tokens": false,
      "enabled": true,
      "created_at": "2024-08-28T05:57:29.578906Z",
      "updated_at": "2024-08-28T05:57:29.578906Z"
  }
}

Коды ошибок

403 Forbidden

У сервисного аккаунта нет ролей.


{
  "code": 7,
  "message": "subject has no permission to get service account",
  "details": []
}
