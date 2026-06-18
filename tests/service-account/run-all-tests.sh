#!/bin/bash
# Скрипт запуска всех тестов сервисного аккаунта

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================="
echo "Запуск автотестов сервисного аккаунта"
echo "=============================================="
echo ""

# Проверка, что конфигурация загружена
if [ -z "$PROJECT_ID" ] || [ -z "$KEY_ID" ] || [ -z "$SECRET" ]; then
    echo "⚠️  Переменные окружения PROJECT_ID, KEY_ID или SECRET не заданы"
    echo "Загрузка конфигурации..."
    source "$SCRIPT_DIR/../auth--cloud-ru--for-api/config--env.sh" 2>/dev/null || {
        echo "❌ Не удалось загрузить конфигурацию"
        exit 1
    }
fi

echo "Configuration:"
echo "  PROJECT_ID: $PROJECT_ID"
echo "  KEY_ID: $KEY_ID"
echo ""

# Создание каталога для результатов
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"

# Запуск тестов по порядку
TESTS=(
    "01-create-sa-test.sh"
    "02-get-sa-test.sh"
    "03-check-role-test.sh"
)

PASSED=0
FAILED=0

for test in "${TESTS[@]}"; do
    echo ""
    echo "=============================================="
    echo "Запуск: $test"
    echo "=============================================="
    
    if bash "$SCRIPT_DIR/$test"; then
        ((PASSED++))
        echo "✅ $test пройден"
    else
        ((FAILED++))
        echo "❌ $test не пройден"
        if [ "$FAILED" -gt 0 ]; then
            echo ""
            echo "Тесты остановлены из-за ошибки"
            break
        fi
    fi
    
    echo ""
done

# Итоговый отчет
echo ""
echo "=============================================="
echo "Итоговый отчет"
echo "=============================================="
echo "Всего тестов: ${#TESTS[@]}"
echo "✅ Пройдено: $PASSED"
echo "❌ Не пройдено: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 Все тесты пройдены успешно!"
    echo ""
    echo "Результаты сохранены в: $RESULTS_DIR"
    echo ""
    echo "Для просмотра результатов выполните:"
    echo "  cat $RESULTS_DIR/create-sa-result.txt"
    echo "  cat $RESULTS_DIR/get-sa-result.txt"
    echo "  cat $RESULTS_DIR/role-result.txt"
    exit 0
else
    echo "⚠️  Некоторые тесты не пройдены"
    exit 1
fi
