#!/usr/bin/env bash


# Setup folder with bootstrap scripts
# The project is not meant to change  the existence of bin aux, logs folders, and dltc-env and dltc-env-setup.sh files
# The rest can change and dltc-eng-setup.sh can handle for users without the need to install again

root_dir="${HOME}/.dltc-env"
bin_dir="${root_dir}/bin"
aux_dir="${root_dir}/aux"
logs_dir="${root_dir}/logs"
log_file="${logs_dir}/install.log"

if [ -d "${root_dir}" ]; then
    echo "Removing old installation..."
    rm -rf "${root_dir}"
    rm_dir_status=$?

    if [ "${rm_dir_status}" -ne 0 ]; then
        echo "Failed to remove the existing directory: ${root_dir}. Aborting."
        exit 1
    fi
    echo "Old installation removed."

fi

printf "\nCreating the directory: ${root_dir}...\n"
mkdir -p "${bin_dir}" && \
mkdir -p "${aux_dir}" && \
mkdir -p "${logs_dir}"
mkdir_status=$?

if [ "${mkdir_status}" -ne 0 ]; then
    echo "Failed to create the directory: ${bin_dir}. Aborting."
    exit 1
fi
printf "Directory created.\n"



# Download bootstrap scripts

base_url="https://raw.githubusercontent.com/Philosophie-ch/dltc-env"
branch="simplify-use"  # change to 'master' for the latest version, when ready
url="${base_url}/${branch}"

printf "\nSetting up the dltc-env command...\n"
if command -v wget > /dev/null 2>&1; then
    wget "${url}/bin/dltc-env" -O "${root_dir}/bin/dltc-env" > /dev/null 2>&1 && \
    wget "${url}/aux/dltc-env-setup.sh" -O "${root_dir}/aux/dltc-env-setup.sh" > /dev/null 2>&1
    download_status=$?

elif command -v curl > /dev/null 2>&1; then
    curl "${url}/bin/dltc-env" > "${root_dir}/bin/dltc-env" > /dev/null 2>&1 && \
    curl "${url}/aux/dltc-env-setup.sh" > "${root_dir}/aux/dltc-env-setup.sh" > /dev/null 2>&1
    download_status=$?

else
    echo "Neither wget nor curl found. Please install one of those and try again. Aborting."
    exit 1
fi

if [ "${download_status}" -ne 0 ]; then
    echo "Failed to download the script. Aborting."
    exit 1
fi
printf "...script downloaded...\n"


# Make the scripts executable and add the bin directory to the PATH

chmod +x "${root_dir}/bin/dltc-env"
chmod +x "${root_dir}/aux/dltc-env-setup.sh"

# Add the bin directory to the PATH
PATH="${root_dir}/bin:${PATH}"

# Add bin directory to rc files if found
# and if not already present
line_to_add="export PATH=\"${root_dir}/bin:\$PATH\""
files=( "${HOME}/.bashrc" "${HOME}/.zshrc" )

for file in "${files[@]}"; do

    if [ -f "${file}" ]; then

        if ! grep -Fxq "${line_to_add}" "${file}"; then
            echo "" >> "${file}"
            echo "${line_to_add}" >> "${file}"
            echo "" >> "${file}"

            echo "Appended '${line_to_add}' to ${file}."

        else
            printf "\nThe line ${line_to_add} is already present in ${file}. Everything is correct, no modification needed.\n"

        fi
    fi
done


# Execute the setup script to finalize bootstrapping
printf "\nExecuting 'dltc-env setup'...\n" | tee -a "${log_file}"

"${root_dir}/aux/dltc-env-setup.sh"
setup_status=$?

if [ "${setup_status}" -ne 0 ]; then
    echo "Failed to execute 'dltc-env setup'. Aborting. Please check the log file at ${log_file} for more information and contact the IT responsible if needed."
    exit 1
fi

printf "dltc-env setup executed successfully.\n" | tee -a "${log_file}"


cat << EOF

dltc-env command successfully installed. Please open a new terminal and do

dltc-env help

to see the available commands and how to use them.


EOF


