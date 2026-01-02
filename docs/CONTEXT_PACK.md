# Context Pack

Context packs define which repo files are injected for each agent.

## Source of Truth
- `.codex/context_map.json` is the authoritative mapping.
- `scripts/agent.ps1` and `scripts/agent.sh` print the context pack for a given agent.

## Rules
- Keep packs small and focused.
- Add files only when needed for the task.
