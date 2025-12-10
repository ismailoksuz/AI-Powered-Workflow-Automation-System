# AI Powered Workflow Automation System (AIWAS)

## Project Overview

**AI Powered Workflow Automation System (AIWAS)** is a sophisticated command-line interface (CLI) tool designed to streamline development and project management workflows by integrating local Large Language Models (LLMs) via Ollama. 

AIWAS combines the robustness of **Bash scripting** for system interaction and delegation with the computational power of **Python** for complex data handling (Pandas, JSON) and AI communication (Requests). The core value of AIWAS lies in its ability to generate structural, context-aware decisions (priority scores, actionable commands) directly from system data.

### Key Features

* **AI-Driven Task Prioritization:** Automatically assigns priority scores (1-10) and relevant technical tags (e.g., Python, Shell, AI_Integration) to newly added tasks using an LLM.
* **Contextual System Analysis:** Feeds the LLM with real-time system context (open tasks, directory structure, recent logs) to generate high-value, actionable recommendations and next-step shell commands.
* **Multi-Format Reporting:** Generates comprehensive task reports in both Excel (`.xlsx`) and CSV formats using the Pandas library.
* **Dynamic Resource Management:** Includes a daemon to monitor system resource usage (CPU/RAM) and dynamically manage the niceness/priority of the local Ollama process to prevent resource monopolization during heavy AI computation.
* **Polyglot Architecture:** Demonstrates professional integration and data exchange between Shell (Bash) and Python via Command-Line Arguments and structured JSON output.

## Prerequisites

Before running AIWAS, ensure you have the following installed on your macOS or Linux system:

1.  **Ollama:** The local LLM server must be running.
    * **Model:** Pull the specific model used for this project:
        ```bash
        ollama pull leeplenty/lumimaid-v0.2:8b 
        ```
2.  **Python 3.11+**
3.  **Dependencies:** Required Python libraries:
    ```bash
    pip install pandas openpyxl requests
    ```
4.  **System Tools:** The `jq` utility is required for JSON processing in Bash.
    ```bash
    # For macOS (using Homebrew)
    brew install jq
    ```

## Installation and Setup

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/ismailoksuz/AI-Powered-Workflow-Automation-System](https://github.com/ismailoksuz/AI-Powered-Workflow-Automation-System)
    cd AI-Powered-Workflow-Automation-System
    ```

2.  **Make Scripts Executable:**
    ```bash
    chmod +x bin/*.sh
    ```

3.  **Run Initialization:** The system will automatically create the necessary `data/` and `output/` directories and log files on the first run.

## Usage

All functionality is accessed via the main entry script `bin/aiwas`.

| Command Category | Action | Example Usage | Description |
| :--- | :--- | :--- | :--- |
| **Task Management** | `task add` | `bin/aiwas task add "Fix the JSON parsing error in the utils script"` | Adds a new task and triggers AI prioritization. |
| | `task list` | `bin/aiwas task list` | Displays all tasks, sorted by AI-assigned priority. |
| | `task status` | `bin/aiwas task status 1 Done` | Updates the status of a specific task ID. |
| **AI Analysis** | `ai analyze` | `bin/aiwas ai analyze` | Gathers system context (tasks, logs, directory) and requests an actionable suggestion from the LLM. |
| **Reporting** | `report generate` | `bin/aiwas report generate excel` | Generates a comprehensive report in Excel or CSV format. |
| **Resources** | `resource monitor` | `bin/aiwas resource monitor` | Starts a background daemon to monitor resources and manage the Ollama process priority dynamically. |

## Architecture Highlights

The system architecture is a clean separation of concerns, showcasing strong Shell scripting mastery and Python integration:

| Component | Technology | Role |
| :--- | :--- | :--- |
| **Entry Point** | Bash (`bin/aiwas`) | Handles command routing, setup, and logging. The main user interface. |
| **Logic/Delegation** | Bash (`bin/*.sh`) | Manages task CRUD operations, resource monitoring, and context collection using native system utilities (`top`, `pgrep`, `renice`). |
| **Data Processing** | Python (`lib/*.py`) | Uses Pandas for structured data manipulation and Openpyxl for Excel output. |
| **AI Bridge** | Python (`ai/ai_query.py`) | Manages API communication with Ollama. Crucially uses **Prompt Engineering** to force structural JSON output for robust data exchange back to the Bash layer. |