#!/usr/bin/env bash

version="0.1.0"
root_dir="${HOME}/.dltc-env"
bin_dir="${root_dir}/bin"
aux_dir="${root_dir}/aux"
docker_dir="${root_dir}/docker"
logs_dir="${root_dir}/logs"

ex_log_file="${1}"

if [ -z "${ex_log_file}" ]; then
    echo "utils: No log file passed as argument. Exiting."
    exit 1
fi


function check_dependencies() {

    local error_messages=

    local cmd_arr=( "docker" )
    for cmd in "${cmd_arr[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            error_messages+="Missing dependency: ${cmd} is not installed or not in the PATH. Exiting.\n"
        fi
    done

    if ! docker compose version &> /dev/null; then
        error_messages+="Missing dependency: docker-compose is not installed or not in the PATH. Exiting.\n"
    fi

    if [ ! -z "${error_messages}" ]; then
        error_messages+="\n${_name}: Aborting. Please install the missing dependencies and try again.\n\n"    
        printf "${error_messages}" | tee -a "${ex_log_file}"
        exit 1
    fi

}


# Generate .env file
function gen_env_file() {

    echo "Generating .env file. Please wait, this might take a couple minutes..." | tee -a "${ex_log_file}"

    # Match with the shared's folder information
    local hash_file="philosophie_19a0b9d5e59d915021f676c9c2cc85d4204c14fc57e094bb8ba991c30116bde420240224013009" 
    local dockerhub_token_file="dh"
    local dockerhub_username="philosophiech"


    # 1. Architecture
    echo "Checking architecture..."
    local arch_uname=$( uname -m )

    if [ "${arch_uname}" == "x86_64" ]; then
        local arch="amd64"
    elif [ "${arch_uname}" == "aarch64" ]; then
        local arch="arm64"
    else
        echo "Unsupported architecture: ${arch_uname}"
        exit 1
    fi
    echo "Architecture: '${arch}'"

    # 2. dltc-workhouse directory
    echo "Looking for the 'dltc-workhouse' folder..."
    local hash_path=$( find "${HOME}" -name "${hash_file}" )
    local hash_dir=$( dirname "${hash_path}" )

    local dltc_workhouse_directory=$( dirname "${hash_dir}" )
    echo "dltc-workhouse directory's path: '${dltc_workhouse_directory}'"

    # 3. Dockerhub token
    echo "Looking for the dockerhub token..."
    local dockerhub_token=$( cat "${hash_dir}/${dockerhub_token_file}" )

    if [ -z "${dockerhub_token}" ]; then
        echo "Dockerhub token not found. Please contact the IT responsible. Aborting."
        exit 1
    fi
    echo "Dockerhub token found."


    # Repristine the .env file
    echo "ARCH=\"${arch}\"" > "${docker_dir}/.env" && \
    echo "DLTC_WORKHOUSE_DIRECTORY=\"${dltc_workhouse_directory}\"" >> "${docker_dir}/.env" && \
    echo "DOCKERHUB_USERNAME=\"${dockerhub_username}\"" >> "${docker_dir}/.env" && \
    echo "DOCKERHUB_TOKEN=\"${dockerhub_token}\"" >> "${docker_dir}/.env"
    gen_env_file_status=$?

    if [ "${gen_env_file_status}" -ne 0 ]; then
        echo "Failed to generate the .env file. Aborting." | tee -a "${ex_log_file}"
        exit 1
    fi

    echo "The .env file has been generated successfully." | tee -a "${ex_log_file}"

}

function load_env_file() {

    env_file="${docker_dir}/.env"

    if [ ! -f "${env_file}" ]; then
        echo "No .env file found. Generating one..." | tee -a "${ex_log_file}"
        gen_env_file
    fi


    echo "Loading .env file..." >> "${ex_log_file}"

    set -a
    . "${env_file}"
    local load_env_file_status=$?

    if [ "${load_env_file_status}" -ne 0 ]; then
        echo "Failed to load the .env file. Aborting." | tee -a "${ex_log_file}"
        set +a
        exit 1
    fi

    set +a

    echo "The .env file has been loaded successfully." >> "${ex_log_file}"
}


function check_env_vars() {
    
    load_env_file
    local fail_flag=0

    local required_env_vars=( "ARCH" "DLTC_WORKHOUSE_DIRECTORY" "DOCKERHUB_USERNAME" "DOCKERHUB_TOKEN" )

    # Check if required environment variables are set
    for var_name in "${required_env_vars[@]}"; do
        if [ -z "${!var_name}" ]; then
            echo "Error: the environment variable '${var_name}' is not set."
            fail_flag=1
        fi
    done


    # Check if ARCH is set to "arm64" or "amd64"
    if [ "${ARCH}" != "arm64" ] && [ "${ARCH}" != "amd64" ]; then
        echo "ARCH is not set to 'arm64' or 'amd64'."
        fail_flag=1
        
    fi

    # Check if DLTC_WORKHOUSE_DIRECTORY exists
    if [ ! -d "${DLTC_WORKHOUSE_DIRECTORY}" ]; then
        echo "DLTC_WORKHOUSE_DIRECTORY does not exist."
        fail_flag=1
    fi


    if [ "${fail_flag}" -eq 1 ]; then
        echo "The .env file is not correctly set. Generating a new one..."
        gen_env_file
    fi

    printf "All dependencies found, and environment variables are all correctly set.\n\n" >> "${ex_log_file}"


}


function update_image() {

    check_env_vars

    local DOCKER_IMAGE_NAME_TAG="${DOCKERHUB_USERNAME}/dltc-env:latest-${ARCH}"

    printf "\nUpdating the dltc-env image. If it's the first time or there is an important update, this might take a while. Please wait...\n\n" | tee -a "${ex_log_file}"

    printf "1. Log in to Docker Hub\n\n" >> "${ex_log_file}"

    echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin >> "${ex_log_file}" 2>&1
    local login_status=$?

    if [ ${login_status} -ne 0 ]; then
        printf "Error: Could not log in to Docker Hub.\nPlease check the log file at ${ex_log_file} for more information.\n"
        exit 1
    fi

    printf "Logged in to Docker Hub as ${DOCKERHUB_USERNAME}\n\n" >> "${ex_log_file}"


    # 2. Pull latest dltc-env image
    printf "2. Pull latest dltc-env image for ${ARCH}\n\n" >> "${ex_log_file}"

    docker pull "${DOCKER_IMAGE_NAME_TAG}" >> "${ex_log_file}" 2>&1
    local pull_status=$?
    echo "" >> "${ex_log_file}"

    if [ ${pull_status} -ne 0 ]; then
        printf "Error: Could not pull latest dltc-env image for ${ARCH}.\nPlease check the log file at ${ex_log_file} for more information.\n"
        exit 1
    fi

    # 3. Assert it's actually there
    docker inspect --type=image "${DOCKER_IMAGE_NAME_TAG}" > /dev/null 2>&1
    local inspect_status=$?

    if [ ${inspect_status} -ne 0 ]; then
        printf "Error: Could not find the dltc-env image locally.\nPlease check the log file at ${ex_log_file} for more information.\n"
        exit 1
    fi
    printf "${DOCKER_IMAGE_NAME_TAG} image found locally.\n\n" >> "${ex_log_file}"

    # 4. Log out from Docker Hub
    docker logout >> "${ex_log_file}" 2>&1
    echo "" >> "${ex_log_file}"


    # 5. Repristine container
    printf "5. Repristine containers\n\n" >> "${ex_log_file}"
    local compose_file="${docker_dir}/docker-compose.yml"

    if [ -x "$(command -v docker-compose)" ]; then
        docker-compose -f "${compose_file}" down >> "${ex_log_file}" 2>&1 && \
        docker-compose -f "${compose_file}" up -d >> "${ex_log_file}" 2>&1
        local compose_status=$?
    else
        docker compose -f "${compose_file}" down >> "${ex_log_file}" 2>&1 && \
        docker compose -f "${compose_file}" up -d >> "${ex_log_file}" 2>&1
        local compose_status=$?
    fi
    echo "" >> "${ex_log_file}"

    if [ ${compose_status} -ne 0 ]; then
        printf "Error: Could not start dltc-env container.\nPlease check the log file at ${ex_log_file} for more information.\n"
        exit 1
    fi

    printf "The dltc-env image has been updated successfully.\n\n" | tee -a "${ex_log_file}"

}


function start_dltc_env_container() {

    printf "Starting the dltc-env container, please wait...\n\n" | tee -a "${ex_log_file}"

    check_env_vars

    local DOCKER_IMAGE_NAME_TAG="${DOCKERHUB_USERNAME}/dltc-env:latest-${ARCH}"

    # 1. Assert image is actually there
    printf "1. Assert the dltc-env image is actually there\n\n" >> "${ex_log_file}"
    docker inspect --type=image "${DOCKER_IMAGE_NAME_TAG}" > /dev/null 2>&1
    local inspect_status=$?

    # 1.1 Update image if not found
    if [ ${inspect_status} -ne 0 ]; then
        printf "Could not find the dltc-env image locally. Pulling the latest one...\n\n" | tee -a "${ex_log_file}"
        update_image
    fi

    printf "'${DOCKER_IMAGE_NAME_TAG}' image found locally.\n\n" >> "${ex_log_file}"


    # 2. Start dltc-env container
    printf "2. Start the container\n\n" >> "${ex_log_file}"
    local compose_file="${docker_dir}/docker-compose.yml"

    if [ -x "$(command -v docker-compose)" ]; then
        docker-compose -f "${compose_file}" restart >> "${ex_log_file}" 2>&1
        local compose_status=$?
    else
        docker compose -f "${compose_file}" restart >> "${ex_log_file}" 2>&1 
        local compose_status=$?
    fi
    echo "" >> "${ex_log_file}"

    if [ ${compose_status} -ne 0 ]; then
        printf "Error: Could not start dltc-env container.\nPlease check the log file at ${ex_log_file} for more information.\n"
        exit 1
    fi


    printf "\n...container started successfully!\n" | tee -a "${ex_log_file}"

}

function stop_dltc_env_container() {

    printf "Stopping the dltc-env container, please wait...\n\n" | tee -a "${ex_log_file}"

    check_env_vars

    local compose_file="${docker_dir}/docker-compose.yml"

    if [ -x "$(command -v docker-compose)" ]; then
        docker-compose -f "${compose_file}" stop >> "${ex_log_file}" 2>&1
        local compose_status=$?
    else
        docker compose -f "${compose_file}" stop >> "${ex_log_file}" 2>&1
        local compose_status=$?
    fi
    echo "" >> "${ex_log_file}"

    if [ ${compose_status} -ne 0 ]; then
        printf "Error: Could not stop dltc-env container.\nPlease check the log file at ${ex_log_file} for more information.\n"
        exit 1
    fi

    printf "\n...container stopped successfully!\n" | tee -a "${ex_log_file}"
    echo "To start the container again, run 'dltc-env start'."

}


function set_path() {

    PATH="${root_dir}/bin:${PATH}"

    # Add bin directory to rc files if found
    # and if not already present
    local line_to_add="export PATH=\"${root_dir}/bin:\$PATH\""
    local files=( "${HOME}/.bashrc" "${HOME}/.zshrc" )

    for file in "${files[@]}"; do

        if [ -f "${file}" ]; then

            if ! grep -Fxq "${line_to_add}" "${file}"; then
                echo "" >> "${file}"
                echo "${line_to_add}" >> "${file}"
                echo "" >> "${file}"

                echo "Appended '${line_to_add}' to ${file}."

            fi
        fi
    done

}