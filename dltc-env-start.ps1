# TODO: test this script on Windows

function Help-Message {
@"
Usage: ./dltc-env-start.ps1 [OPTIONS]

OPTIONS:
    -h, --help      Show this message

Starts a dltc-env container. This script pulls the latest dltc-env image from Docker Hub and then uses docker compose to start the container.
"@
}

param (
    [switch]$help
)

if ($help) {
    Help-Message
    exit
}

# SETUP

# Check if docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: docker is not installed.`nPlease install it and then retry." -ForegroundColor Red
    exit 1
}

# Read from .env file if it exists, else exit with error
if (Test-Path .\.env) {
    Get-Content .\.env | ForEach-Object {
        $var = $_.Split('=')
        Set-Variable -Name $var[0] -Value $var[1]
    }
} else {
    Write-Host "No .env file found.`nPlease copy the .env.template file with the name '.env' and fill in the required variables." -ForegroundColor Red
    exit 1
}

$required_env_vars = "ARCH", "DLTC_WORKHOUSE_DIRECTORY", "DOCKERHUB_TOKEN"

# Check if required environment variables are set
foreach ($var_name in $required_env_vars) {
    if (-not (Get-Variable -Name $var_name -ErrorAction SilentlyContinue)) {
        Write-Host "Error: $var_name is not set.`nPlease set it in the .env file." -ForegroundColor Red
        exit 1
    }
}

# Check if DLTC_WORKHOUSE_DIRECTORY exists
if (-not (Test-Path $DLTC_WORKHOUSE_DIRECTORY)) {
    Write-Host "Error: DLTC_WORKHOUSE_DIRECTORY does not exist.`nPlease put the path to the shared dltc-workhouse folder in Dropbox." -ForegroundColor Red
    exit 1
}

$DOCKERHUB_USERNAME = "philosophiech"

# MAIN

# 1. Login to dockerhub
echo $DOCKERHUB_TOKEN | docker login -u $DOCKERHUB_USERNAME --password-stdin > $null 2>&1
Write-Host "Logged in to Docker Hub as $DOCKERHUB_USERNAME"

# 2. Pull latest dltc-env image
docker pull $DOCKERHUB_USERNAME/dltc-env:latest-$ARCH
docker logout > $null 2>&1
Write-Host "Pulled latest dltc-env image for $ARCH; logged out of Docker Hub"

# 3. Start dltc-env container
Write-Host "Starting dltc-env container..."
if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
    docker-compose -f docker-compose.yml down
    docker-compose -f docker-compose.yml up -d
} else {
    docker compose -f docker-compose.yml down
    docker compose -f docker-compose.yml up -d
}
Write-Host "...success!"