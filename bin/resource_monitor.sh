#!/bin/bash

# ===============================================
# System Resource Monitoring Module
# ===============================================

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "${SCRIPT_DIR}/lib/utils.sh"

MAX_CPU_THRESHOLD=80
MAX_RAM_THRESHOLD=90
OLLAMA_SERVICE_NAME="ollama"

# Function: get_cpu_usage
# Description: Calculates the current system CPU usage percentage (on macOS/BSD).
get_cpu_usage() {
    if command -v top > /dev/null; then
        # Extracts idle CPU percentage from 'top' command output
        local idle_cpu=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | sed 's/[^0-9.]*//g')
        if [ -n "$idle_cpu" ]; then
            echo "scale=2; 100 - ${idle_cpu}" | bc
            return 0
        fi
    fi

    log_message WARNING "Cannot reliably determine CPU usage. Returning 0." silent
    echo 0
}

# Function: get_ram_usage
# Description: Calculates the current system RAM usage percentage (on macOS/BSD).
get_ram_usage() {
    
    if command -v top > /dev/null; then
        # Use sysctl to get active and total memory pages for accurate percentage
        local used_percent=$(sysctl vm.pages | grep "pages active" | awk '{print $3}')
        local total_percent=$(sysctl vm.pages | grep "pages total" | awk '{print $3}')
        
        if [ -n "$used_percent" ] && [ -n "$total_percent" ] && [ "$total_percent" -gt 0 ]; then
            echo "scale=0; ${used_percent} * 100 / ${total_percent}" | bc
            return 0
        fi
    fi

    log_message WARNING "Cannot reliably determine RAM usage. Returning 0." silent
    echo 0
}

# Function: manage_ollama_resources
# Description: Checks current CPU usage and dynamically adjusts Ollama process niceness/priority.
manage_ollama_resources() {
    local ollama_pids=$(pgrep -f "${OLLAMA_SERVICE_NAME}")
    
    if [ -n "${ollama_pids}" ]; then
        local current_cpu=$(get_cpu_usage)
        
        if (( $(echo "$current_cpu > $MAX_CPU_THRESHOLD" | bc -l) )); then
            local new_niceness=+10 # Lower priority
            log_message WARNING "High CPU (${current_cpu}%). Lowering priority of all Ollama PIDs (nice ${new_niceness})."
        else
            local new_niceness=0 # Normal priority
        fi

        echo "${ollama_pids}" | while IFS= read -r pid; do
            if [ -n "$pid" ]; then
                log_message INFO "Managing Ollama PID: ${pid}" silent
                renice "${new_niceness}" -p "${pid}" 2>/dev/null
            fi
        done
    else
        log_message WARNING "Ollama service process not detected." silent
    fi
}

# Function: monitor_daemon
# Description: Main loop that periodically checks resources and calls the manager.
# Usage: resource monitor
monitor_daemon() {
    local interval=10 

    log_message INFO "Resource monitoring daemon started (Interval: ${interval}s)."

    while true; do
        current_cpu=$(get_cpu_usage)
        current_ram=$(get_ram_usage)
        
        log_message INFO "Resources: CPU=${current_cpu}%, RAM=${current_ram}%" silent
        
        manage_ollama_resources

        sleep ${interval}
    done
}

COMMAND="$1"
shift

case "${COMMAND}" in
    monitor)
        monitor_daemon
        ;;
    *)
        log_message ERROR "Invalid resource command: ${COMMAND}. Usage: resource monitor"
        ;;
esac