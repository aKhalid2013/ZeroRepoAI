#!/usr/bin/env bash
set -euo pipefail

dry_run=false
use_context=false
update_status=""
update_step=""
args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    --use-context)
      use_context=true
      ;;
    --update-status)
      shift
      if [ "$#" -eq 0 ]; then
        echo "--update-status requires a value"
        exit 1
      fi
      update_status="$1"
      ;;
    --update-step)
      shift
      if [ "$#" -eq 0 ]; then
        echo "--update-step requires a value"
        exit 1
      fi
      update_step="$1"
      ;;
    *)
      args+=("$1")
      ;;
  esac
  shift
done

if [ "$use_context" = false ] && { [ -n "$update_status" ] || [ -n "$update_step" ]; }; then
  echo "--update-status and --update-step can only be used with --use-context"
  exit 1
fi

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
  context_json=$(python - "$context_file" <<'PY'
import json
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

print(json.dumps(
    {
        "next_agent_role": data.get("next_agent_role", ""),
        "next_user_message": data.get("next_user_message", ""),
        "current_step": data.get("current_step", ""),
        "current_status": data.get("current_status", ""),
    }
))
PY
)
  role=$(echo "$context_json" | python - <<'PY'
import json
import sys
data = json.load(sys.stdin)
print(data.get("next_agent_role", ""))
PY
)
  message=$(echo "$context_json" | python - <<'PY'
import json
import sys
data = json.load(sys.stdin)
print(data.get("next_user_message", ""))
PY
)
  current_step=$(echo "$context_json" | python - <<'PY'
import json
import sys
data = json.load(sys.stdin)
print(data.get("current_step", ""))
PY
)
  if [ -z "$role" ] || [ -z "$message" ]; then
    echo "Missing next_agent_role or next_user_message in $context_file"
    exit 1
  fi
  if [ -z "$current_step" ]; then
    echo "Missing current_step in $context_file"
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

if [ "$use_context" = true ]; then
  step_lc="$(echo "$current_step" | tr '[:upper:]' '[:lower:]')"
  role_lc="$(echo "$role" | tr '[:upper:]' '[:lower:]')"
  allowed_roles=()
  case "$step_lc" in
    spec)
      allowed_roles=("spec" "planner")
      ;;
    plan)
      allowed_roles=("planner" "implementer")
      ;;
    implement)
      allowed_roles=("implementer" "verifier")
      ;;
    verify)
      allowed_roles=("verifier" "reviewer")
      ;;
    review)
      allowed_roles=("reviewer" "doc_steward")
      ;;
    *)
      echo "Unknown or unsupported current_step \"$current_step\" in $context_file"
      exit 1
      ;;
  esac
  valid_transition=false
  for allowed in "${allowed_roles[@]}"; do
    if [ "$role_lc" = "$allowed" ]; then
      valid_transition=true
      break
    fi
  done
  if [ "$valid_transition" = false ]; then
    echo "Invalid role transition: current_step \"$current_step\" does not allow next_agent_role \"$role\""
    exit 1
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

if [ "$use_context" = true ] && { [ -n "$update_status" ] || [ -n "$update_step" ]; }; then
  python - "$context_file" "$update_status" "$update_step" <<'PY'
import sys
from datetime import date

path = sys.argv[1]
new_status = sys.argv[2]
new_step = sys.argv[3]

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

if new_status:
    data["current_status"] = new_status
if new_step:
    data["current_step"] = new_step

ordered_keys = ["current_status", "current_step", "next_agent_role", "next_user_message"]
front_matter = ["---"]
for key in ordered_keys:
    value = data.get(key, "")
    escaped = value.replace('"', '\\"')
    front_matter.append(f'{key}: "{escaped}"')
front_matter.append("---")

new_lines = front_matter + lines[end + 1 :]

log_header_idx = None
for idx, line in enumerate(new_lines):
    if line.strip() == "## Change Log":
        log_header_idx = idx
        break

if log_header_idx is None:
    sys.stderr.write("Could not find '## Change Log' section in docs/CONTEXT_MANAGER.md\n")
    sys.exit(1)

table_start = None
separator_idx = None
for idx in range(log_header_idx + 1, len(new_lines)):
    if new_lines[idx].startswith("| Date |"):
        table_start = idx
    if table_start is not None and new_lines[idx].startswith("| ---"):
        separator_idx = idx
        break

if table_start is None or separator_idx is None:
    sys.stderr.write("Could not find change log table structure in docs/CONTEXT_MANAGER.md\n")
    sys.exit(1)

insert_idx = separator_idx + 1
while insert_idx < len(new_lines) and new_lines[insert_idx].startswith("|"):
    insert_idx += 1

status_value = data.get("current_status", "")
step_value = data.get("current_step", "")
summary = f"Updated status to {status_value} and step to {step_value}"
new_row = f"| {date.today().isoformat()} | agent.sh | {summary} |"

new_lines.insert(insert_idx, new_row)

with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(new_lines) + "\n")
PY
fi
