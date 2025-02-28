#!/bin/bash

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Backup configuration
SPEC_FILE="${SCRIPT_DIR}/backup_directories.conf"
DATE_FORMAT="%Y%m%d_%H%M%S"
TIMESTAMP=$(date +"${DATE_FORMAT}")

# Function to create backup
create_backup() {
    local name=${1}
    local path=${2}
    local output_dir=${3}

    # Check if directory exists
    if [ -d "${path}" ]; then
        # Create archive name
        hostname=$(hostname)
        ARCHIVE_NAME="${hostname}_${name}_${TIMESTAMP}.tar.gz"
        ARCHIVE_PATH="${output_dir}/${ARCHIVE_NAME}"

        # Create backup archive
        mkdir -p "${output_dir}"  # Ensure the output directory exists
        tar -czf "${ARCHIVE_PATH}" "${path}"
        if [ $? -eq 0 ]; then
            echo "Successfully created backup: ${ARCHIVE_NAME}"
        else
            echo "Failed to create backup for ${name}"
        fi

        # Prune old backups
        prune_backups "${output_dir}" "${name}"
    else
        echo "Directory ${path} does not exist, skipping backup"
    fi
}

# Function to prune old backups
prune_backups() {
    local output_dir=${1}
    local name=${2}

    # Find all backups for this name
    find "${output_dir}" -name "${hostname}_${name}_*.tar.gz" | while read file; do
        # Extract timestamp from filename
        file_timestamp=$(echo "${file}" | cut -d'_' -f3)
        current_timestamp=$(date -d "${file_timestamp}" +%s)
        now=$(date +%s)

        # Calculate age in days
        age=$(( (now - current_timestamp) / 86400 ))

        # Prune based on retention policy
        if [ ${age} -ge 30 ]; then
            # Older than 1 month - candidate for pruning
            if [ ${age} -ge 90 ]; then
                # Older than 3 months - remove
                rm "${file}"
                if [ $? -eq 0 ]; then
                    echo "Removed old backup: ${file}"
                fi
            else
                # Between 1 and 3 months old - keep 6 monthly backups
                monthly_count=$(find "${output_dir}" -name "${hostname}_${name}_*.tar.gz" -mtime +30 | wc -l)
                while [ ${monthly_count} -gt 6 ]; do
                    oldest_monthly=$(find "${output_dir}" -name "${hostname}_${name}_*.tar.gz" -mtime +30 -exec ls -rt {} + | head -n1)
                    rm "${oldest_monthly}"
                    if [ $? -eq 0 ]; then
                        echo "Pruned monthly backup: ${oldest_monthly}"
                    fi
                    monthly_count=$(find "${output_dir}" -name "${hostname}_${name}_*.tar.gz" -mtime +30 | wc -l)
                done
            fi
        else
            # Within the last month - keep 10 daily backups
            daily_count=$(find "${output_dir}" -name "${hostname}_${name}_*.tar.gz" | wc -l)
            while [ ${daily_count} -gt 10 ]; do
                oldest_daily=$(find "${output_dir}" -name "${hostname}_${name}_*.tar.gz" -exec ls -rt {} + | head -n1)
                rm "${oldest_daily}"
                if [ $? -eq 0 ]; then
                    echo "Pruned daily backup: ${oldest_daily}"
                fi
                daily_count=$(find "${output_dir}" -name "${hostname}_${name}_*.tar.gz" | wc -l)
            done
        fi
    done
}

# Main script execution
hostname=$(hostname)

# Read spec file and process each entry
while IFS= read -r line; do
    # Skip lines with Ansible markers
    if [[ "${line}" != *"ANSIBLE MANAGED BLOCK"* ]]; then
        # Split line into components
        components=(${line//:/ })
        if [ ${#components[@]} -eq 3 ]; then
            name=${components[0]}
            path=${components[1]}
            output_dir=${components[2]}

            # Create output directory if it doesn't exist
            mkdir -p "${output_dir}"

            # Create backup
            create_backup "${name}" "${path}" "${output_dir}"
        fi
    fi
done < "${SPEC_FILE}"
