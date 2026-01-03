# Git Hooks

This directory contains custom Git hooks for the project.

## Setup

Configure Git to use this hooks directory:

```bash
git config core.hooksPath .githooks
```

This setting is stored in `.git/config` and must be run once per clone.

## Available Hooks

### pre-commit

Prevents accidental modification of raw data without a corresponding manifest
update.

**Behavior:**

- If `data/asrs_curated_drone_reports.csv` is staged, the hook requires
  `data/data_manifest.json` to also be staged
- Exits with error if the manifest is missing from staged files
- Passes silently if the raw CSV is not staged or if both files are staged

**Rationale:**

Raw ASRS data exports should be tracked with metadata (source, date, row count)
in the manifest file. This hook enforces that practice.

## Bypassing Hooks

In rare cases where you need to bypass the hook (not recommended):

```bash
git commit --no-verify -m "message"
```

Use sparingly and document why in the commit message.
