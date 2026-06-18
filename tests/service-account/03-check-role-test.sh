#!/bin/bash
# Тест 3: Проверка назначения роли сервисному аккаунту

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Загрузка утилит
source "$SCRIPT_DIR/utils.sh"

# Загрузка конфигурации
load_config

echo "=========================================="
echo "Тест 3: Проверка назначения роли SA"
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

info_msg "Проверка ролей для SA с ID: $SA_ID"

# Проверка, что роль назначена
info_msg "Проверка назначения роли 'platform.project.admin'..."

# Сначала проверим, есть ли вообще какие-то роли у SA
RESPONSE=$(get_request "permissions?subjectId=$SA_ID&subjectType=service_account" "$TOKEN")
HTTP_CODE=$(extract_status "$RESPONSE")
BODY=$(extract_json "$RESPONSE")

info_msg "HTTP статус: $HTTP_CODE"

if [ "$HTTP_CODE" != "200" ]; then
    error_msg "Ожидаемый статус 200, получено: $HTTP_CODE"
    error_msg "Ответ сервера: $BODY"
    
    # Проверка на ошибку "нет прав" - это означает, что SA не имеет ролей
    if echo "$BODY" | grep -q "has no permission"; then
        error_msg "Сервисный аккаунт не имеет ролей доступа"
        exit 1
    fi
    
    exit 1
fi
success_msg "HTTP статус верный: $HTTP_CODE"

# Проверка, что в ответе есть роли
if ! has_json_key "$BODY" "permissions"; then
    error_msg "Отсутствует поле 'permissions' в ответе"
    error_msg "Сервисный аккаунт не имеет ролей"
    exit 1
fi

# Проверка наличия конкретной роли
ROLE_NAME="platform.project.admin"

if ! check_role_exists "$BODY" "$ROLE_NAME"; then
    error_msg "Роль '$ROLE_NAME' не найдена у сервисного аккаунта"
    info_msg "Полный ответ сервера:"
    echo "$BODY" | sed 's/^/  /'
    exit 1
fi
success_msg "Роль '$ROLE_NAME' назначена успешно"

# Извлечение информации о роли для проверки
ROLE_INFO=$(echo "$BODY" | grep -o "\"role\":\"$ROLE_NAME\"[^}]*}")
info_msg "Информация о роли: $ROLE_INFO"

# Проверка дополнительных полей роли
if ! has_json_key "$ROLE_INFO" "subjectId"; then
    error_msg "Отсутствует поле 'subjectId' в информации о роли"
    exit 1
fi
success_msg "Поле 'subjectId' присутствует в роли"

if ! has_json_key "$ROLE_INFO" "subjectType"; then
    error_msg "Отсутствует поле 'subjectType' в информации о роли"
    exit 1
fi
success_msg "Поле 'subjectType' присутствует в роли"

if ! has_json_key "$ROLE_INFO" "objectId"; then
    error_msg "Отсутствует поле 'objectId' в информации о роли"
    exit 1
fi
success_msg "Поле 'objectId' присутствует в роли"

if ! has_json_key "$ROLE_INFO" "objectType"; then
    error_msg "Отсутствует поле 'objectType' в информации о роли"
    exit 1
fi
success_msg "Поле 'objectType' присутствует в роли"

# Проверка, что subjectId совпадает с SA_ID
ROLE_SUBJECT_ID=$(echo "$ROLE_INFO" | grep -o '"subjectId":"[^"]*"' | cut -d'"' -f4)
if [ "$ROLE_SUBJECT_ID" != "$SA_ID" ]; then
    error_msg "subjectId не совпадает: ожидается '$SA_ID', получено '$ROLE_SUBJECT_ID'"
    exit 1
fi
success_msg "subjectId совпадает: $SA_ID"

# Проверка, что subjectType равен service_account
ROLE_SUBJECT_TYPE=$(echo "$ROLE_INFO" | grep -o '"subjectType":"[^"]*"' | cut -d'"' -f4)
if [ "$ROLE_SUBJECT_TYPE" != "service_account" ]; then
    error_msg "subjectType не равен 'service_account': получено '$ROLE_SUBJECT_TYPE'"
    exit 1
fi
success_msg "subjectType равен 'service_account'"

# Проверка, что objectId совпадает с PROJECT_ID
ROLE_OBJECT_ID=$(echo "$ROLE_INFO" | grep -o '"objectId":"[^"]*"' | cut -d'"' -f4)
if [ "$ROLE_OBJECT_ID" != "$PROJECT_ID" ]; then
    error_msg "objectId не совпадает: ожидается '$PROJECT_ID', получено '$ROLE_OBJECT_ID'"
    exit 1
fi
success_msg "objectId совпадает: $PROJECT_ID"

# Проверка objectType
ROLE_OBJECT_TYPE=$(echo "$ROLE_INFO" | grep -o '"objectType":"[^"]*"' | cut -d'"' -f4)
if [ "$ROLE_OBJECT_TYPE" != "resource" ]; then
    error_msg "objectType не равен 'resource': получено '$ROLE_OBJECT_TYPE'"
    exit 1
fi
success_msg "objectType равен 'resource'"

# Сохранение результатов
echo "SA_ID=$SA_ID" > "$RESULTS_DIR/role-result.txt"
echo "ROLE_NAME=$ROLE_NAME" >> "$RESULTS_DIR/role-result.txt"
echo "ROLE_SUBJECT_ID=$ROLE_SUBJECT_ID" >> "$RESULTS_DIR/role-result.txt"
echo "ROLE_OBJECT_ID=$ROLE_OBJECT_ID" >> "$RESULTS_DIR/role-result.txt"
echo "HTTP_CODE=$HTTP_CODE" >> "$RESULTS_DIR/role-result.txt"

success_msg "Результаты сохранены в $RESULTS_DIR/role-result.txt"

echo ""
success_msg "Тест 3 пройден успешно!"
echo ""

# Вывод полного ответа для отладки
echo "Полный ответ сервера:"
echo "$BODY" | sed 's/^/  /'

exit 0
