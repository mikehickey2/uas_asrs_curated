---
name: orient
description: Rebuild project context and report current status
allowed-tools: Bash(git:*), Read, Glob
---

Rebuild project context and report current status.

## Context Files

Read these files:
1. @CLAUDE.md
2. @README.md
3. @R/asrs_schema.R
4. @CONTRIBUTING.md

## Git Status

- Current branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`
- Last commit: !`git log -1 --oneline`

## Task

Provide a summary of the current project status and confirm you have read and will adhere to the `Critical Work Rules` in CLAUDE.md.