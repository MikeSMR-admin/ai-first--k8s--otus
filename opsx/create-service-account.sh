#!/bin/bash
#
# Script for creating a service account in cloud.ru
# Usage: ./create-service-account.sh [--name SERVICE_ACCOUNT_NAME] [--project-id PROJECT_ID] [--token AUTH_TOKEN]
#
# Environment variables:
#   SERVICE_ACCOUNT_NAME - Name of the service account (default: my-service-account)
#   PROJECT_ID - Project ID where service account will be created (required)
#   AUTH_TOKEN - IAM authentication token (required)
#

set -e

# Default values
DEFAULT_SERVICE_ACCOUNT_NAME="my-service-account"
CLOUD_IAM_API="https://iam.api.cloud.ru/api/v1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-$DEFAULT_SERVICE_ACCOUNT_NAME}"
PROJECT_ID=""
AUTH_TOKEN=""

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 [options]"
    echo ""
    echo "Options:"
    echo "  -n, --name SERVICE_ACCOUNT_NAME   Name of the service account (default: $DEFAULT_SERVICE_ACCOUNT_NAME)"
    echo "  -p, --project-id PROJECT_ID       Project ID (required)"
    echo "  -t, --token AUTH_TOKEN            IAM authentication token (required)"
    echo "  -h, --help                        Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  SERVICE_ACCOUNT_NAME              Name of the service account"
    echo "  PROJECT_ID                        Project ID"
    echo "  AUTH_TOKEN                        IAM authentication token"
    echo ""
    echo "Example:"
    echo "  export SERVICE_ACCOUNT_NAME=\"my-sa\""
    echo "  export PROJECT_ID=\"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\""
    echo "  export AUTH_TOKEN=\"eyJhbGci...\""
    echo "  ./create-service-account.sh"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            SERVICE_ACCOUNT_NAME="$2"
            shift 2
            ;;
        -p|--project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        -t|--token)
            AUTH_TOKEN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}Error: PROJECT_ID is required${NC}"
    usage
fi

if [[ -z "$AUTH_TOKEN" ]]; then
    echo -e "${RED}Error: AUTH_TOKEN is required${NC}"
    usage
fi

# Function to make API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    local curl_cmd="curl.exe -s -X $method \"$CLOUD_IAM_API$endpoint\""
    curl_cmd="$curl_cmd --header 'accept: application/json'"
    curl_cmd="$curl_cmd --header 'Content-Type: application/json'"
    curl_cmd="$curl_cmd --header \"Authorization: Bearer $AUTH_TOKEN\""
    
    if [[ -n "$data" ]]; then
        curl_cmd="$curl_cmd --data '$data'"
    fi
    
    eval "$curl_cmd"
}

# Function to check if service account exists
check_service_account_exists() {
    local name=$1
    
    echo -e "${YELLOW}Checking if service account '$name' exists...${NC}"
    
    local response
    response=$(api_call "GET" "/service-accounts")
    
    if [[ -z "$response" ]]; then
        echo -e "${RED}Error: Failed to fetch service accounts list${NC}"
        return 1
    fi
    
    # Check if service account with given name exists
    if echo "$response" | grep -q "\"name\": \"$name\""; then
        echo -e "${GREEN}Service account '$name' already exists!${NC}"
        return 0
    else
        echo -e "${YELLOW}Service account '$name' does not exist. Creating it...${NC}"
        return 1
    fi
}

# Function to create service account
create_service_account() {
    local name=$1
    local project_id=$2
    
    echo -e "${YELLOW}Creating service account '$name'...${NC}"
    
    local data="{\"name\": \"$name\", \"description\": \"Service account created via API\", \"projectId\": \"$project_id\"}"
    
    local response
    response=$(api_call "POST" "/service-accounts" "$data")
    
    if [[ -z "$response" ]]; then
        echo -e "${RED}Error: Failed to create service account${NC}"
        return 1
    fi
    
    # Extract service account ID from response
    local sa_id
    sa_id=$(echo "$response" | grep -o '"id": "[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [[ -z "$sa_id" ]]; then
        echo -e "${RED}Error: Failed to extract service account ID from response${NC}"
        echo "Response: $response"
        return 1
    fi
    
    echo -e "${GREEN}Service account created successfully!${NC}"
    echo -e "${GREEN}Service Account ID: $sa_id${NC}"
    
    echo "$sa_id"
}

# Function to assign role to service account
assign_role() {
    local sa_id=$1
    local project_id=$2
    
    echo -e "${YELLOW}Assigning role 'platform.project.admin' to service account...${NC}"
    
    local data="{\"role\": \"platform.project.admin\", \"objectId\": \"$project_id\", \"objectType\": \"resource\", \"subjectId\": \"$sa_id\", \"subjectType\": \"service_account\", \"expiresAt\": \"2025-12-31T23:59:59Z\"}"
    
    local response
    response=$(api_call "POST" "/permissions" "$data")
    
    if [[ -z "$response" ]]; then
        echo -e "${RED}Error: Failed to assign role to service account${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Role assigned successfully!${NC}"
    echo "$response"
}

# Function to create access key for service account
create_access_key() {
    local sa_id=$1
    
    echo -e "${YELLOW}Creating access key for service account...${NC}"
    
    local description="Access key for $sa_id"
    local data="{\"serviceAccountId\": \"$sa_id\", \"description\": \"$description\", \"ttl\": \"8760h\"}"
    
    local response
    response=$(api_call "POST" "/service-accounts/credentials/access-keys" "$data")
    
    if [[ -z "$response" ]]; then
        echo -e "${RED}Error: Failed to create access key${NC}"
        return 1
    fi
    
    # Extract key details from response
    local key_id
    key_id=$(echo "$response" | grep -o '"key_id": "[^"]*"' | cut -d'"' -f4)
    
    local secret
    secret=$(echo "$response" | grep -o '"secret": "[^"]*"' | cut -d'"' -f4)
    
    local created_at
    created_at=$(echo "$response" | grep -o '"created_at": "[^"]*"' | cut -d'"' -f4)
    
    local expired_at
    expired_at=$(echo "$response" | grep -o '"expired_at": "[^"]*"' | cut -d'"' -f4)
    
    echo -e "${GREEN}Access key created successfully!${NC}"
    echo -e "${GREEN}Key ID: $key_id${NC}"
    echo -e "${YELLOW}Secret: $secret (save this securely!)${NC}"
    echo -e "${GREEN}Created at: $created_at${NC}"
    echo -e "${GREEN}Expires at: $expired_at${NC}"
    
    # Save credentials to file
    local credentials_file="service-account-credentials-${sa_id}.txt"
    cat > "$credentials_file" << EOF
Service Account Credentials
===========================
Service Account ID: $sa_id
Key ID: $key_id
Secret: $secret
Created at: $created_at
Expires at: $expired_at
EOF
    
    echo -e "${GREEN}Credentials saved to: $credentials_file${NC}"
}

# Main execution
echo "=========================================="
echo "Service Account Creation Script"
echo "=========================================="
echo "Service Account Name: $SERVICE_ACCOUNT_NAME"
echo "Project ID: $PROJECT_ID"
echo "=========================================="

# Check if service account exists
if check_service_account_exists "$SERVICE_ACCOUNT_NAME"; then
    # Service account already exists, get its ID
    echo -e "${YELLOW}Fetching existing service account details...${NC}"
    
    local response
    response=$(api_call "GET" "/service-accounts")
    
    # Extract service account ID
    local sa_id
    sa_id=$(echo "$response" | grep -A5 "\"name\": \"$SERVICE_ACCOUNT_NAME\"" | grep -o '"id": "[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [[ -z "$sa_id" ]]; then
        echo -e "${RED}Error: Failed to extract service account ID${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Existing Service Account ID: $sa_id${NC}"
    
    # Check if role is assigned
    echo -e "${YELLOW}Checking role assignment...${NC}"
    
    local perm_response
    perm_response=$(api_call "GET" "/permissions?subjectId=$sa_id&subjectType=service_account")
    
    if echo "$perm_response" | grep -q '"role": "platform.project.admin"'; then
        echo -e "${GREEN}Role 'platform.project.admin' is already assigned${NC}"
    else
        echo -e "${YELLOW}Role 'platform.project.admin' is not assigned. Assigning it...${NC}"
        assign_role "$sa_id" "$PROJECT_ID"
    fi
    
    # Check if access key exists
    echo -e "${YELLOW}Checking access keys...${NC}"
    
    local keys_response
    keys_response=$(api_call "GET" "/service-accounts/$sa_id/credentials/access-keys")
    
    if [[ -z "$keys_response" ]] || [[ "$keys_response" == "[]" ]]; then
        echo -e "${YELLOW}No access keys found. Creating one...${NC}"
        create_access_key "$sa_id"
    else
        echo -e "${GREEN}Access keys already exist:${NC}"
        echo "$keys_response"
    fi
else
    # Service account doesn't exist, create it
    sa_id=$(create_service_account "$SERVICE_ACCOUNT_NAME" "$PROJECT_ID")
    
    if [[ -n "$sa_id" ]]; then
        # Assign role
        assign_role "$sa_id" "$PROJECT_ID"
        
        # Create access key
        create_access_key "$sa_id"
        
        echo "=========================================="
        echo -e "${GREEN}Service account created successfully!${NC}"
        echo "=========================================="
    else
        echo -e "${RED}Failed to create service account${NC}"
        exit 1
    fi
fi
