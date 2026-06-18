Создать сервисный аккаунт
Эта статья полезна?


Вы можете создать любое количество сервисных аккаунтов в личном кабинете или по API с помощью curl-запроса.


Личный кабинет

API
Создайте персональный ключ доступа.

Получите аутентификационный токен.

Создайте сервисный аккаунт с помощью curl-запроса:


curl --location 'https://iam.api.cloud.ru/api/v1/service-accounts' \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer <аутентификационный токен>' \
     --data '{
       "name": "SA2_test_public_api",
       "description": "тестовый сервисный аккаунт для публичного API",
       "projectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx"
     }'

Где:

name — Название сервисного аккаунта. Можно использовать латинские буквы, цифры, дефисы, двоеточия и подчеркивания.

description — Описание сервисного аккаунта.

projectID — Идентификатор проекта, в котором вы хотите создать сервисный аккаунт.

Пример ответа

С помощью запроса назначьте роль, используя id сервисного аккаунта из предыдущего шага.

Подсказка
Если сервисному аккаунту не добавлена роль, то он не будет авторизован на выполнение вызовов API.


curl --location 'https://iam.api.cloud.ru/api/v1/permissions' \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer <аутентификационный токен>' \
     --data '{
       "role": "platform.project.admin",
       "objectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
       "objectType": "resource",
       "subjectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
       "subjectType": "service_account",
       "expiresAt": "2024-10-28T07:19:34.563Z"
     }'

Где:

role — роль, выдаваемая сервисному аккаунту;

objectId — идентификатор ресурса, на уровень которого выдается роль;

objectType:

customer — роль выдается на организацию;

resource — роль на любой ресурс.

subjectId — идентификатор сервисного аккаунта;

subjectType — тип субъекта, которому выдается роль:

service_account — роль для сервисного аккаунта.

expiresAt - 2025-05-28 — дата, после которой роль будет удалена.

Сервисный аккаунт появился в списке со статусом «Активен».

Теперь для него можно создать ключ доступа или API-ключ.