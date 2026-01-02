#!/usr/bin/env bash
set -u
set -o pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
gates_file="$root/docs/QUALITY_GATES.md"

if [ ! -f "$gates_file" ]; then
  echo "Missing docs/QUALITY_GATES.md"
  exit 1
fi

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf "%s" "$s"
}

get_cmd() {
  local gate="$1"
  local line
  line="$(grep -E "^${gate}=" "$gates_file" | head -n1 || true)"
  printf "%s" "${line#${gate}=}"
}

gates=(lint typecheck test build)
declare -A status
failed=""

for gate in "${gates[@]}"; do
  if [ -n "$failed" ]; then
    break
  fi

  cmd="$(get_cmd "$gate")"
  cmd="$(trim "$cmd")"

  if [ -z "$cmd" ] || [[ "$cmd" =~ ^[Tt][Bb][Dd]$ ]]; then
    echo "SKIPPED $gate: not configured or TBD" >&2
    status["$gate"]="SKIP"
    continue
  fi

  echo "RUN $gate: $cmd"
  if sh -c "$cmd"; then
    echo "PASS $gate"
    status["$gate"]="PASS"
  else
    echo "FAIL $gate"
    status["$gate"]="FAIL"
    failed="$gate"
  fi
done

if [ -n "$failed" ]; then
  for gate in "${gates[@]}"; do
    if [ -z "${status[$gate]:-}" ]; then
      echo "SKIPPED $gate: blocked by failure in $failed" >&2
      status["$gate"]="SKIP"
    fi
  done
fi

echo ""
echo "Summary"
printf "%-10s %s\n" "Gate" "Status"
printf "%-10s %s\n" "----" "------"
for gate in "${gates[@]}"; do
  printf "%-10s %s\n" "$gate" "${status[$gate]}"
done

if [ -n "$failed" ]; then
  echo "Failed gate: $failed"
  exit 1
fi

echo "All configured gates passed."
