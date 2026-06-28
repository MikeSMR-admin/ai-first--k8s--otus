# Развёртывание Kubernetes-кластера в Cloud.ru

## Требования
- Установленный Terraform (≥ 1.0)
- PowerShell (для Windows)
- Файл `.env` с заполненными переменными находится здесь: infrastructure\terraform\.env

## Шаги перед запуском скриптов terraform

1. **Загрузить переменные окружения:**
   ```powershell
   infrastructure\terraform\load-env.ps1