#!/bin/bash
# Тест 1: Создание сервисного аккаунта

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Загрузка утилит
source "$SCRIPT_DIR/utils.sh"

# Загрузка конфигурации
load_config

echo "=========================================="
echo "Тест 1: Создание сервисного аккаунта"
echo "=========================================="

# Получение токена
info_msg "Получение токена доступа..."
TOKEN=$(get_token)
success_msg "Токен получен"

# Подготовка данных для создания SA
SA_NAME="${SA_NAME:-test-sa-$(date +%s)}"
SA_DESCRIPTION="${SA_DESCRIPTION:-Тестовый сервисный аккаунт для автотестов}"

JSON_DATA=$(cat <<EOF
{
  "name": "$SA_NAME",
  "description": "$SA_DESCRIPTION",
  "projectId": "$PROJECT_ID"
}
EOF
)

info_msg "Создание сервисного аккаунта: $SA_NAME"
info_msg "Project ID: $PROJECT_ID"

# Выполнение запроса
RESPONSE=$(post_request "service-accounts" "$JSON_DATA" "$TOKEN")
HTTP_CODE=$(extract_status "$RESPONSE")
BODY=$(extract_json "$RESPONSE")

info_msg "HTTP статус: $HTTP_CODE"

# Проверка HTTP статуса
if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
    error_msg "Ожидаемый статус 200 или 201, получено: $HTTP_CODE"
    error_msg "Ответ сервера: $BODY"
    exit 1
fi
success_msg "HTTP статус верный: $HTTP_CODE"

# Проверка обязательных полей в ответе
info_msg "Проверка структуры ответа..."

if ! has_json_key "$BODY" "id"; then
    error_msg "Отсутствует поле 'id' в ответе"
    exit 1
fi
success_msg "Поле 'id' присутствует"

if ! has_json_key "$BODY" "name"; then
    error_msg "Отсутствует поле 'name' в ответе"
    exit 1
fi
success_msg "Поле 'name' присутствует"

if ! has_json_key "$BODY" "email"; then
    error_msg "Отсутствует поле 'email' в ответе"
    exit 1
fi
success_msg "Поле 'email' присутствует"

if ! has_json_key "$BODY" "enabled"; then
    error_msg "Отсутствует поле 'enabled' в ответе"
    exit 1
fi
success_msg "Поле 'enabled' присутствует"

# Извлечение ID созданного SA
SA_ID=$(get_json_value "$BODY" "id")
info_msg "ID созданного сервисного аккаунта: $SA_ID"

# Сохранение результатов
RESULTS_DIR="$PROJECT_DIR/tests/service-account/results"
mkdir -p "$RESULTS_DIR"

echo "SA_ID=$SA_ID" > "$RESULTS_DIR/create-sa-result.txt"
echo "SA_NAME=$SA_NAME" >> "$RESULTS_DIR/create-sa-result.txt"
echo "SA_EMAIL=$(get_json_value "$BODY" "email")" >> "$RESULTS_DIR/create-sa-result.txt"
echo "PROJECT_ID=$PROJECT_ID" >> "$RESULTS_DIR/create-sa-result.txt"
echo "HTTP_CODE=$HTTP_CODE" >> "$RESULTS_DIR/create-sa-result.txt"

success_msg "Результаты сохранены в $RESULTS_DIR/create-sa-result.txt"

# Проверка email формата
EMAIL=$(get_json_value "$BODY" "email")
if ! check_sa_email_format "$EMAIL" "$PROJECT_ID"; then
    error_msg "Неверный формат email: $EMAIL"
    exit 1
fi
success_msg "Email формат верный: $EMAIL"

# Проверка, что SA включен
if ! check_sa_active "$BODY"; then
    error_msg "Сервисный аккаунт не активен"
    exit 1
fi
success_msg "Сервисный аккаунт активен"

echo ""
success_msg "Тест 1 пройден успешно!"
echo ""

# Вывод полного ответа для отладки
echo "Полный ответ сервера:"
echo "$BODY" | sed 's/^/  /'

exit 0
