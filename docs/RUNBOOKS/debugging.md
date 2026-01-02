# Debugging Runbook

## Steps
1) Reproduce and capture the failure.
2) Gather logs, inputs, and environment details.
3) Identify the failing gate or acceptance criterion.
4) Propose the smallest fix and add/adjust regression tests.
5) Verify with scripts/verify.* and report results.
6) Update registers if new KI/R items are discovered.

## Optional: Vision Bridge Protocol (UI Evidence)
- Capture UI evidence (screenshot or video) and save its path.
- Write a short text summary of what the UI shows.
- Note expected vs actual behavior.
- Link the summary to the related feature or bug report.
