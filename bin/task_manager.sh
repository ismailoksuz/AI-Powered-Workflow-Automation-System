#!/bin/bash

# ===============================================
# Task Management Module (CRUD Operations)
# ===============================================

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TASK_FILE="${SCRIPT_DIR}/data/tasks.json"
AI_SCRIPT="${SCRIPT_DIR}/ai/ai_query.py"
PYTHON_BIN="/Library/Frameworks/Python.framework/Versions/3.11/bin/python3"

source "${SCRIPT_DIR}/lib/utils.sh"

# Function: check_dependencies
# Description: Checks for required system tools (like jq).
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log_message ERROR "Dependency 'jq' not found. Please install jq."
        exit 1
    fi
}

# Function: initialize_task_file
# Description: Ensures the task database file exists and contains valid JSON array structure.
initialize_task_file() {
    if [ ! -f "${TASK_FILE}" ] || [ ! -s "${TASK_FILE}" ] || [ "$(cat "${TASK_FILE}" | tr -d '[:space:]')" == "" ] || [ "$(cat "${TASK_FILE}" | tr -d '[:space:]')" == "null" ]; then
        echo "[]" > "${TASK_FILE}"
        log_message INFO "Task database initialized: ${TASK_FILE}"
    fi
}

# Function: process_ai_response
# Description: Parses AI response (priority/tags) and updates the task in the database.
process_ai_response() {
    local task_id="$1"
    local ai_json_response="$2"

    local new_priority
    local new_tags
    
    # Extract priority and tags using jq
    new_priority=$(echo "${ai_json_response}" | jq -r '.priority_score // 1')
    new_tags=$(echo "${ai_json_response}" | jq -c '.tags // ["no_tags"]')

    # Check for AI error (if priority is 1 and tags is ["AI_Error"])
    if [ "${new_priority}" -eq 1 ] && [ "${new_tags}" == "[\"AI_Error\"]" ]; then
        log_message WARNING "AI prioritization failed for Task #${task_id}. Default priority (1) applied."
    else
        local updated_data=$(jq --arg id_str "$task_id" \
                                --argjson priority_val "$new_priority" \
                                --argjson tags_val "$new_tags" \
            'map(if (.id | tostring) == $id_str then (.priority = $priority_val) | (.tags = $tags_val) else . end)' "${TASK_FILE}")

        echo "${updated_data}" > "${TASK_FILE}"
        log_message AI_RESPONSE "Task #${task_id} prioritized. Priority: ${new_priority}. Tags: $(echo "${new_tags}" | jq -r 'join(", ")')"
    fi
}

# Function: add_task
# Description: Adds a new task and triggers AI prioritization.
# Usage: add_task <description>
add_task() {
    local description="$1"
    
    if [ -z "${description}" ]; then
        log_message ERROR "Task description cannot be empty."
        return 1
    fi

    check_dependencies
    initialize_task_file

    local max_id=$(jq 'map(.id) | max // 0' "${TASK_FILE}")
    local new_id=$((max_id + 1))
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    local new_task=$(jq -n \
        --argjson id "${new_id}" \
        --arg desc "${description}" \
        --arg status "Pending" \
        --arg priority 0 \
        --arg created "${timestamp}" \
        '{id: $id, description: $desc, status: $status, priority: $priority, created_at: $created}')

    local updated_data=$(jq --argjson new_task "${new_task}" '. += [$new_task]' "${TASK_FILE}")

    echo "${updated_data}" > "${TASK_FILE}"

    log_message INFO "Task #${new_id} added: '${description}' (Triggering AI for prioritization...)"
    
    # Call AI Python script using the fixed Python interpreter path
    local ai_output
    log_message AI_QUERY "Prioritizing task ${new_id}: ${description}" silent
    
    ai_output=$("${PYTHON_BIN}" "${AI_SCRIPT}" prioritize "${new_id}" "${description}")

    if [ $? -eq 0 ] && [ -n "${ai_output}" ]; then
        process_ai_response "${new_id}" "${ai_output}"
    else
        log_message ERROR "AI script failed or returned no data for Task #${new_id}."
    fi

    return 0
}

# Function: list_tasks
# Description: Displays all tasks, sorted by priority (high to low).
list_tasks() {
    check_dependencies
    initialize_task_file

    log_message INFO "Listing tasks (Sorted by Priority: High to Low)..."
    
    if [ "$(jq length "${TASK_FILE}")" -eq 0 ]; then
        echo "No tasks found."
        return 0
    fi

    jq -r '. | sort_by(.priority) | reverse | .[] | 
        "[\(.id)] \tStatus: \(.status) \tPriority: \(.priority) \tTags: \((.tags // ["N/A"]) | join(", ")) \t\t\(.description)"' "${TASK_FILE}"
}

# Function: update_task_status
# Description: Updates the status of a specific task ID.
# Usage: update_task_status <ID> <new_status>
update_task_status() {
    local task_id="$1"
    local new_status="$2"
    
    if [ -z "${task_id}" ] || [ -z "${new_status}" ]; then
        log_message ERROR "Usage: task status <ID> <new_status>"
        return 1
    fi

    check_dependencies
    initialize_task_file
    
    if [[ "$(jq --arg id_str "$task_id" 'any((.id | tostring) == $id_str)' "${TASK_FILE}")" != "true" ]]; then
        log_message ERROR "Task ID ${task_id} not found."
        return 1
    fi
    
    local updated_data=$(jq --arg id_str "$task_id" --arg status "$new_status" \
        'map(if (.id | tostring) == $id_str then .status = $status else . end)' "${TASK_FILE}")

    echo "${updated_data}" > "${TASK_FILE}"
    log_message INFO "Task #${task_id} status updated to: ${new_status}"
}

MAIN_COMMAND="$1"
shift

case "${MAIN_COMMAND}" in
    add)
        add_task "$@"
        ;;
    list)
        list_tasks
        ;;
    status)
        update_task_status "$@"
        ;;
    *)
        log_message ERROR "Invalid task command: ${MAIN_COMMAND}"
        echo "Usage: task <add|list|status>"
        ;;
esac