# Workflow

Conservative, CLI-driven workflow for AI-assisted development. Durable context lives in the repo, not chat history.

## Non-Negotiable Global Rules
- Repo is the source of truth; read relevant docs before acting.
- NEVER invent: files, functions, endpoints, env vars, credentials, DB schema, config keys, libraries, command outputs. If uncertain, search the repo or ask the user.
- Keep diffs small: one slice per change.
- No refactor + feature unless explicitly required by an approved plan.
- Manual approval required for terminal commands; never auto-run destructive commands.
- Verification gates are mandatory and must be reported: lint, typecheck, test, build. Gates may be SKIPPED until configured, but each SKIP must be explicit.
- Bug fixes require regression tests or a documented exception.
- Iteration cap: max 2 fix attempts before Diagnose Mode.

## Branching Model
- Trunk-based development with short-lived feature branches; `main` is always green.

## Evidence Requirements (Outputs)
- Files changed.
- Commands run (or not run) with results/errors.
- Mapping to acceptance criteria.

## Core Flow
Chore track: Triage → Spec-lite → Plan-lite → Implement → Verify → Review → Rework (≤2) → Verify → Commit/Merge → Doc Steward Update (if needed)
Feature track: Triage → Spec → Plan → Implement → Verify → Review → Rework (≤2) → Verify → Commit/Merge → Doc Steward Update (end of feature only)

All sessions should reference `docs/CONTEXT_MANAGER.md` for the current state and the next instructed step.

## Triage Checklist
- [ ] Classify work as Chore (small change, low risk) or Feature (new behavior, medium/high risk).
- [ ] Confirm the track before proceeding.
- [ ] Identify if the change is a bug fix; plan regression tests or document an exception.

## Chore Track Checklist
- [ ] Spec-lite: minimal requirements + acceptance checks (no prolonged Q and A).
- [ ] Plan-lite: steps + file touch list + verification commands.
- [ ] Implement: smallest safe change, no scope creep.
- [ ] Verify: run `scripts/verify.*` or explicitly SKIP each gate.
- [ ] Review: choose a review outcome.
- [ ] Rework if needed (max 2 iterations).
- [ ] Verify again.
- [ ] Commit/Merge: keep `main` green.
- [ ] Doc Steward Update: end of change if docs/registers changed.

## Feature Track Checklist
- [ ] Spec: mandatory; questions must be closed (see docs/FEATURES/_TEMPLATE.md).
- [ ] Plan: include registry sweep + file touch list + verification commands.
- [ ] Implement: minimal diff, one slice, no scope creep.
- [ ] Verify: run `scripts/verify.*` or explicitly SKIP each gate.
- [ ] Review: choose a review outcome.
- [ ] Rework if needed (max 2 iterations).
- [ ] Verify again.
- [ ] Commit/Merge: keep `main` green.
- [ ] Doc Steward Update: end of feature only.

## Review Outcomes (Choose One)
1) Approved
2) Rework Required (must-fix items)
3) Approved with Deferred Items (log in Known Issues and/or Risk Register)

## Rework Loop
- Allowed after Review.
- Capped: max 2 rework iterations per review cycle.
- If still not passing, enter Diagnose Mode.

## Diagnose Mode
- Trigger: after 2 consecutive failed repair attempts for the same failing gate or repeated rework stalls.
- Output: hypotheses + minimal experiments; no random rewrites.

## Doc Stewardship Policy
- Doc updates only at end of each feature.
- Updates must be based on repo evidence (specs, commits, verification logs).
- Update PRD (including progress), feature docs in `docs/FEATURES/`, ADRs, registers, and decision log as needed.

## Reference Freeze Lite (Hallucination Control)
- No new third-party dependency or external API integration unless recorded in docs/REFERENCES or captured in an ADR.
- Keep notes concise; do not mirror vendor docs.

## Registry Sweep (Mandatory)
- Before planning: read `docs/REGISTERS/KNOWN_ISSUES.md` and `docs/REGISTERS/RISK_REGISTER.md` and identify relevant open items.
- During Doc Steward Update: close/update statuses only when evidence exists.
