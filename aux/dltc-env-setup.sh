#!/usr/bin/env bash

_target_dir="${HOME}/.dltc-env"

_root_dir="${HOME}/.dltc-env.new"
_bin_dir="${_root_dir}/bin"
_aux_dir="${_root_dir}/aux"
_docker_dir="${_root_dir}/docker"

_logs_dir="${_root_dir}/logs"
_log_file="${_logs_dir}/dltc-env-setup.log"


download_file() {
    local url=$1
    local output_path=$2

    if command -v wget > /dev/null 2>&1; then
        wget "$url" -O "$output_path" >> "${_log_file}" 2>&1
    elif command -v curl > /dev/null 2>&1; then
        curl "$url" > "$output_path" >> "${_log_file}" 2>&1
    else
        echo "Neither wget nor curl found. Please install one of those and try again. Aborting."
        exit 1
    fi

    return $?
}


############
# MAIN
############

# 1. Setup project folder
rm -rf "${_root_dir}"

mkdir -p "${_bin_dir}" && \
mkdir -p "${_aux_dir}" && \
mkdir -p "${_docker_dir}" && \
mkdir -p "${_logs_dir}" 
mkdir_status=$?

if [ "${mkdir_status}" -ne 0 ]; then
    echo "Failed to create the project's folder. Aborting." | tee -a "${_log_file}"
    exit 1
fi


# 2. Download files and make the correct ones executable
_base_url="https://raw.githubusercontent.com/Philosophie-ch/dltc-env"
_branch="simplify-use"  # change to 'master' for the latest version, when ready
_url="${_base_url}/${_branch}"

_files=( "bin/dltc-env" "aux/dltc-env-setup.sh" "aux/dltc-env-utils.sh" "docker/docker-compose.yml" "README.md" )

for file in "${_files[@]}"; do
    download_file "${_url}/${file}" "${_root_dir}/${file}"
    download_status=$?

    if [ "${download_status}" -ne 0 ]; then
        echo "Failed to download the file: '${file}'. Aborting." | tee -a "${_log_file}"
        rm -rf "${_root_dir}"
        exit 1
    fi

done

_executables=( "bin/dltc-env" "aux/dltc-env-setup.sh" "aux/dltc-env-utils.sh" )

for executable in "${_executables[@]}"; do
    chmod +x "${_root_dir}/${executable}"
    chmod_status=$?

    if [ "${chmod_status}" -ne 0 ]; then
        echo "Failed to make the file executable: '${executable}'. Aborting." | tee -a "${_log_file}"
        rm -rf "${_root_dir}"
        exit 1
    fi
done


# 3. Replace the old folder with the new one
rm -rf "${_target_dir}"
mv "${_root_dir}" "${_target_dir}"
log_file="${_target_dir}/logs/dltc-env-setup.log"
echo "DLTC-ENV-SETUP LOG" > "${log_file}"


# 4. Use the utils script to generate the .env file and the container
set -a
. "${_target_dir}/aux/dltc-env-utils.sh" "${log_file}"
set +a

gen_env_file

set_path

check_dependencies

update_image

start_dltc_env_container

#  Create a flag file to indicate that the setup was successful
touch "${_target_dir}/.dltc_setup_flag"

