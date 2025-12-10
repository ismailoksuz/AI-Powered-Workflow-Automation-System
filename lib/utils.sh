#!/bin/bash

# ===============================================
# Core Utility Functions
# ===============================================

# Function: log_message
# Description: Writes a timestamped message to the central system log and console,
#              using ANSI colors for easy reading.
# Usage: log_message <LEVEL> <MESSAGE> [OPTIONS]
#   LEVEL: INFO, WARNING, ERROR, AI_QUERY, AI_RESPONSE
log_message() {
    local log_level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # log_file path is set relative to the root, which is consistent with other scripts.
    local log_file="$(dirname "$0")/../data/system.log"
    
    local console_output=true
    
    # Check for the 'silent' option to suppress console output
    if [[ "$3" == "silent" ]]; then
        console_output=false
    fi
    
    local log_line="[${timestamp}] [${log_level}] ${message}"
    
    # Always write to the log file
    echo "${log_line}" >> "${log_file}"
    
    # Print to console with color if not silent
    if [ "$console_output" = true ]; then
        case "$log_level" in
            INFO)
                echo -e "\033[0;32m[INFO]\033[0m ${message}"
                ;;
            WARNING)
                echo -e "\033[0;33m[WARNING]\033[0m ${message}" >&2
                ;;
            ERROR)
                echo -e "\033[0;31m[ERROR]\033[0m ${message}" >&2
                ;;
            AI_QUERY)
                echo -e "\033[0;34m[AI_QUERY]\033[0m ${message}"
                ;;
            AI_RESPONSE)
                echo -e "\033[0;35m[AI_RESPONSE]\033[0m ${message}"
                ;;
            *)
                echo "${log_line}"
                ;;
        esac
    fi
}