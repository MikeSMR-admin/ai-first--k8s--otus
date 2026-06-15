
cd MikeSMR-admin/ai-first--k8s--otus/authentication--cloud-ru--for-api/
chmod +x get-token--script create-sa--script delete-sa--script menu--script
./menu--script.sh


# Конфигурация для работы с API Cloud.ru
# Персональный ключ доступа (или ключ от сервисного аккаунта с правами)
export KEY_ID="9526930d266bb01011a3684cd3584f16"
export SECRET=""

# ID проекта (обязателен для создания сервисного аккаунта)
export PROJECT_ID="120acc13-f4e2-471d-a896-7ba624a70b3d"

# Опционально: имя и описание создаваемого сервисного аккаунта
export SA_NAME="sa-managed-k8s-otus"
export SA_DESCRIPTION="Для управления кластером Kubernetes в рамках курса OTUS"

# ID сервисного аккаунта для удаления (если нужно удалить конкретный)
export SA_ID_TO_DELETE=""