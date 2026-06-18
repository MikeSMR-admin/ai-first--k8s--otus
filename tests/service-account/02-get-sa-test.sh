#!/bin/bash
# Тест 2: Получение информации о сервисном аккаунте

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Загрузка утилит
source "$SCRIPT_DIR/utils.sh"

# Загрузка конфигурации
load_config

echo "=========================================="
echo "Тест 2: Получение информации о SA"
echo "=========================================="

# Получение токена
info_msg "Получение токена доступа..."
TOKEN=$(get_token)
success_msg "Токен получен"

# Загрузка ID из предыдущего теста
RESULTS_DIR="$PROJECT_DIR/tests/service-account/results"
RESULT_FILE="$RESULTS_DIR/create-sa-result.txt"

if [ ! -f "$RESULT_FILE" ]; then
    error_msg "Файл результатов не найден: $RESULT_FILE"
    error_msg "Запустите тест 1 (01-create-sa-test.sh) первым"
    exit 1
fi

source "$RESULT_FILE"

if [ -z "$SA_ID" ]; then
    error_msg "ID сервисного аккаунта не найден в файле результатов"
    exit 1
fi

info_msg "Получение информации о SA с ID: $SA_ID"

# Выполнение запроса
RESPONSE=$(get_request "service-accounts/$SA_ID" "$TOKEN")
HTTP_CODE=$(extract_status "$RESPONSE")
BODY=$(extract_json "$RESPONSE")

info_msg "HTTP статус: $HTTP_CODE"

# Проверка HTTP статуса
if [ "$HTTP_CODE" != "200" ]; then
    error_msg "Ожидаемый статус 200, получено: $HTTP_CODE"
    error_msg "Ответ сервера: $BODY"
    exit 1
fi
success_msg "HTTP статус верный: $HTTP_CODE"

# Проверка структуры ответа
info_msg "Проверка структуры ответа..."

if ! has_json_key "$BODY" "service_account"; then
    error_msg "Отсутствует поле 'service_account' в ответе"
    exit 1
fi
success_msg "Поле 'service_account' присутствует"

# Извлечение вложенного объекта service_account
SA_JSON=$(echo "$BODY" | grep -o '"service_account":{[^}]*}')

if [ -z "$SA_JSON" ]; then
    error_msg "Не удалось извлечь объект service_account"
    exit 1
fi

# Проверка обязательных полей сервисного аккаунта
REQUIRED_FIELDS=("id" "name" "email" "enabled" "created_at" "updated_at")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! has_json_key "$SA_JSON" "$field"; then
        error_msg "Отсутствует поле '$field' в service_account"
        exit 1
    fi
    success_msg "Поле '$field' присутствует"
done

# Проверка ID совпадает
SA_ID_FROM_RESPONSE=$(get_json_value "$SA_JSON" "id")
if [ "$SA_ID_FROM_RESPONSE" != "$SA_ID" ]; then
    error_msg "ID не совпадает: ожидается '$SA_ID', получено '$SA_ID_FROM_RESPONSE'"
    exit 1
fi
success_msg "ID совпадает: $SA_ID"

# Проверка имени
SA_NAME_FROM_RESPONSE=$(get_json_value "$SA_JSON" "name")
if [ "$SA_NAME_FROM_RESPONSE" != "$SA_NAME" ]; then
    error_msg "Имя не совпадает: ожидается '$SA_NAME', получено '$SA_NAME_FROM_RESPONSE'"
    exit 1
fi
success_msg "Имя совпадает: $SA_NAME"

# Проверка email формата
EMAIL=$(get_json_value "$SA_JSON" "email")
if ! check_sa_email_format "$EMAIL" "$PROJECT_ID"; then
    error_msg "Неверный формат email: $EMAIL"
    exit 1
fi
success_msg "Email формат верный: $EMAIL"

# Проверка, что SA активен
SA_ENABLED=$(get_json_value "$SA_JSON" "enabled")
if [ "$SA_ENABLED" != "true" ]; then
    error_msg "Сервисный аккаунт не активен (enabled=$SA_ENABLED)"
    exit 1
fi
success_msg "Сервисный аккаунт активен (enabled=true)"

# Проверка timestamps
CREATED_AT=$(get_json_value "$SA_JSON" "created_at")
UPDATED_AT=$(get_json_value "$SA_JSON" "updated_at")

if [ -z "$CREATED_AT" ] || [ -z "$UPDATED_AT" ]; then
    error_msg "Отсутствуют timestamps"
    exit 1
fi
success_msg "Timestamps присутствуют: created_at=$CREATED_AT, updated_at=$UPDATED_AT"

echo ""
success_msg "Тест 2 пройден успешно!"
echo ""

# Сохранение результатов
echo "SA_ID=$SA_ID" > "$RESULTS_DIR/get-sa-result.txt"
echo "SA_NAME=$SA_NAME" >> "$RESULTS_DIR/get-sa-result.txt"
echo "SA_EMAIL=$EMAIL" >> "$RESULTS_DIR/get-sa-result.txt"
echo "SA_ENABLED=$SA_ENABLED" >> "$RESULTS_DIR/get-sa-result.txt"
echo "HTTP_CODE=$HTTP_CODE" >> "$RESULTS_DIR/get-sa-result.txt"

success_msg "Результаты сохранены в $RESULTS_DIR/get-sa-result.txt"

# Вывод полного ответа для отладки
echo "Полный ответ сервера:"
echo "$BODY" | sed 's/^/  /'

exit 0
