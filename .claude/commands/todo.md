---
description: Archive completed and abandoned tasks
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), Bash(bash:*), Bash(mv:*), Bash(mkdir:*), Bash(ls:*), Bash(find:*), Bash(jq:*), Bash(python3:*), Bash(wc:*), Bash(grep:*), Bash(date:*), TaskCreate, TaskUpdate, AskUserQuestion
argument-hint: [--dry-run]
model: opus
---

# /todo Command

Archive completed and abandoned tasks to clean up active task list.

## Arguments

- `--dry-run` - Show what would be archived without making changes

## Execution

### 1. Parse Arguments

```
dry_run = "--dry-run" in $ARGUMENTS
```

### 2. Scan for Archivable Tasks

Read specs/state.json and identify:
- Tasks with status = "completed"
- Tasks with status = "abandoned"

Read specs/TODO.md and cross-reference:
- Entries marked [COMPLETED]
- Entries marked [ABANDONED]

### 2.5. Detect Orphaned and Misplaced Directories

Run the orphan detection utility script and parse its output.

**CRITICAL**: This step MUST be executed to identify orphaned directories.

```bash
# Run orphan detection
orphan_output=$(bash .claude/scripts/orphan-detection.sh \
  "specs" \
  "specs/state.json" \
  "specs/archive/state.json" 2>/dev/null)

# Parse output sections using delimiter lines
orphaned_in_specs=()
orphaned_in_archive=()
misplaced_in_specs=()

current_section=""
while IFS= read -r line; do
  case "$line" in
    ---orphaned_in_specs---) current_section="specs" ;;
    ---orphaned_in_archive---) current_section="archive" ;;
    ---misplaced_in_specs---) current_section="misplaced" ;;
    "")  ;;
    *)
      case "$current_section" in
        specs)    [ -n "$line" ] && orphaned_in_specs+=("$line") ;;
        archive)  [ -n "$line" ] && orphaned_in_archive+=("$line") ;;
        misplaced)[ -n "$line" ] && misplaced_in_specs+=("$line") ;;
      esac
      ;;
  esac
done <<< "$orphan_output"

# Combined list for output reporting
orphaned_dirs=("${orphaned_in_specs[@]+"${orphaned_in_specs[@]}"}" "${orphaned_in_archive[@]+"${orphaned_in_archive[@]}"}") 
```

Store counts and lists for later use in Steps 4.5, 4.6, and 5E/5F.

### 3. Prepare Archive List

For each archivable task, collect:
- project_number
- project_name (slug)
- status
- completion/abandonment date
- artifact paths

Build `archivable_tasks` as a JSON array from state.json. Write to temp file for utility script consumption:

```bash
mkdir -p specs/tmp

# Extract archivable tasks (completed or abandoned)
jq '[.active_projects[] | select(.status == "completed" or .status == "abandoned")]' \
  specs/state.json > specs/tmp/todo_archivable_$$.json
```

### 3.5. Scan Roadmap for Task References (Structured Matching)

Run the roadmap-sync.sh scan phase to find ROADMAP.md items matching archivable tasks.

**IMPORTANT**: Meta tasks (task_type: "meta") are automatically excluded inside the script.

```bash
# Run roadmap scan -- outputs JSON matches array to stdout, counts to stderr
roadmap_matches_json=$(bash .claude/scripts/roadmap-sync.sh scan \
  "specs/tmp/todo_archivable_$$.json" \
  "specs/ROADMAP.md" 2>/tmp/todo_roadmap_counts_$$.txt)

# Save matches to file for apply phase
echo "$roadmap_matches_json" > specs/tmp/todo_roadmap_matches_$$.json

# Parse counts from stderr output
roadmap_completed_count=0
roadmap_abandoned_count=0
if [ -f /tmp/todo_roadmap_counts_$$.txt ]; then
  while IFS= read -r count_line; do
    case "$count_line" in
      roadmap_completed_count=*) roadmap_completed_count="${count_line#*=}" ;;
      roadmap_abandoned_count=*) roadmap_abandoned_count="${count_line#*=}" ;;
    esac
  done < /tmp/todo_roadmap_counts_$$.txt
  rm -f /tmp/todo_roadmap_counts_$$.txt
fi

roadmap_total_matches=$(echo "$roadmap_matches_json" | jq 'length' 2>/dev/null || echo "0")
```

Track:
- `roadmap_matches_json` - JSON array of match objects (project_num, status, match_type, line_num, item_text)
- `roadmap_completed_count` - Count of completed task matches
- `roadmap_abandoned_count` - Count of abandoned task matches
- `roadmap_total_matches` - Total number of matches found

### 4. Dry Run Output (if --dry-run)

```
Tasks to archive:

Completed:
- #{N1}: {title} (completed {date})
- #{N2}: {title} (completed {date})

Abandoned:
- #{N3}: {title} (abandoned {date})

Orphaned directories in specs/ (will be moved to archive/): {N}
- {N4}_{SLUG4}/
- {N5}_{SLUG5}/

Orphaned directories in archive/ (need state tracking): {N}
- {N6}_{SLUG6}/
- {N7}_{SLUG7}/

Misplaced directories in specs/ (tracked in archive/, will be moved): {N}
- {N8}_{SLUG8}/
- {N9}_{SLUG9}/

Roadmap updates (from completion summaries):

Task #{N1} ({project_name}):
  Summary: "{completion_summary}"
  Matches:
    - [ ] {item text} (line {N}) [explicit]
    - [ ] {item text 2} (line {N}) [exact]

Task #{N2} ({project_name}):
  Summary: "{completion_summary}"
  Matches:
    - [ ] {item text} (line {N}) [exact]

Task #{N3} ({project_name}) [abandoned]:
  Matches:
    - [ ] {item text} (line {N}) [exact] -> *(Task {N} abandoned)*

Total roadmap items to update: {N}
- Completed: {N}
- Abandoned: {N}

Total tasks: {N}
Total orphans: {N} (specs: {N}, archive: {N})
Total misplaced: {N}

Run without --dry-run to archive.
```

If no roadmap matches were found (from Step 3.5), omit the "Roadmap updates" section.

Exit here if dry run. Clean up temp files before exiting:
```bash
rm -f "specs/tmp/todo_archivable_$$.json" "specs/tmp/todo_roadmap_matches_$$.json"
```

### 4.5. Handle Orphaned Directories (if any found)

If orphaned directories were detected in Step 2.5:

**Use AskUserQuestion**:
```json
{
  "question": "Found {N} orphaned directories not tracked in state files. What would you like to do?",
  "header": "Orphans",
  "multiSelect": false,
  "options": [
    {"label": "Track all orphans", "description": "Move to archive/ and add state entries"},
    {"label": "Skip orphans", "description": "Only archive tracked tasks"},
    {"label": "Review list first", "description": "Show full list before deciding"}
  ]
}
```

**If "Review list first" selected**, display directory list then re-ask:
```json
{
  "question": "Track these {N} orphaned directories?",
  "header": "Confirm",
  "multiSelect": false,
  "options": [
    {"label": "Yes, track all", "description": "Move to archive/ and add state entries"},
    {"label": "No, skip", "description": "Only archive tracked tasks"}
  ]
}
```

**Store the user's decision** (track_orphans = true/false) for use in Step 5.

If no orphaned directories were found, skip this step and proceed.

### 4.6. Handle Misplaced Directories (if any found)

If misplaced directories were detected in Step 2.5:

**Use AskUserQuestion**:
```json
{
  "question": "Found {N} misplaced directories in specs/ (tracked in archive/state.json). Move them?",
  "header": "Misplaced",
  "multiSelect": false,
  "options": [
    {"label": "Move all", "description": "Move to archive/ (state already correct)"},
    {"label": "Skip", "description": "Leave in current location"}
  ]
}
```

**Store the user's decision** (move_misplaced = true/false) for use in Step 5F.

If no misplaced directories were found, skip this step and proceed.

### 5. Archive Tasks

For each archivable task in the archivable_tasks list:

**Step 5.0: Harvest memory candidates** (before archiving each task):

```bash
for task in "${archivable_tasks[@]}"; do
  task_number=$(echo "$task" | jq -r '.project_number')
  project_name=$(echo "$task" | jq -r '.project_name')

  # Harvest memory candidates before archiving
  harvested=$(bash .claude/scripts/memory-harvest.sh "$task_number" 2>/dev/null || echo "0")
  total_harvested=$(( total_harvested + harvested ))
  if [ "$harvested" -gt 0 ]; then
    echo "Harvested $harvested memories from task $task_number"
  fi

  # Archive the task (Steps A-D)
  if $dry_run; then
    bash .claude/scripts/archive-task.sh "$task_number" "$project_name" --dry-run
  else
    bash .claude/scripts/archive-task.sh "$task_number" "$project_name"
  fi
done
```

Initialize `total_harvested=0` before the loop. This replaces the inline Steps A-D (update
archive/state.json, update state.json, update TODO.md, move directory) -- all handled by
`archive-task.sh`.

**E. Track Orphaned Directories (if approved in Step 4.5)**

If user selected "Track all orphans" (track_orphans = true):

**Step E.1: Move orphaned directories from specs/ to archive/**
```bash
for orphan_dir in "${orphaned_in_specs[@]+"${orphaned_in_specs[@]}"}"; do
  dir_name=$(basename "$orphan_dir")
  mv "$orphan_dir" "specs/archive/${dir_name}"
  echo "Moved orphan: ${dir_name} -> archive/"
done
```

**Step E.2: Add state entries for ALL orphans (both moved and existing in archive/)**
```bash
for orphan_dir in "${orphaned_dirs[@]+"${orphaned_dirs[@]}"}"; do
  dir_name=$(basename "$orphan_dir")
  project_num=$(echo "$dir_name" | cut -d_ -f1)
  project_name=$(echo "$dir_name" | cut -d_ -f2-)

  # Determine archive path (after potential move)
  archive_path="specs/archive/${dir_name}"

  # Scan for existing artifacts
  artifacts="[]"
  [ -d "$archive_path/reports" ] && artifacts=$(echo "$artifacts" | jq '. + ["reports/"]')
  [ -d "$archive_path/plans" ] && artifacts=$(echo "$artifacts" | jq '. + ["plans/"]')
  [ -d "$archive_path/summaries" ] && artifacts=$(echo "$artifacts" | jq '. + ["summaries/"]')

  # Add entry to archive/state.json
  jq --arg num "$project_num" \
     --arg name "$project_name" \
     --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     --argjson arts "$artifacts" \
     '.completed_projects += [{
       project_number: ($num | tonumber),
       project_name: $name,
       status: "orphan_archived",
       archived: $date,
       source: "orphan_recovery",
       detected_artifacts: $arts
     }]' specs/archive/state.json > specs/archive/state.json.tmp \
  && mv specs/archive/state.json.tmp specs/archive/state.json

  echo "Added state entry for orphan: ${dir_name}"
done
```

Track orphan operations for output reporting:
- orphans_moved: count of directories moved from specs/ to archive/
- orphans_tracked: count of state entries added to archive/state.json

**F. Move Misplaced Directories (if approved in Step 4.6)**

If user selected "Move all" (move_misplaced = true):

```bash
misplaced_moved=0
for dir in "${misplaced_in_specs[@]+"${misplaced_in_specs[@]}"}"; do
  dir_name=$(basename "$dir")
  dst="specs/archive/${dir_name}"

  if [ -d "$dst" ]; then
    echo "Warning: ${dir_name} already exists in archive/, skipping"
    continue
  fi

  mv "$dir" "$dst"
  echo "Moved misplaced: ${dir_name} -> archive/"
  misplaced_moved=$(( misplaced_moved + 1 ))
done
```

Track misplaced operations for output reporting:
- misplaced_moved: count of directories moved from specs/ to archive/

### 5.5. Update Roadmap for Archived Tasks

**Context**: Load @.claude/context/patterns/roadmap-update.md for matching strategy.

Apply roadmap annotations using the roadmap-sync.sh apply phase:

```bash
if [ "$roadmap_total_matches" -gt 0 ]; then
  bash .claude/scripts/roadmap-sync.sh apply \
    "specs/tmp/todo_roadmap_matches_$$.json" \
    "specs/ROADMAP.md"
fi

# Clean up temp files
rm -f "specs/tmp/todo_archivable_$$.json" "specs/tmp/todo_roadmap_matches_$$.json"
```

The apply phase outputs annotation summary counts directly to stdout.

### 5.6. Sync Repository Metrics

Update repository-wide metrics in both state.json and TODO.md header.

**Step 5.7.1: Compute current metrics**:
```bash
# Count TODOs in source files
todo_count=$(grep -r "TODO" . --include="*.lua" --include="*.py" --include="*.js" --include="*.ts" --include="*.tex" | wc -l)

# Count FIXME markers
fixme_count=$(grep -r "FIXME" . --include="*.lua" --include="*.py" --include="*.js" --include="*.ts" --include="*.tex" | wc -l)

# Get current timestamp
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Build errors (0 if project-specific lint/check passes)
if make check 2>/dev/null || npm run lint 2>/dev/null || true; then
  build_errors=0
else
  build_errors=1
fi
```

**Step 5.7.2: Update state.json repository_health**:
```bash
jq --arg todo "$todo_count" \
   --arg fixme "$fixme_count" \
   --arg ts "$ts" \
   --arg errors "$build_errors" \
   '.repository_health = {
     "last_assessed": $ts,
     "todo_count": ($todo | tonumber),
     "fixme_count": ($fixme | tonumber),
     "build_errors": ($errors | tonumber),
     "status": (if ($build_errors | tonumber) == 0 then "healthy" else "needs_attention" end)
   }' specs/state.json > specs/state.json.tmp && mv specs/state.json.tmp specs/state.json
```

**Step 5.7.3: Update TODO.md frontmatter**:

Read TODO.md and update the YAML frontmatter `technical_debt` section to match state.json:
```bash
# Using Edit tool to update TODO.md frontmatter
# old_string: current technical_debt block
# new_string: updated technical_debt block with current values
```

The technical_debt block should be updated to:
```yaml
technical_debt:
  todo_count: {todo_count}
  fixme_count: {fixme_count}
  build_errors: {build_errors}
  status: {status}
```

Also update `last_assessed` in repository_health:
```yaml
repository_health:
  overall_score: 90
  production_readiness: improved
  last_assessed: {ts}
```

**Step 5.7.4: Report metrics sync**:
Track for output:
- `metrics_todo_count`: Current TODO count
- `metrics_fixme_count`: Current FIXME count
- `metrics_build_errors`: Current build errors
- `metrics_synced`: true/false indicating if sync was performed

### 5.8. Regenerate Task Order

After syncing repository metrics, regenerate the Task Order section in TODO.md to reflect current task statuses.

**Run `generate-task-order.sh --update-todo`:**
```bash
# Regenerate Task Order (non-fatal -- continue if script unavailable or fails)
if [ -f ".claude/scripts/generate-task-order.sh" ]; then
  bash ".claude/scripts/generate-task-order.sh" --update-todo specs/TODO.md specs/state.json \
    || { echo "Warning: Task Order regeneration failed (non-fatal)" >&2; }
else
  echo "Note: generate-task-order.sh not found -- skipping Task Order regeneration" >&2
fi
```

**Purpose**: Keep Task Order wave+tree format current with archived tasks removed and statuses updated.

**Non-fatal**: If the script fails for any reason, log the warning and continue.

### 5.7. Vault Operation (when next_project_number > 1000)

When `next_project_number` exceeds 1000, run the vault operation utility:

**Step 5.8.1: Detect vault threshold**:
```bash
next_num=$(jq -r '.next_project_number' specs/state.json)
if [ "$next_num" -gt 1000 ]; then
  vault_needed=true
fi
```

**Step 5.8.3: User confirmation** (if vault_needed):

Use AskUserQuestion with vault operation details:
```json
{
  "question": "Task numbering has exceeded 1000. Initiate vault archival?",
  "header": "Vault Operation",
  "description": "Current next_project_number: {next_num}\nActive tasks to renumber: {renumber_count}\n\nThis will:\n1. Move specs/archive/ to specs/vault/{NN-vault}/\n2. Renumber tasks > 1000 by subtracting 1000\n3. Reset next_project_number",
  "options": [
    {"label": "Yes, proceed with vault operation", "value": "proceed"},
    {"label": "No, skip vault this time", "value": "skip"}
  ]
}
```

If user selects "proceed", run the vault operation:
```bash
bash .claude/scripts/vault-operation.sh "specs/state.json" --confirmed
```

If user selects "skip", proceed to Step 6 (Git Commit).

Track vault operations for output:
- `vault_created`: true/false
- `tasks_renumbered`: count of tasks renumbered (from vault-operation.sh output)
- `new_next_project_number`: reset value

### 6. Git Commit

```bash
git add specs/
git commit -m "todo: archive {N} completed tasks"
```

Include roadmap, orphan, misplaced, harvest, and Task Order counts in message as applicable:
```bash
# If roadmap items updated, orphans tracked, and misplaced moved:
git commit -m "todo: archive {N} tasks, update {R} roadmap items, track {M} orphans, move {P} misplaced"

# If roadmap items updated only:
git commit -m "todo: archive {N} tasks, update {R} roadmap items"

# If roadmap items updated and orphans tracked:
git commit -m "todo: archive {N} tasks, update {R} roadmap items, track {M} orphaned directories"

# If orphans tracked and misplaced moved (no roadmap):
git commit -m "todo: archive {N} tasks, track {M} orphans, move {P} misplaced directories"

# If only orphans tracked (no roadmap):
git commit -m "todo: archive {N} tasks and track {M} orphaned directories"

# If only misplaced moved (no roadmap):
git commit -m "todo: archive {N} tasks and move {P} misplaced directories"
```

Where `{R}` = roadmap_completed_annotated + roadmap_abandoned_annotated (total roadmap items updated).

**Note**: When Task Order regeneration ran (Step 5.8), append `, regenerate task order` to the commit message.

### 7. Output

Use grouped counts instead of listing individual items:

```
Archived {N} tasks

Tasks: {C} completed, {A} abandoned
Directories: {D} moved
Memories: {H} harvested

{If orphans or misplaced processed:}
Cleanup: {O} orphans tracked, {P} misplaced moved

{If roadmap updated:}
Roadmap: {R} items updated

{If CLAUDE.md suggestions:}
CLAUDE.md: {applied}/{total} suggestions applied

Active tasks remaining: {N}

Next Steps:
1. Review archive at specs/archive/
2. Run /review for codebase analysis
```

**Section Inclusion Rules:**

| Section | Show When |
|---------|-----------|
| Tasks | Always (with counts) |
| Directories | directories_moved > 0 |
| Memories | total_harvested > 0 |
| Cleanup | orphans_tracked > 0 OR misplaced_moved > 0 |
| Roadmap | roadmap items updated |

If no roadmap items were updated (no matches found in Step 3.5):
- Omit the "Roadmap updated" section

## Notes

### Task Archival
- Artifacts (plans, reports, summaries) are preserved in archive/{NNN}_{SLUG}/
- Tasks can be recovered with `/task --recover N`
- Archive is append-only (for audit trail)

### Memory Harvest
- Memory candidates with confidence >= 0.7 are harvested before each task is archived
- Idempotent: duplicate candidates are skipped via memory-index.json deduplication
- See `.claude/scripts/memory-harvest.sh` for implementation details

### Utility Scripts

| Script | Purpose | Called in Step |
|--------|---------|----------------|
| `orphan-detection.sh` | Detect orphaned/misplaced directories | 2.5 |
| `memory-harvest.sh` | Harvest memory candidates from tasks | 5.0 |
| `archive-task.sh` | Archive single task (state + directory) | 5.0 (loop) |
| `roadmap-sync.sh scan` | Scan ROADMAP.md for task matches | 3.5 |
| `roadmap-sync.sh apply` | Apply completion annotations | 5.5 |
| `vault-operation.sh` | Vault archival when task numbers > 1000 | 5.7 |

All scripts are in `.claude/scripts/`.

### Directory Categories

| Category | Location | In state.json? | In archive/state.json? | Action |
|----------|----------|----------------|------------------------|--------|
| Active | specs/ | Yes | No | Normal (no action) |
| Orphaned in specs/ | specs/ | No | No | Move + add state entry |
| Orphaned in archive/ | archive/ | No | No | Add state entry only |
| Misplaced | specs/ | No | Yes | Move only (state correct) |
| Archived | archive/ | No | Yes | Normal (no action) |

### Roadmap Annotation Formats

Completed tasks (explicit match):
```markdown
- [x] {item text} *(Completed: Task {N}, {DATE})*
```

Completed tasks (exact Task N reference):
```markdown
- [x] {item text} (Task {N}) *(Completed: Task {N}, {DATE})*
```

Abandoned tasks:
```markdown
- [ ] {item text} (Task {N}) *(Task {N} abandoned: {short_reason})*
```

**Safety**: Skip items already containing `*(Completed:` or `*(Task` annotations.

### jq Pattern Safety (Issue #1132)

Use `del()` for exclusion and `select(.type == "X" | not)` instead of `select(.type != "X")`.
See `.claude/context/patterns/jq-escaping-workarounds.md` for comprehensive patterns.
