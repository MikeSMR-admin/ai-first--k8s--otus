#!/bin/bash

# Главное меню для управления сервисными аккаунтами

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загружаем конфигурацию для отображения текущих настроек
source "$SCRIPT_DIR/config--env.sh"

show_menu() {
    echo "========================================="
    echo "   Управление сервисными аккаунтами"
    echo "========================================="
    echo "1. Создать сервисный аккаунт"
    echo "2. Удалить сервисный аккаунт"
    echo "3. Показать текущую конфигурацию"
    echo "4. Выйти"
    echo "========================================="
    echo -n "Выберите действие [1-4]: "
}

show_config() {
    echo "---- Текущая конфигурация (из config--env.sh) ----"
    echo "KEY_ID: ${KEY_ID:-<не задан>}"
    echo "SECRET: ${SECRET:+<скрыто>}"
    echo "PROJECT_ID: ${PROJECT_ID:-<не задан>}"
    echo "SA_NAME: ${SA_NAME:-<не задан>}"
    echo "SA_DESCRIPTION: ${SA_DESCRIPTION:-<не задан>}"
    echo "SA_ID_TO_DELETE: ${SA_ID_TO_DELETE:-<не задан>}"
    echo "-----------------------------------------------"
}

while true; do
    show_menu
    read choice
    case $choice in
        1)
            echo ">>> Создание сервисного аккаунта..."
            "$SCRIPT_DIR/create-sa--script"
            echo "Нажмите Enter для продолжения..."
            read
            ;;
        2)
            echo ">>> Удаление сервисного аккаунта..."
            "$SCRIPT_DIR/delete-sa--script"
            echo "Нажмите Enter для продолжения..."
            read
            ;;
        3)
            show_config
            echo "Нажмите Enter для продолжения..."
            read
            ;;
        4)
            echo "Выход."
            exit 0
            ;;
        *)
            echo "Неверный выбор. Попробуйте снова."
            sleep 1
            ;;
    esac
done