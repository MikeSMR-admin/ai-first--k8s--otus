#!/usr/bin/env pwsh
# Автотесты сервисного аккаунта на PowerShell
# Запуск: .\run-tests.ps1

# Настройка ошибок
$ErrorActionPreference = "Stop"

# Пути
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent (Split-Path -Parent $scriptDir)
$configFile = Join-Path $projectDir "auth--cloud-ru--for-api" "config--env.sh"
$tokenFile = Join-Path $projectDir "opsx" "cloud-ru-token.txt"
$resultsDir = Join-Path $scriptDir "results"

# Создание каталога для результатов
if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir | Out-Null
}

# Загрузка конфигурации
function Load-Config {
    if (-not (Test-Path $configFile)) {
        Write-Host "❌ Не найден файл конфигурации: $configFile" -ForegroundColor Red
        exit 1
    }
    
    $content = Get-Content $configFile -Raw
    
    # Извлечение переменных из config--env.sh
    $content | Select-String 'export\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"' -AllMatches | ForEach-Object {
        $_.Matches | ForEach-Object {
            $name = $_.Groups[1].Value
            $value = $_.Groups[2].Value
            Set-Variable -Name $name -Value $value -Scope Global
        }
    }
    
    Write-Host "✅ Конфигурация загружена" -ForegroundColor Green
    Write-Host "   PROJECT_ID: $PROJECT_ID" -ForegroundColor Gray
}

# Получение токена
function Get-Token {
    # Сначала проверяем наличие токена в файле
    if (Test-Path $tokenFile) {
        $token = Get-Content $tokenFile -Raw | ForEach-Object { $_.Trim() }
        if ($token -ne "" -and $token -ne $null) {
            return $token
        }
    }
    
    # Если токена нет в файле, получаем его через API
    Load-Config
    
    $url = "https://iam.api.cloud.ru/api/v1/auth/token"
    $body = @{
        keyId = $KEY_ID
        secret = $SECRET
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json"
        return $response.token
    }
    catch {
        Write-Host "❌ Ошибка получения токена: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Выполнение POST запроса
function Invoke-PostRequest {
    param(
        [string]$Endpoint,
        [string]$Data,
        [string]$Token
    )
    
    $url = "https://iam.api.cloud.ru/api/v1/$Endpoint"
    $headers = @{
        "accept" = "application/json"
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $Token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method POST -Body $Data -Headers $headers
        return @{
            StatusCode = 200
            Body = $response | ConvertTo-Json -Depth 10
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $body = $_.Exception.Response.Content.ReadAsStringAsync().Result
        return @{
            StatusCode = $statusCode
            Body = $body
        }
    }
}

# Выполнение GET запроса
function Invoke-GetRequest {
    param(
        [string]$Endpoint,
        [string]$Token
    )
    
    $url = "https://iam.api.cloud.ru/api/v1/$Endpoint"
    $headers = @{
        "accept" = "application/json"
        "Authorization" = "Bearer $Token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
        return @{
            StatusCode = 200
            Body = $response | ConvertTo-Json -Depth 10
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $body = $_.Exception.Response.Content.ReadAsStringAsync().Result
        return @{
            StatusCode = $statusCode
            Body = $body
        }
    }
}

# Извлечение значения из JSON
function Get-JsonValue {
    param(
        [string]$Json,
        [string]$Key
    )
    
    $jsonObj = $Json | ConvertFrom-Json
    return $jsonObj.$Key
}

# Проверка наличия ключа в JSON
function Has-JsonKey {
    param(
        [string]$Json,
        [string]$Key
    )
    
    $jsonObj = $Json | ConvertFrom-Json
    return $jsonObj.PSObject.Properties.Name -contains $Key
}

# Форматирование сообщения об успехе
function Success-Message {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

# Форматирование сообщения об ошибке
function Error-Message {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Форматирование информационного сообщения
function Info-Message {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

# Сохранение результата
function Save-Result {
    param(
        [string]$Key,
        [string]$Value,
        [string]$FileName = "result.txt"
    )
    
    $filePath = Join-Path $resultsDir $FileName
    Add-Content -Path $filePath -Value "$Key=$Value"
}

# Тест 1: Создание сервисного аккаунта
function Test-CreateServiceAccount {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Тест 1: Создание сервисного аккаунта" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    $token = Get-Token
    Info-Message "Токен получен"
    
    # Генерация имени SA
    $saName = "test-sa-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
    $saDescription = "Тестовый сервисный аккаунт для автотестов"
    
    $jsonData = @{
        name = $saName
        description = $saDescription
        projectId = $PROJECT_ID
    } | ConvertTo-Json -Depth 3
    
    Info-Message "Создание SA: $saName"
    
    $response = Invoke-PostRequest -Endpoint "service-accounts" -Data $jsonData -Token $token
    Info-Message "HTTP статус: $($response.StatusCode)"
    
    # Проверка HTTP статуса
    if ($response.StatusCode -notin 200, 201) {
        Error-Message "Ожидаемый статус 200 или 201, получено: $($response.StatusCode)"
        Error-Message "Ответ: $($response.Body)"
        return $false
    }
    Success-Message "HTTP статус верный: $($response.StatusCode)"
    
    # Проверка структуры ответа
    Info-Message "Проверка структуры ответа..."
    
    $body = $response.Body | ConvertFrom-Json
    
    $requiredFields = @("id", "name", "email", "enabled")
    foreach ($field in $requiredFields) {
        if (-not (Has-JsonKey $response.Body $field)) {
            Error-Message "Отсутствует поле '$field' в ответе"
            return $false
        }
    }
    Success-Message "Все обязательные поля присутствуют"
    
    # Извлечение ID
    $saId = $body.id
    $saEmail = $body.email
    Info-Message "ID созданного SA: $saId"
    
    # Сохранение результатов
    Save-Result -Key "SA_ID" -Value $saId -FileName "create-sa-result.txt"
    Save-Result -Key "SA_NAME" -Value $saName -FileName "create-sa-result.txt"
    Save-Result -Key "SA_EMAIL" -Value $saEmail -FileName "create-sa-result.txt"
    Save-Result -Key "PROJECT_ID" -Value $PROJECT_ID -FileName "create-sa-result.txt"
    Save-Result -Key "HTTP_CODE" -Value $response.StatusCode -FileName "create-sa-result.txt"
    
    Success-Message "Результаты сохранены"
    
    # Проверка email формата
    $emailPattern = "@$PROJECT_ID\.iam\.cloud\.ru$"
    if ($saEmail -notmatch $emailPattern) {
        Error-Message "Неверный формат email: $saEmail"
        return $false
    }
    Success-Message "Email формат верный: $saEmail"
    
    # Проверка, что SA активен
    if ($body.enabled -ne $true) {
        Error-Message "Сервисный аккаунт не активен"
        return $false
    }
    Success-Message "Сервисный аккаунт активен"
    
    return $true
}

# Тест 2: Получение информации о SA
function Test-GetServiceAccount {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Тест 2: Получение информации о SA" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    $token = Get-Token
    Info-Message "Токен получен"
    
    # Загрузка ID
    $resultFile = Join-Path $resultsDir "create-sa-result.txt"
    if (-not (Test-Path $resultFile)) {
        Error-Message "Файл результатов не найден: $resultFile"
        Error-Message "Запустите тест 1 первым"
        return $false
    }
    
    $content = Get-Content $resultFile -Raw
    $saId = ($content | Select-String "SA_ID=(.*)").Matches.Groups[1].Value
    
    if (-not $saId) {
        Error-Message "ID сервисного аккаунта не найден в файле результатов"
        return $false
    }
    
    Info-Message "Получение информации о SA с ID: $saId"
    
    $response = Invoke-GetRequest -Endpoint "service-accounts/$saId" -Token $token
    Info-Message "HTTP статус: $($response.StatusCode)"
    
    # Проверка HTTP статуса
    if ($response.StatusCode -ne 200) {
        Error-Message "Ожидаемый статус 200, получено: $($response.StatusCode)"
        Error-Message "Ответ: $($response.Body)"
        return $false
    }
    Success-Message "HTTP статус верный: $($response.StatusCode)"
    
    # Проверка структуры ответа
    Info-Message "Проверка структуры ответа..."
    
    $body = $response.Body | ConvertFrom-Json
    $sa = $body.service_account
    
    if (-not $sa) {
        Error-Message "Отсутствует объект service_account"
        return $false
    }
    Success-Message "Объект service_account присутствует"
    
    # Проверка обязательных полей
    $requiredFields = @("id", "name", "email", "enabled", "created_at", "updated_at")
    foreach ($field in $requiredFields) {
        if (-not ($sa.PSObject.Properties.Name -contains $field)) {
            Error-Message "Отсутствует поле '$field'"
            return $false
        }
    }
    Success-Message "Все обязательные поля присутствуют"
    
    # Проверка ID
    if ($sa.id -ne $saId) {
        Error-Message "ID не совпадает: ожидается '$saId', получено '$($sa.id)'"
        return $false
    }
    Success-Message "ID совпадает: $saId"
    
    # Проверка email
    $emailPattern = "@$PROJECT_ID\.iam\.cloud\.ru$"
    if ($sa.email -notmatch $emailPattern) {
        Error-Message "Неверный формат email: $($sa.email)"
        return $false
    }
    Success-Message "Email формат верный: $($sa.email)"
    
    # Проверка активности
    if ($sa.enabled -ne $true) {
        Error-Message "Сервисный аккаунт не активен"
        return $false
    }
    Success-Message "Сервисный аккаунт активен"
    
    # Сохранение результатов
    Save-Result -Key "SA_ID" -Value $sa.id -FileName "get-sa-result.txt"
    Save-Result -Key "SA_NAME" -Value $sa.name -FileName "get-sa-result.txt"
    Save-Result -Key "SA_EMAIL" -Value $sa.email -FileName "get-sa-result.txt"
    Save-Result -Key "SA_ENABLED" -Value $sa.enabled -FileName "get-sa-result.txt"
    Save-Result -Key "HTTP_CODE" -Value $response.StatusCode -FileName "get-sa-result.txt"
    
    Success-Message "Результаты сохранены"
    
    return $true
}

# Тест 3: Проверка роли
function Test-CheckRole {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Тест 3: Проверка назначения роли SA" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    $token = Get-Token
    Info-Message "Токен получен"
    
    # Загрузка ID
    $resultFile = Join-Path $resultsDir "create-sa-result.txt"
    $content = Get-Content $resultFile -Raw
    $saId = ($content | Select-String "SA_ID=(.*)").Matches.Groups[1].Value
    
    if (-not $saId) {
        Error-Message "ID сервисного аккаунта не найден в файле результатов"
        return $false
    }
    
    Info-Message "Проверка ролей для SA с ID: $saId"
    
    $url = "https://iam.api.cloud.ru/api/v1/permissions"
    $query = "subjectId=$saId&subjectType=service_account"
    $fullUrl = "$url?$query"
    
    $headers = @{
        "accept" = "application/json"
        "Authorization" = "Bearer $token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $fullUrl -Method GET -Headers $headers
        $statusCode = 200
        $body = $response | ConvertTo-Json -Depth 10
        
        Info-Message "HTTP статус: $statusCode"
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $body = $_.Exception.Response.Content.ReadAsStringAsync().Result
        
        Info-Message "HTTP статус: $statusCode"
        
        if ($statusCode -ne 200) {
            Error-Message "Ожидаемый статус 200, получено: $statusCode"
            Error-Message "Ответ: $body"
            return $false
        }
    }
    
    Success-Message "HTTP статус верный: $statusCode"
    
    # Проверка наличия ролей
    $permissions = $response.permissions
    
    if (-not $permissions -or $permissions.Count -eq 0) {
        Error-Message "Сервисный аккаунт не имеет ролей"
        return $false
    }
    Success-Message "Сервисный аккаунт имеет роли"
    
    # Проверка конкретной роли
    $roleName = "platform.project.admin"
    $foundRole = $permissions | Where-Object { $_.role -eq $roleName }
    
    if (-not $foundRole) {
        Error-Message "Роль '$roleName' не найдена"
        return $false
    }
    Success-Message "Роль '$roleName' назначена"
    
    # Проверка полей роли
    $requiredFields = @("subjectId", "subjectType", "objectId", "objectType")
    foreach ($field in $requiredFields) {
        if (-not ($foundRole.PSObject.Properties.Name -contains $field)) {
            Error-Message "Отсутствует поле '$field' в роли"
            return $false
        }
    }
    Success-Message "Все обязательные поля роли присутствуют"
    
    # Проверка значений
    if ($foundRole.subjectId -ne $saId) {
        Error-Message "subjectId не совпадает"
        return $false
    }
    
    if ($foundRole.subjectType -ne "service_account") {
        Error-Message "subjectType не равен 'service_account'"
        return $false
    }
    
    if ($foundRole.objectType -ne "resource") {
        Error-Message "objectType не равен 'resource'"
        return $false
    }
    
    Success-Message "Все поля роли верны"
    
    # Сохранение результатов
    Save-Result -Key "SA_ID" -Value $saId -FileName "role-result.txt"
    Save-Result -Key "ROLE_NAME" -Value $roleName -FileName "role-result.txt"
    Save-Result -Key "HTTP_CODE" -Value $statusCode -FileName "role-result.txt"
    
    Success-Message "Результаты сохранены"
    
    return $true
}

# Основная логика
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Автотесты сервисного аккаунта" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Загрузка конфигурации
Load-Config

# Запуск тестов
$tests = @(
    @{Name = "Создание SA"; Script = { Test-CreateServiceAccount }},
    @{Name = "Получение SA"; Script = { Test-GetServiceAccount }},
    @{Name = "Проверка роли"; Script = { Test-CheckRole }}
)

$passed = 0
$failed = 0

foreach ($test in $tests) {
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "Запуск: $($test.Name)" -ForegroundColor Gray
    
    if (& $test.Script) {
        $passed++
        Write-Host "✅ $($test.Name) пройден" -ForegroundColor Green
    }
    else {
        $failed++
        Write-Host "❌ $($test.Name) не пройден" -ForegroundColor Red
        break
    }
}

# Итоговый отчет
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Итоговый отчет" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Всего тестов: $($tests.Count)"
Write-Host "✅ Пройдено: $passed"
Write-Host "❌ Не пройдено: $failed"
Write-Host ""

if ($failed -eq 0) {
    Write-Host "🎉 Все тесты пройдены успешно!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Результаты сохранены в: $resultsDir"
    Write-Host ""
    Write-Host "Для просмотра результатов:"
    Write-Host "  cat $resultsDir\create-sa-result.txt"
    Write-Host "  cat $resultsDir\get-sa-result.txt"
    Write-Host "  cat $resultsDir\role-result.txt"
    exit 0
}
else {
    Write-Host "⚠️  Некоторые тесты не пройдены" -ForegroundColor Red
    exit 1
}
