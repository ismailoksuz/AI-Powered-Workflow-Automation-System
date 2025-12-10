import sys
import json
import requests

# --- Ollama API Configuration ---
OLLAMA_API_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "leeplenty/lumimaid-v0.2:8b" 
# --------------------------------

def send_query(prompt: str, format_json: bool = True):
    """
    Sends a query to the configured Ollama API endpoint.
    Handles network requests, JSON formatting, and basic error catching.
    """
    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.3
        }
    }

    if format_json:
        payload["format"] = "json"

    try:
        response = requests.post(OLLAMA_API_URL, json=payload, timeout=300)
        response.raise_for_status()
        
        result = response.json()
        
        if 'response' in result:
            return result['response']
        else:
            return None

    except requests.exceptions.RequestException as e:
        # Returns JSON error response for Shell script consumption
        print(json.dumps({"error": f"Ollama connection error: {e}"}), file=sys.stderr)
        return None
    except json.JSONDecodeError:
        print(json.dumps({"error": "Failed to decode Ollama response JSON."}), file=sys.stderr)
        return None

def prioritize_task(task_id: str, description: str):
    """
    Analyzes task description using the AI model to determine priority and tags.
    Expected JSON Output Structure: {"priority_score": int, "tags": [str]}
    """
    system_prompt = (
        "You are an expert project manager AI. Analyze the following task description. "
        "Assign a 'priority_score' from 1 (lowest) to 10 (highest) based on complexity and urgency. "
        "Also extract relevant 'tags' (e.g., 'Shell', 'Python', 'AI_Integration', 'Testing'). "
        "Respond ONLY with a valid JSON object."
    )
    
    prompt = f"Task ID: {task_id}. Description: '{description}'"
    
    full_prompt = f"{system_prompt}\n\n{prompt}"
    
    ai_response_text = send_query(full_prompt, format_json=True)

    if ai_response_text:
        print(ai_response_text)
    else:
        # Fallback response if API fails
        print(json.dumps({"id": task_id, "priority_score": 1, "tags": ["AI_Error"]}))

def analyze_context(context_data: str):
    """
    Generates a prompt to get contextual suggestions based on system data.
    Expected JSON Output Structure: {"suggestion": "text", "command": "shell command"}
    """
    system_prompt = (
        "You are an expert developer and workflow assistant named AIWAS. "
        "Analyze the provided system context (open tasks, directory, recent logs). "
        "Provide one high-value 'suggestion' (natural language advice) and one corresponding 'command' "
        "(a useful Shell command for the user's next step). "
        "Respond ONLY with a valid JSON object."
    )
    
    prompt = f"Current System Context:\n{context_data}"
    
    full_prompt = f"{system_prompt}\n\n{prompt}"
    
    ai_response_text = send_query(full_prompt, format_json=True)

    if ai_response_text:
        print(ai_response_text)
    else:
        # Fallback response if API fails
        print(json.dumps({"suggestion": "Could not connect to AI. Check Ollama status.", "command": "ollama run leeplenty/lumimaid-v0.2:8b"}))

def main():
    """Main entry point for the Shell script integration."""
    if len(sys.argv) < 3:
        print("Usage: python3 ai/ai_query.py <command> <arg1> [arg2]...", file=sys.stderr)
        sys.exit(1)

    command = sys.argv[1]
    
    if command == "prioritize":
        if len(sys.argv) < 4:
            print("Usage: prioritize <task_id> <description>", file=sys.stderr)
            sys.exit(1)
            
        task_id = sys.argv[2]
        description = " ".join(sys.argv[3:])
        prioritize_task(task_id, description)
        
    elif command == "analyze_context":
        if len(sys.argv) < 3:
            print("Usage: analyze_context <context_string>", file=sys.stderr)
            sys.exit(1)
        
        context_data = " ".join(sys.argv[2:])
        analyze_context(context_data)
        
    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()