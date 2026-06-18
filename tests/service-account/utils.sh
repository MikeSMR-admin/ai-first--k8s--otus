#!/bin/bash
# Утилиты для автотестов сервисного аккаунта

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUTH_DIR="$PROJECT_DIR/auth--cloud-ru--for-api"
RESULTS_DIR="$SCRIPT_DIR/results"

# Загрузка конфигурации напрямую из файла (без source, чтобы избежать проблем с CRLF и chmod)
load_config() {
    if [ -f "$AUTH_DIR/config--env.sh" ]; then
        # Читаем файл и извлекаем только export команды
        while IFS= read -r line; do
            # Игнорируем пустые строки и комментарии
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
                continue
            fi
            # Извлекаем export команды
            if [[ "$line" =~ ^export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=\"(.*)\"$ ]]; then
                key="${BASH_REMATCH[1]}"
                value="${BASH_REMATCH[2]}"
                export "$key=$value"
            fi
        done < "$AUTH_DIR/config--env.sh"
    else
        echo "Ошибка: не найден файл конфигурации $AUTH_DIR/config--env.sh"
        exit 1
    fi
}

# Получение токена из файла или через API
get_token() {
    # Сначала проверяем наличие токена в файле
    if [ -f "$PROJECT_DIR/opsx/cloud-ru-token.txt" ]; then
        TOKEN=$(cat "$PROJECT_DIR/opsx/cloud-ru-token.txt" | tr -d '\r\n')
        if [ -n "$TOKEN" ] && [ "$TOKEN" != "" ]; then
            echo "$TOKEN"
            return 0
        fi
    fi
    
    # Если токена нет в файле, получаем его через API
    if [ -z "$KEY_ID" ] || [ -z "$SECRET" ]; then
        load_config
    fi
    
    if [ -z "$KEY_ID" ] || [ -z "$SECRET" ]; then
        echo "Ошибка: не заданы KEY_ID или SECRET" >&2
        return 1
    fi
    
    RESPONSE=$(curl -s -X POST 'https://iam.api.cloud.ru/api/v1/auth/token' \
        -H 'Content-Type: application/json' \
        -d "{\"keyId\": \"$KEY_ID\", \"secret\": \"$SECRET\"}")
    
    TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
        echo "Ошибка получения токена: $RESPONSE" >&2
        return 1
    fi
    
    echo "$TOKEN"
    return 0
}

# Выполнение POST запроса к IAM API
post_request() {
    local endpoint="$1"
    local data="$2"
    local token="$3"
    
    curl -s -w "\n%{http_code}" \
        -X POST "https://iam.api.cloud.ru/api/v1/$endpoint" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "$data"
}

# Выполнение GET запроса к IAM API
get_request() {
    local endpoint="$1"
    local token="$2"
    
    curl -s -w "\n%{http_code}" \
        -X GET "https://iam.api.cloud.ru/api/v1/$endpoint" \
        -H "accept: application/json" \
        -H "Authorization: Bearer $token"
}

# Выполнение DELETE запроса к IAM API
delete_request() {
    local endpoint="$1"
    local token="$2"
    
    curl -s -w "\n%{http_code}" \
        -X DELETE "https://iam.api.cloud.ru/api/v1/$endpoint" \
        -H "accept: application/json" \
        -H "Authorization: Bearer $token"
}

# Извлечение JSON из ответа (без HTTP статуса)
extract_json() {
    echo "$1" | sed '$d'
}

# Извлечение HTTP статуса из ответа
extract_status() {
    echo "$1" | tail -n1
}

# Извлечение значения из JSON с помощью grep/sed (без jq)
get_json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":\"[^\"]*\"" | cut -d'"' -f4
}

# Извлечение числового значения из JSON
get_json_numeric() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":[0-9]*" | cut -d':' -f2
}

# Проверка наличия ключа в JSON
has_json_key() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -q "\"$key\":"
}

# Форматирование сообщения об успехе
success_msg() {
    echo "✅ $1"
}

# Форматирование сообщения об ошибке
error_msg() {
    echo "❌ $1"
}

# Форматирование информационного сообщения
info_msg() {
    echo "ℹ️  $1"
}

# Сохранение результата в файл
save_result() {
    local key="$1"
    local value="$2"
    local file="$3"
    
    if [ -z "$value" ]; then
        return 1
    fi
    
    # Создать каталог, если не существует
    local dir=$(dirname "$file")
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
    
    echo "$key=$value" >> "$file"
    return 0
}

# Загрузка сохраненного значения
load_result() {
    local key="$1"
    local file="$2"
    
    if [ -f "$file" ]; then
        grep "^$key=" "$file" | cut -d'=' -f2-
    fi
}

# Проверка, что SA существует и активен
check_sa_active() {
    local sa_json="$1"
    
    if ! has_json_key "$sa_json" "enabled"; then
        return 1
    fi
    
    local enabled
    enabled=$(get_json_value "$sa_json" "enabled")
    [ "$enabled" = "true" ]
}

# Проверка формата email SA
check_sa_email_format() {
    local email="$1"
    local project_id="$2"
    
    # Email должен быть в формате: <name>@<project_id>.iam.cloud.ru
    echo "$email" | grep -q "@$project_id\.iam\.cloud\.ru$"
}

# Проверка наличия роли в ответе
check_role_exists() {
    local response="$1"
    local role_name="$2"
    
    echo "$response" | grep -q "\"role\":\"$role_name\""
}
