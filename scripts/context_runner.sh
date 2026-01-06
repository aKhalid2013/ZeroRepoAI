#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
context_file="$root/docs/CONTEXT_MANAGER.md"

usage() {
  echo "Usage: $0 [--dry-run]"
}

# Parse flags
args=()
dry_run=false
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    dry_run=true
  else
    args+=("$arg")
  fi
done

if [ ${#args[@]} -gt 0 ]; then
  usage
  exit 1
fi

if [ ! -f "$context_file" ]; then
  echo "Context manager file not found: $context_file" >&2
  exit 1
fi

invoke_script=""
agent_role=""
user_message=""
in_section=false

trim() {
  echo "$1" | sed 's/^\s*//;s/\s*$//'
}

while IFS= read -r line; do
  if [[ "$line" =~ ^###\ Next\ Task\ Instructions ]]; then
    in_section=true
    continue
  fi

  if [ "$in_section" = true ] && [[ "$line" =~ ^##[[:space:]] ]]; then
    break
  fi

  if [ "$in_section" = true ]; then
    if [[ "$line" =~ \*\*Invoke[[:space:]]Script\*\* ]]; then
      value=$(echo "$line" | sed -E 's/^[-[:space:]]*\*\*Invoke Script\*\*:[[:space:]]*`?([^`]*?)`?.*/\1/')
      invoke_script=$(trim "$value")
    elif [[ "$line" =~ \*\*Agent[[:space:]]Role\*\* ]]; then
      value=$(echo "$line" | sed -E 's/^[-[:space:]]*\*\*Agent Role\*\*:[[:space:]]*`?([^`]*?)`?.*/\1/')
      agent_role=$(trim "$value")
    elif [[ "$line" =~ \*\*User[[:space:]]Message\*\* ]]; then
      value=$(echo "$line" | sed -E 's/^[-[:space:]]*\*\*User Message\*\*:[[:space:]]*`?([^`]*?)`?.*/\1/')
      user_message=$(trim "$value")
    fi
  fi

done < "$context_file"

if [ -z "$invoke_script" ] || [ -z "$agent_role" ] || [ -z "$user_message" ]; then
  echo "Failed to parse Next Task Instructions. Ensure Invoke Script, Agent Role, and User Message are populated." >&2
  exit 1
fi

cmd=("$invoke_script" "$agent_role" "$user_message")

if [ "$dry_run" = true ]; then
  echo "Invoke Script: $invoke_script"
  echo "Agent Role: $agent_role"
  echo "User Message: $user_message"
  echo "Command: ${cmd[*]}"
  exit 0
fi

"${cmd[@]}"
