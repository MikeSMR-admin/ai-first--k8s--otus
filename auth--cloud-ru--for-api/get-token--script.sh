#!/bin/bash
# Скрипт получения IAM-токена по KEY_ID и SECRET
# Использует переменные окружения KEY_ID, SECRET
# Возвращает токен в stdout, в случае ошибки пишет в stderr и возвращает код 1

# Загружаем конфигурацию, если не загружена
if [ -z "$KEY_ID" ] || [ -z "$SECRET" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/config--env" 2>/dev/null
fi

if [ -z "$KEY_ID" ] || [ -z "$SECRET" ]; then
    echo "Ошибка: не заданы KEY_ID или SECRET" >&2
    exit 1
fi

RESPONSE=$(curl -s -X POST 'https://iam.api.cloud.ru/api/v1/auth/token' \
    -H 'Content-Type: application/json' \
    -d "{\"keyId\": \"$KEY_ID\", \"secret\": \"$SECRET\"}")

# Извлечение токена
if command -v jq &>/dev/null; then
    TOKEN=$(echo "$RESPONSE" | jq -r '.token')
else
    TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*' | cut -d '"' -f 4)
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "Ошибка получения токена: $RESPONSE" >&2
    exit 1
fi

echo "$TOKEN"