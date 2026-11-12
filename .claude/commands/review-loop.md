---
description: Danny reviews, Mark fixes, Danny re-reviews until approved (max 3 rounds)
argument-hint: <what to review, e.g. file paths, feature name, or "current diff">
---

Run a review/fix loop on: $ARGUMENTS

If no target is given, use the current uncommitted git diff.

Subagents cannot call each other, so you (the main session) orchestrate. Use the Agent tool with subagent_type "danny" and "mark".

Loop, at most 3 rounds:

1. Call **danny** to review the target. Danny only reviews and must end with exactly one line: `VERDICT: APPROVED` or `VERDICT: CHANGES REQUESTED`. Findings must be a numbered list, each with file path, problem, and required change, ordered by severity.
2. If APPROVED, stop and report.
3. If CHANGES REQUESTED, call **mark** with Danny's full findings. Mark fixes only the listed issues, does not touch unrelated code, and reports what changed per finding. If Mark disagrees with a finding or it conflicts with approved requirements, Mark says so instead of silently skipping it.
4. Go back to step 1, telling Danny which files Mark changed and asking him to verify the previous findings are resolved and to check for regressions.

After the loop, report: number of rounds, final verdict, what was fixed, and any findings still open or disputed. If round 3 still has CHANGES REQUESTED, stop and list the remaining findings for the user to decide.
