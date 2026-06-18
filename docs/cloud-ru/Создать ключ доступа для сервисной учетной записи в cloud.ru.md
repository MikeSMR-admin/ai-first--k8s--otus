Создать ключ доступа
Эта статья полезна?


Для одного сервисного аккаунта может быть создано до 20 ключей доступа в личном кабинете или через API-запрос.


Личный кабинет

API
Скопируйте идентификатор сервисного аккаунта.

Выполните запрос:


curl --location 'https://iam.api.cloud.ru/api/v1/service-accounts/credentials/access-keys' \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer <аутентификационный токен>' \
     --data '{
       "serviceAccountId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
       "description": "ключ доступа 2, созданный через public api для сервисного аккаунта SA2_test_public_api ",
       "ttl": "4000h"
     }'

Где:

serviceAccoutId — идентификатор сервисного аккаунта;

description — описание ключа доступа;

ttl — время жизни ключа доступа в часах, минутах и секундах (например, 24h15m10s — одни сутки, 15 мин и 10 с).

Подсказка
Если задать 24h, то ключ доступа будет действовать одни сутки. Максимальное значение действия ключа доступа — один год (8760h).

Если задать значение больше одного года, например 8800h, то API выдаст ошибку:


{
  "code": 3,
  "message": "(ttl) is invalid argument: access key TTL is out of range: 1d(24h) > 8800h0m0s > 1year(8760h)",
  "details": []
}

Пример ответа


{
  "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
  "service_account_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
  "description": "ключ доступа 2 созданный через public api для сервисного аккаунта SA2_test_public_api",
  "key_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
  "secret": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
  "created_at": "2024-08-28T11:21:41.108344449Z",
  "expired_at": "2025-02-11T03:21:41.108344449Z"
}


