#!/usr/bin/env bash
set -euo pipefail

dry_run=false
args=()
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    dry_run=true
  else
    args+=("$arg")
  fi
done

if [ "${#args[@]}" -lt 1 ]; then
  echo "Usage: ./scripts/agent.sh <role> [message...] [--dry-run]"
  exit 1
fi

role="${args[0]}"
message=""
if [ "${#args[@]}" -gt 1 ]; then
  message="${args[*]:1}"
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
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

if ! command -v python >/dev/null 2>&1; then
  echo "python is required to read context_map.json"
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

if [ "$dry_run" = true ]; then
  echo "DRY RUN: payload below (no Codex invocation)."
  echo ""
  cat "$payload_file"
  exit 0
fi

codex_cmd="${CODEX_CLI:-codex}"
cmd_base="$(basename "$codex_cmd")"
cmd_base="${cmd_base%.exe}"

if ! echo "$cmd_base" | grep -qi "codex"; then
  echo "CODEX_CLI must reference a Codex CLI command."
  exit 1
fi

if ! command -v "$codex_cmd" >/dev/null 2>&1; then
  echo "Codex CLI not found: $codex_cmd"
  exit 1
fi

cat "$payload_file" | "$codex_cmd"
