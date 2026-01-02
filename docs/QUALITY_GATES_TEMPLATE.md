# Quality Gates (Template)

Policy: lint, typecheck, test, build must be reported. Until configured, gates may be SKIPPED, but each SKIP must be explicit.
Use blank or `TBD` to mark a gate as not configured.

Use `scripts/verify.ps1` or `scripts/verify.sh` to run these gates.

## Commands
Set one command per line. Leave blank to SKIP.

lint=
typecheck=
test=
build=
