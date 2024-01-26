#!/usr/bin/env bash

function help_msg() {
cat << EOF
Usage: ./dltc-env-start.sh [OPTIONS]

OPTIONS:
    -h, --help      Show this message

Starts a dltc-env container. This script pulls the latest dltc-env image from Docker Hub and then uses docker compose to start the container.

EOF
}

case "$1" in
    "-h" | "--help")
        help_msg
        exit 0
        ;;
esac


############
# SETUP
############

# Check if docker is installed
if ! [ -x "$(command -v docker)" ]; then
  printf 'Error: docker is not installed.\nPlease install it and then retry.' >&2
  exit 1
fi

# Read from .env file if it exists, else exit with error
set -a
if [ -f ".env" ]; then
    . .env
else
    printf "No .env file found.\nPlease copy the .env.template file with the name ".env" and fill in the required variables.\n"
    exit 1
fi
set +a

required_env_vars=( "ARCH" "DLTC_WORKHOUSE_DIRECTORY" "DOCKERHUB_TOKEN" )

# Check if required environment variables are set
for var_name in "${required_env_vars[@]}"; do
    if [ -z "${!var_name}" ]; then
        no_env_var_msg "${var_name}"
        exit 1
    fi
done

# Check if DLTC_WORKHOUSE_DIRECTORY exists
if [ ! -d "${DLTC_WORKHOUSE_DIRECTORY}" ]; then
    printf 'Error: DLTC_WORKHOUSE_DIRECTORY does not exist.\nPlease put the path to the shared dltc-workhouse folder in Dropbox.\n' >&2
    exit 1
fi

DOCKERHUB_USERNAME=philosophiech

############
# MAIN
############

# 1. Login to dockerhub
echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin > /dev/null 2>&1
printf "Logged in to Docker Hub as ${DOCKERHUB_USERNAME}\n\n"


# 2. Pull latest dltc-env image
docker pull ${DOCKERHUB_USERNAME}/dltc-env:latest-${ARCH} && docker logout > /dev/null 2>&1
printf "\nSuccessfully pulled latest dltc-env image for ${ARCH}; now logged out of Docker Hub\n"


# 3. Start dltc-env container
# Check which of these two commands is available: docker compose or docker-compose
printf "\nStarting dltc-env container, please wait...\n"
if [ -x "$(command -v docker-compose)" ]; then
  docker-compose -f docker-compose.yml down
  docker-compose -f docker-compose.yml up -d
else
  docker compose -f docker-compose.yml down
  docker compose -f docker-compose.yml up -d
fi
printf "\n...success!\n"
