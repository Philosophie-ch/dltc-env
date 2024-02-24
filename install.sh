#!/usr/bin/env bash

root_dir="${HOME}/.dltc-env"
bin_dir="${root_dir}/bin"

if [ -d "${root_dir}" ]; then
    rm -rf "${root_dir}"
    rm_dir_status=$?

    if [ "${rm_dir_status}" -ne 0 ]; then
        echo "Failed to remove the existing directory: ${root_dir}. Aborting."
        exit 1
    fi

fi

mkdir -p "${bin_dir}"
mkdir_status=$?

if [ "${mkdir_status}" -ne 0 ]; then
    echo "Failed to create the directory: ${bin_dir}. Aborting."
    exit 1
fi


base_url="https://raw.githubusercontent.com/Philosophie-ch/dltc-env"
branch="simplify-use"  # change to 'master' for the latest version, when ready
url="${base_url}/${branch}"

if command -v wget > /dev/null 2>&1; then
    wget "${url}/bin/dltc-env" -O "${root_dir}/bin/dltc-env" > /dev/null 2>&1
    download_status=$?

elif command -v curl > /dev/null 2>&1; then
    curl "${url}/bin/dltc-env" > "${root_dir}/bin/dltc-env" > /dev/null 2>&1
    download_status=$?

else
    echo "Neither wget nor curl found. Please install one of those and try again. Aborting."
    exit 1
fi

if [ "${download_status}" -ne 0 ]; then
    echo "Failed to download the script. Aborting."
    exit 1
fi

chmod +x "${root_dir}/bin/dltc-env"


# Add the bin directory to the PATH
PATH="${root_dir}/bin:${PATH}"

# Add bin directory to rc files if found
# and if not already present
line_to_add="export PATH=\"${root_dir}/bin:\$PATH\""
files=( "${HOME}/.bashrc" "${HOME}/.zshrc" )

for file in "${files[@]}"; do

    if [ -f "${file}" ]; then

        if ! grep -Fxq "${line_to_add}" "${file}"; then
            echo "${line_to_add}" >> "${file}"

        fi
    fi
done


