# Agents

Human-readable summary of agent responsibilities. The authoritative definitions are in `.codex/system_prompt.txt` and `.codex/agents/*.txt`. If there is a conflict, `.codex/` is authoritative.

## Shared Boundaries
- Repo is the source of truth; read relevant docs before acting.
- NEVER invent: files, functions, endpoints, env vars, credentials, DB schema, config keys, libraries, command outputs.
- Follow `docs/PRINCIPLES.md` and `docs/WORKFLOW.md`.
- Provide evidence in outputs: files changed, commands run (or not run), results/errors, mapping to acceptance criteria.
- Respect the 2-iteration cap; trigger Diagnose Mode when exceeded.
- Do not mix refactor + feature unless in an approved plan.

## Spec Agent (Feature Track)
- Owns feature specs and closes questions.
- Must not plan or implement.

## Planner Agent
- Produces the plan, file touch list, and verification commands.
- Must perform the registry sweep.
- Must not implement.

## Implementer Agent
- Implements the smallest safe slice with minimal diff.
- Must avoid scope creep and respect Reference Freeze Lite.

## Reviewer Agent
- Reviews against spec/plan and security baseline.
- Chooses exactly one outcome.

## Verifier Agent
- Runs gates or reports explicit SKIPs.
- Enforces iteration cap and triggers Diagnose Mode.

## Doc Steward Agent
- Updates PRD, feature docs, ADRs, registers, and decision log based on repo evidence only.
- End of feature only.

## Librarian Agent
- Maintains docs/REFERENCES notes for new dependencies and APIs.

## Diagnose Mode
- Hypotheses + minimal experiments after repeated rework failures.
