# Zero-Step Repository Template

This repository is Step Zero for new projects. It provides a conservative, CLI-driven workflow and durable context for AI-assisted development.

## Use This Repo as Step Zero
- Copy this repo to start a new project.
- Keep it framework and language agnostic until you intentionally add one.
- Follow `docs/00-START-HERE.md` to triage and create the first feature spec.
- Use trunk-based development with short-lived feature branches; keep `main` green.

## Agent Wrapper
- PowerShell (Windows): `.\scripts\agent.ps1 spec "Feature description..."`
- Bash: `./scripts/agent.sh spec "Feature description..."`
- Use `--dry-run` to preview the payload without invoking Codex.
- Agent prompts and context packs live in `.codex/`.

## Quality Gates
- Configure commands in `docs/QUALITY_GATES.md` (copy from template if needed).
- Run verification with `scripts/verify.ps1` or `scripts/verify.sh`.
- Gates are mandatory and must be reported: lint, typecheck, test, build. Unconfigured gates are explicitly SKIPPED.
