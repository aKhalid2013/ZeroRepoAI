#!/usr/bin/env bash
set -euo pipefail

dry_run=false
use_context=false
args=()
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    dry_run=true
  elif [ "$arg" = "--use-context" ]; then
    use_context=true
  else
    args+=("$arg")
  fi
done

root="$(cd "$(dirname "$0")/.." && pwd)"
context_file="$root/docs/CONTEXT_MANAGER.md"

if ! command -v python >/dev/null 2>&1; then
  echo "python is required to read context files"
  exit 1
fi

if [ "$use_context" = true ]; then
  if [ ! -f "$context_file" ]; then
    echo "Missing context file: $context_file"
    exit 1
  fi
  context_output=$(python - "$context_file" <<'PY'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()

start = None
end = None
for idx, line in enumerate(lines):
    if start is None:
        if line.strip() == "---":
            start = idx
            continue
        if line.lstrip().startswith("#"):
            break
    elif line.strip() == "---":
        end = idx
        break

if start is None or end is None:
    sys.stderr.write("Could not find YAML front matter in docs/CONTEXT_MANAGER.md\n")
    sys.exit(1)

data = {}
for line in lines[start + 1:end]:
    if ":" not in line:
        continue
    key, value = line.split(":", 1)
    key = key.strip()
    value = value.strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        value = value[1:-1]
    data[key] = value

print(data.get("next_agent_role", ""))
print(data.get("next_user_message", ""))
PY
)
  role="$(echo "$context_output" | sed -n '1p')"
  message="$(echo "$context_output" | sed -n '2,$p')"
  if [ -z "$role" ] || [ -z "$message" ]; then
    echo "Missing next_agent_role or next_user_message in $context_file"
    exit 1
  fi
else
  if [ "${#args[@]}" -lt 1 ]; then
    echo "Usage: ./scripts/agent.sh [--dry-run] <role> [message...]"
    echo "       ./scripts/agent.sh --use-context [--dry-run]"
    exit 1
  fi
  role="${args[0]}"
  message=""
  if [ "${#args[@]}" -gt 1 ]; then
    message="${args[*]:1}"
  fi
fi

system_prompt="$root/.codex/system_prompt.txt"
agent_prompt="$root/.codex/agents/$role.txt"
context_map="$root/.codex/context_map.json"

if [ ! -f "$system_prompt" ]; then
  echo "Missing system prompt: $system_prompt"
  exit 1
fi
if [ ! -f "$agent_prompt" ]; then
  echo "Missing agent prompt: $agent_prompt"
  exit 1
fi
if [ ! -f "$context_map" ]; then
  echo "Missing context map: $context_map"
  exit 1
fi

map_files=()
while IFS= read -r line; do
  map_files+=("$line")
done < <(python - "$context_map" "$role" <<'PY'
import json
import sys

path = sys.argv[1]
role = sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
entry = data.get("agents", {}).get(role, data.get("defaults", {}))
for item in entry.get("files", []):
    print(item)
PY
)

if [ "$role" = "planner" ]; then
  registry_files=("docs/REGISTERS/KNOWN_ISSUES.md" "docs/REGISTERS/RISK_REGISTER.md")
  for reg in "${registry_files[@]}"; do
    found=false
    for f in "${map_files[@]}"; do
      if [ "$f" = "$reg" ]; then
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      map_files=("$reg" "${map_files[@]}")
    fi
  done
fi

payload_file="$(mktemp)"
cleanup() { rm -f "$payload_file"; }
trap cleanup EXIT

{
  echo "SYSTEM PROMPT"
  cat "$system_prompt"
  echo ""
  echo "AGENT PROMPT"
  cat "$agent_prompt"
  echo ""
  echo "CONTEXT FILES"
  for file in "${map_files[@]}"; do
    path="$root/$file"
    if [ ! -f "$path" ]; then
      echo "Missing context file: $file" >&2
      continue
    fi
    echo "### FILE: $file"
    cat "$path"
    echo ""
  done
  echo "USER MESSAGE"
  echo "$message"
} > "$payload_file"

echo "Agent: $role"
echo "Reminder: max 2 fix attempts before Diagnose Mode."

codex_cmd="${CODEX_CLI:-codex}"
cmd_base="$(basename "$codex_cmd")"
cmd_base="${cmd_base%.exe}"

if [ "$dry_run" = true ]; then
  if [ "$use_context" = true ]; then
    echo "Context role: $role"
    echo "Context message: $message"
  fi
  echo "DRY RUN: payload below (no Codex invocation)."
  echo ""
  cat "$payload_file"
  echo ""
  echo "Command that would be run: $codex_cmd"
  exit 0
fi

if ! echo "$cmd_base" | grep -qi "codex"; then
  echo "CODEX_CLI must reference a Codex CLI command."
  exit 1
fi

if ! command -v "$codex_cmd" >/dev/null 2>&1; then
  echo "Codex CLI not found: $codex_cmd"
  exit 1
fi

cat "$payload_file" | "$codex_cmd"
