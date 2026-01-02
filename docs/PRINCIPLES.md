# Principles

Non-negotiable operating rules for this repo.

- Repo is the source of truth; read relevant docs before acting.
- NEVER invent: files, functions, endpoints, env vars, credentials, DB schema, config keys, libraries, command outputs.
- Keep diffs small: one slice per change.
- No refactor + feature unless explicitly required by an approved plan.
- Manual approval required for terminal commands; never auto-run destructive commands.
- Verification gates are mandatory and must be reported: lint, typecheck, test, build. Gates may be SKIPPED until configured, but each SKIP must be explicit.
- Bug fixes require regression tests or a documented exception.
- Evidence required in outputs: files changed, commands run (or not run), results/errors, mapping to acceptance criteria.
- Iteration cap: max 2 fix attempts before Diagnose Mode.
- Reference Freeze Lite: no new dependency or external API without docs/REFERENCES or an ADR.
- Trunk-based development with short-lived feature branches; main always green.
