$token="ваш_токен"
$projectId="ваш_id_проекта"

curl --location 'https://iam.api.cloud.ru/api/v1/service-accounts' \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --header "Authorization: Bearer $token" \
     --data '{
       "name": "my-service-account",
       "description": "Для доступа к Managed Kubernetes API",
       "projectId": $projectId
     }'