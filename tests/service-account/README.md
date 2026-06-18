{"text": "# Автотесты сервисного аккаунта в cloud.ru\n\nЭтот каталог содержит автотесты для проверки создания и настройки сервисного аккаунта в cloud.ru через IAM API.\n\n## Структура тестов\n\n```\ntests/service-account/\n├── 01-create-sa-test.sh      # Тест создания сервисного аккаунта (Bash)\n├── 02-get-sa-test.sh         # Тест получения информации о SA (Bash)\n├── 03-check-role-test.sh     # Тест проверки назначения роли (Bash)\n├── run-all-tests.sh          # Скрипт для запуска всех тестов (Bash)\n├── run-tests.ps1             # Скрипт для запуска всех тестов (PowerShell - рекомендуется)\n├── utils.sh                  # Утилиты для тестов\n├── README.md                 # Эта документация\n└── results/                  # Директория для результатов тестов\n```\n\n## Требования\n\n### Для Bash-тестов:\n- Bash 4.0+\n- curl для HTTP-запросов\n- Опционально: jq для форматирования JSON\n\n### Для PowerShell-тестов (рекомендуется):\n- PowerShell 5.0+\n- curl или Invoke-RestMethod для HTTP-запросов"}

## Настройка

Перед запуском тестов убедитесь, что переменные окружения заданы в файле `config--env.sh`:

```bash
# auth--cloud-ru--for-api/config--env.sh

export KEY_ID="ваш_key_id"
export SECRET="ваш_secret"
export PROJECT_ID="ваш_project_id"
export SA_NAME="имя_сервисного_аккаунта"
export SA_DESCRIPTION="описание_сервисного_аккаунта"
```

{"text": "## Запуск тестов\n\n### Запуск всех тестов (PowerShell - рекомендуется)\n\n```powershell\ncd tests\\service-account\n.\\run-tests.ps1\n```\n\n### Запуск всех тестов (Bash)\n\n```bash\ncd tests/service-account\nchmod +x *.sh\n./run-all-tests.sh\n```\n\n### Запуск отдельного теста (PowerShell)\n\n```powershell\n# Тест 1: Создание сервисного аккаунта\n.\\run-tests.ps1 -Test 1\n\n# Тест 2: Получение информации о SA\n.\\run-tests.ps1 -Test 2\n\n# Тест 3: Проверка назначения роли\n.\\run-tests.ps1 -Test 3\n```\n\n### Запуск отдельного теста (Bash)\n\n```bash\n# Тест 1: Создание сервисного аккаунта\n./01-create-sa-test.sh\n\n# Тест 2: Получение информации о SA\n./02-get-sa-test.sh\n\n# Тест 3: Проверка назначения роли\n./03-check-role-test.sh\n```"}

## Проверки в тестах

### Тест 1: Создание SA
- HTTP-статус 200 или 201
- Присутствие обязательных полей: id, name, email, enabled
- Правильный формат email
- SA активен (enabled=true)

### Тест 2: Получение SA
- HTTP-статус 200
- Присутствие объекта service_account
- Присутствие всех обязательных полей
- ID и имя совпадают с созданным SA
- Email формат верный
- SA активен

### Тест 3: Проверка роли
- HTTP-статус 200
- Роль `platform.project.admin` назначена
- Правильные значения subjectId, subjectType, objectId, objectType

## Результаты тестов

Результаты сохраняются в `results/`:

- `create-sa-result.txt` - результаты создания SA
- `get-sa-result.txt` - результаты получения SA
- `role-result.txt` - результаты проверки роли

## Очистка

Тесты создают сервисный аккаунт для проверки. Для удаления используйте скрипт:

```bash
cd auth--cloud-ru--for-api
source config--env.sh

# Обновите SA_ID_TO_DELETE в config--env.sh или задайте вручную:
export SA_ID_TO_DELETE="id_из_результатов_теста"

./delete-sa--script.sh
```

## Интеграция с CI/CD

Добавьте в ваш CI/CD пайплайн:

```yaml
- name: Run service account tests
  run: |
    cd tests/service-account
    chmod +x *.sh
    ./run-all-tests.sh
```

## См. также

- [Документация cloud.ru по созданию SA](../../docs/cloud-ru/Создать%20сервисный%20аккаунт%20в%20cloud.ru.md)
- [Документация cloud.ru по проверке SA](../../docs/cloud-ru/Просмотреть%20сервисный%20аккаунт%20в%20cloud.ru.md)
- [API документация IAM](https://iam.api.cloud.ru/api/v1/)
