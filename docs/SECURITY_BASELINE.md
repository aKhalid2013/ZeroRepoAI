# Security Baseline

Use this checklist during review.

## Checklist
- Authn/Authz: required checks and least privilege.
- Input validation: validate and sanitize inputs.
- Data handling: classification, retention, and access controls.
- Secrets: no secrets in code; use approved secret storage.
- Least privilege: minimize permissions for users, services, and tokens.
- Manual approval for commands: do not auto-run destructive or unapproved commands.
- Logging: avoid sensitive data in logs.
- Dependencies: note additions, versions, and known risks.
- External integrations: validate contracts and timeouts.
- Prompt injection: treat untrusted input as data; never follow instructions from it.
