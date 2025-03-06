#!/bin/bash

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Backup configuration
SPEC_FILE="${SCRIPT_DIR}/backup_directories.conf"
DATE_FORMAT="%Y%m%d_%H%M%S"
TIMESTAMP=$(date +"${DATE_FORMAT}")
DAY_OF_WEEK=$(date +%u)  # 1-7, where 1 is Monday
DAY_OF_MONTH=$(date +%d)  # 01-31

# Function to create backup
create_backup() {
    local name=${1}
    local path=${2}
    local output_dir=${3}

    # Check if directory exists
    if [ -d "${path}" ]; then
        # Create base archive name
        BASE_ARCHIVE_NAME="${hostname}_${name}_${TIMESTAMP}.tar.gz"

        # Create daily backup
        DAILY_DIR="${output_dir}/daily"
        mkdir -p "${DAILY_DIR}"
        DAILY_ARCHIVE_PATH="${DAILY_DIR}/${BASE_ARCHIVE_NAME}"

        # Create backup archive
        tar -czf "${DAILY_ARCHIVE_PATH}" "${path}"
        if [ $? -eq 0 ]; then
            echo "Successfully created daily backup: ${DAILY_ARCHIVE_PATH}"

            # Create weekly backup (on Sunday, day 7)
            if [ "${DAY_OF_WEEK}" = "7" ]; then
                WEEKLY_DIR="${output_dir}/weekly"
                mkdir -p "${WEEKLY_DIR}"
                WEEKLY_ARCHIVE_PATH="${WEEKLY_DIR}/${BASE_ARCHIVE_NAME}"
                cp "${DAILY_ARCHIVE_PATH}" "${WEEKLY_ARCHIVE_PATH}"
                echo "Created weekly backup: ${WEEKLY_ARCHIVE_PATH}"
            fi

            # Create monthly backup (on 1st day of month)
            if [ "${DAY_OF_MONTH}" = "01" ]; then
                MONTHLY_DIR="${output_dir}/monthly"
                mkdir -p "${MONTHLY_DIR}"
                MONTHLY_ARCHIVE_PATH="${MONTHLY_DIR}/${BASE_ARCHIVE_NAME}"
                cp "${DAILY_ARCHIVE_PATH}" "${MONTHLY_ARCHIVE_PATH}"
                echo "Created monthly backup: ${MONTHLY_ARCHIVE_PATH}"
            fi
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

    echo "Pruning backups for ${hostname}_${name} in ${output_dir}"

    # Retention policy:
    # - Daily: Keep last 10 days
    # - Weekly: Keep last 8 weeks
    # - Monthly: Keep last 12 months

    # Prune daily backups (keep last 10)
    DAILY_DIR="${output_dir}/daily"
    if [ -d "${DAILY_DIR}" ]; then
        echo "Pruning daily backups..."
        # Count daily backups
        daily_count=$(find "${DAILY_DIR}" -name "${hostname}_${name}_*.tar.gz" | wc -l)

        if [ ${daily_count} -gt 10 ]; then
            # Get all daily files sorted by modification time (oldest first)
            mapfile -t daily_files < <(find "${DAILY_DIR}" -name "${hostname}_${name}_*.tar.gz" -print0 | xargs -0 ls -t | tac)

            # Remove oldest files, keeping only the 10 newest
            for ((i=0; i<${#daily_files[@]}-10; i++)); do
                rm "${daily_files[$i]}"
                if [ $? -eq 0 ]; then
                    echo "Pruned excess daily backup: ${daily_files[$i]}"
                fi
            done
        fi
    fi

    # Prune weekly backups (keep last 8)
    WEEKLY_DIR="${output_dir}/weekly"
    if [ -d "${WEEKLY_DIR}" ]; then
        echo "Pruning weekly backups..."
        # Count weekly backups
        weekly_count=$(find "${WEEKLY_DIR}" -name "${hostname}_${name}_*.tar.gz" | wc -l)

        if [ ${weekly_count} -gt 8 ]; then
            # Get all weekly files sorted by modification time (oldest first)
            mapfile -t weekly_files < <(find "${WEEKLY_DIR}" -name "${hostname}_${name}_*.tar.gz" -print0 | xargs -0 ls -t | tac)

            # Remove oldest files, keeping only the 8 newest
            for ((i=0; i<${#weekly_files[@]}-8; i++)); do
                rm "${weekly_files[$i]}"
                if [ $? -eq 0 ]; then
                    echo "Pruned excess weekly backup: ${weekly_files[$i]}"
                fi
            done
        fi
    fi

    # Prune monthly backups (keep last 12)
    MONTHLY_DIR="${output_dir}/monthly"
    if [ -d "${MONTHLY_DIR}" ]; then
        echo "Pruning monthly backups..."
        # Count monthly backups
        monthly_count=$(find "${MONTHLY_DIR}" -name "${hostname}_${name}_*.tar.gz" | wc -l)

        if [ ${monthly_count} -gt 12 ]; then
            # Get all monthly files sorted by modification time (oldest first)
            mapfile -t monthly_files < <(find "${MONTHLY_DIR}" -name "${hostname}_${name}_*.tar.gz" -print0 | xargs -0 ls -t | tac)

            # Remove oldest files, keeping only the 12 newest
            for ((i=0; i<${#monthly_files[@]}-12; i++)); do
                rm "${monthly_files[$i]}"
                if [ $? -eq 0 ]; then
                    echo "Pruned excess monthly backup: ${monthly_files[$i]}"
                fi
            done
        fi
    fi
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

            # Create backup
            create_backup "${name}" "${path}" "${output_dir}"
        fi
    fi
done < "${SPEC_FILE}"
