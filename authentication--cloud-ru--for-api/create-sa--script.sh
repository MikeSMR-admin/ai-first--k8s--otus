#!/bin/bash
# Создание сервисного аккаунта
# Использует переменные: PROJECT_ID, SA_NAME, SA_DESCRIPTION, а также токен (получает автоматически)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загружаем конфигурацию, если не загружена
if [ -z "$PROJECT_ID" ] || [ -z "$SA_NAME" ]; then
    source "$SCRIPT_DIR/config--env"
fi

# Получаем токен
TOKEN=$("$SCRIPT_DIR/get-token--script")
if [ -z "$TOKEN" ]; then
    echo "Не удалось получить токен. Проверьте KEY_ID и SECRET в config--env"
    exit 1
fi

# Формируем JSON
JSON_DATA=$(cat <<EOF
{
    "name": "$SA_NAME",
    "description": "$SA_DESCRIPTION",
    "projectId": "$PROJECT_ID"
}
EOF
)

URL="https://iam.api.cloud.ru/api/v1/service-accounts"
RESPONSE=$(curl -s -w "%{http_code}" -X POST "$URL" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$JSON_DATA")

HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Сервисный аккаунт успешно создан!"
    if command -v jq &>/dev/null; then
        ACCOUNT_ID=$(echo "$BODY" | jq -r '.service_account.id // .id')
        echo "📌 ID созданного аккаунта: $ACCOUNT_ID"
        echo "👉 Сохраните этот ID для возможного удаления."
    else
        echo "📌 Ответ сервера:"
        echo "$BODY"
    fi
else
    echo "⚠️ Ошибка при создании. HTTP код: $HTTP_CODE"
    echo "Ответ: $BODY"
    exit 1
fi