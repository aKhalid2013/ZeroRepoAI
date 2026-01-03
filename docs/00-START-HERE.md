# 00 Start Here

Use this repo as the starting point for a new project.

## Step-by-Step

### 1. Setup
1) Copy this repository to a new project location.
2) **Recommended**: Open in VS Code.
3) Use `Ctrl+Shift+P` -> `Run Task` -> `ZeroRepo: Verify (All Gates)` to check your environment.

### 2. Triage & Planning
Decide if your task is a **Chore** (small tweak, low risk) or a **Feature** (new capability, medium/high risk).

#### For Features:
1) **Create Spec**: Run Task `ZeroRepo: New Feature` -> specific title.
2) **Refine Spec**: Run Task `ZeroRepo: Agent - Spec` -> "Review this spec and close open questions..."
3) **Plan**: Run Task `ZeroRepo: Agent - Plan` -> "Generate implementation plan for [Feature]..."

#### For Chores:
Skip to Implementation if the path is obvious, but *never* skip Verification.

### 3. Implementation Loop
1) **Implement**: Run Task `ZeroRepo: Agent - Implement` -> "Execute the plan..."
2) **Verify**: Run Task `ZeroRepo: Verify (All Gates)`.
    - If it fails, check errors and ask Agent to fix.
    - **Rule**: Max 2 fix attempts before you must trigger `ZeroRepo: Agent - Diagnose Mode`.

### 4. Review & Merge
1) **Review**: Run Task `ZeroRepo: Agent - Review`.
    - Must choose: Approved, Rework, or Deferred.
2) **Doc Update**: Run Task `ZeroRepo: Agent - Doc Steward` (End of feature only).
3) **Merge**: Ensure `Verify` passes one last time.

## Documentation
- `docs/PRINCIPLES.md`: Core philosophy.
- `docs/WORKFLOW.md`: Detailed rules for Chores vs Features.
- `docs/AGENTS.md`: Specific responsibilities for each agent role.
