Аутентификация в API Managed Kubernetes
Эта статья полезна?


Получите ключи доступа к API одним из способов:

Создайте персональный ключ доступа.

Создайте сервисный аккаунт и сгенерируйте ключи доступа для него.

Получите токен с помощью curl-запроса:


curl --location 'https://iam.api.cloud.ru/api/v1/auth/token' \
     --header 'Content-Type: application/json' \
     --data '{
       "keyId": "<key_id>",
       "secret": "<secret>"
     }'

Где:

keyId — Key ID (логин) ключа доступа.

secret — Key Secret (пароль) ключа доступа.

Используйте токен при каждом API-запросе к сервису — передайте его в заголовке Authorization в формате:


Authorization: Bearer $TOKEN