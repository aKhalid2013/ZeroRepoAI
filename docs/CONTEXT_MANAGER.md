---
current_status: "<!-- e.g., Implementing -->"
current_step: "<!-- e.g., Plan -->"
next_agent_role: "<!-- e.g., planner -->"
next_user_message: "<!-- Summary of the next user prompt. -->"
---

# Context Manager

This file acts as the **single source of truth** for the current session when working with AI agents. It provides a high-level overview of the project, the backlog of features, the current feature and workflow step, instructions for the next agent invocation, and pointers to all other documentation. After **every task**, this file **must be updated** to reflect the new status.

## Project Overview
| Field | Value |
| --- | --- |
| **Project Name** | <!-- e.g., “ZeroRepoAI” --> |
| **Description** | <!-- Brief summary of the project and its purpose. --> |
| **Tech Stack** | <!-- List of languages, frameworks, databases, etc. --> |
| **High-Level Goals** | <!-- Summarise the top-level objectives of the project. --> |

## Backlog
Use this table to track all features planned or in progress. Update the status column as work progresses. Feature IDs should match the files in `docs/FEATURES/`.

| Feature ID | Title | Status | Notes |
| --- | --- | --- | --- |
| F‑001 | [Example Feature](FEATURES/F-001-example.md) | Not started | Sample entry. Replace with your own features. |

**Status values:** `Not started`, `Spec`, `Plan`, `Implementing`, `Verifying`, `Review`, `Doc Steward`, `Completed`.

## Current Feature Progress
This section describes the feature currently being worked on and its state within the workflow.

| Field | Value |
| --- | --- |
| **Feature ID** | <!-- e.g., F‑001 --> |
| **Title** | <!-- e.g., “Implement login flow” --> |
| **Status** | <!-- One of the status values above. --> |
| **Current Step** | <!-- Spec, Plan, Implement, Verify, Review, Doc Steward. --> |
| **Next Step** | <!-- Describe what needs to happen next. --> |
| **Acceptance Criteria** | <!-- Briefly summarise or link to acceptance criteria from the spec. --> |

### Plan Summary

### Next Task Instructions
Provide concrete instructions for the agent that will perform the next task. These fields are consumed by `scripts/agent.sh` and should be kept up to date.

- **Invoke Script**: `./scripts/agent.sh`
- **Agent Role**: <!-- e.g., planner, implementer, verifier, reviewer, doc_steward, librarian, diagnose. -->
- **User Message**: <!-- The prompt to pass to the agent describing what it should do. -->
- **Context Files**: This context manager file plus any relevant spec/plan/test files listed below.
- **Status/Step Updates**: When running `./scripts/agent.sh --use-context`, optional `--update-status <status>` and `--update-step <step>` flags will refresh the YAML front matter and append a Change Log entry after the agent finishes.

## Pointers to Key Documents
Refer to these canonical documents for detailed information. Do **not** embed their content here—use links instead to avoid inconsistency.

- **Project Charter / PRD**: `docs/PROJECT_CHARTER.md` or `docs/PRD.md`
- **High-Level Plan**: `docs/STATUS.md` (or similar backlog overview)
- **Feature Spec**: `docs/FEATURES/<Feature ID>.md`
- **Feature Plan**: `docs/PLANS/<Feature ID>-plan.md` <!-- if you maintain separate plan files -->
- **Test Plan**: `tests/<Feature ID>/` (directory for tests)
- **Known Issues Register**: `docs/REGISTERS/KNOWN_ISSUES.md`
- **Risk Register**: `docs/REGISTERS/RISK_REGISTER.md`
- **Development Principles**: `docs/PRINCIPLES.md`
- **Workflow**: `docs/WORKFLOW.md`
- **Agent Definitions**: `.codex/agents/*.txt`
- **Security Baseline**: `docs/SECURITY_BASELINE.md`

## Registry and Risk Summary
Before planning or implementing, identify any open items from the registers that relate to the current feature. List their IDs here and summarise the mitigation or impact.

| Register ID | Description | Mitigation / Consideration | Open Questions | ADR/Reference IDs |
| --- | --- | --- | --- | --- |
| <!-- e.g., KI‑001 --> | <!-- Describe the known issue or risk. --> | <!-- How it affects this feature. --> | <!-- Clarify open items. --> | <!-- Link to ADRs or references. --> |

## Verification and Evidence
Maintain a record of verification results and other evidence. This section should be updated by the Verifier agent or by any script that runs tests.

### Verification Results

| Gate | Status | Notes |
| --- | --- | --- |
| lint | SKIP/PASS/FAIL | <!-- Provide command output summary or reference to logs. --> |
| typecheck | SKIP/PASS/FAIL | <!-- Provide command output summary or reference to logs. --> |
| test | SKIP/PASS/FAIL | <!-- Provide command output summary or reference to logs. --> |
| build | SKIP/PASS/FAIL | <!-- Provide command output summary or reference to logs. --> |

- **Reminder**: After updating gate statuses, run `scripts/update_context.py --status <status> --step <step>` to refresh the Current Feature Progress and Change Log entries.

### Evidence Summary
- **Files changed**: <!-- List files modified during the last task. -->
- **Commands run**: <!-- Document commands executed and their outputs. -->
- **Mapping to acceptance criteria**: <!-- Explain how changes satisfy the acceptance criteria. -->

## Change Log
Keep an audit trail of updates to this context manager. Each entry should note the date, the agent or person making the update, and a short description.

| Date | Agent / User | Summary |
| --- | --- | --- |
| 2026‑01‑06 | _init_ | Initial creation of context manager with placeholders. |
| 2026‑01‑06 | agent.sh | Documented automated context updates and change log entries. |

## Template Usage Instructions
1. **At project start**: Fill in the **Project Overview** table and seed the **Backlog** with planned features.  
2. **Before starting a feature**: Move the feature from `Not started` to `Spec` in the backlog, set the **Current Feature Progress** fields, and write the **User Message** instructing the Spec agent to begin drafting the spec.  
3. **After each task**: The agent responsible for the task must update the **Current Feature Progress**, **Backlog**, **Next Task Instructions**, **Registry and Risk Summary**, **Verification and Evidence**, and **Change Log** sections as appropriate.  
4. **During planning**: Ensure the **Registry and Risk Summary** is reviewed and updated to show which known issues or risks apply to the feature.  
5. **During verification**: Run `./scripts/verify.sh` or `./scripts/verify.ps1` and record results in **Verification and Evidence**.  
6. **At completion of a feature**: Mark the feature as `Completed` in the **Backlog**, clear the **Current Feature Progress**, and prepare to start the next feature.  
