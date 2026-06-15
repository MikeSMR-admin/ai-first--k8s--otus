#!/bin/bash
# Удаление сервисного аккаунта
# Использует переменную SA_ID_TO_DELETE, а также токен

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$SA_ID_TO_DELETE" ]; then
    source "$SCRIPT_DIR/config--env"
fi

if [ -z "$SA_ID_TO_DELETE" ]; then
    echo "Ошибка: не задан SA_ID_TO_DELETE в config--env"
    exit 1
fi

TOKEN=$("$SCRIPT_DIR/get-token--script")
if [ -z "$TOKEN" ]; then
    echo "Не удалось получить токен."
    exit 1
fi

URL="https://iam.api.cloud.ru/api/v1/service-accounts/${SA_ID_TO_DELETE}"
RESPONSE=$(curl -s -w "%{http_code}" -X DELETE "$URL" \
    -H "accept: application/json" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"

if [ "$HTTP_CODE" -eq 204 ]; then
    echo "✅ Сервисный аккаунт с ID ${SA_ID_TO_DELETE} успешно удалён."
elif [ "$HTTP_CODE" -eq 404 ]; then
    echo "❌ Сервисный аккаунт с ID ${SA_ID_TO_DELETE} не найден."
else
    echo "⚠️ Ошибка при удалении. HTTP код: ${HTTP_CODE}"
    echo "Ответ: ${BODY}"
    exit 1
fi