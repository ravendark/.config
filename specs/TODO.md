---
next_project_number: 638
---

# TODO

## Task Order

*Updated 2026-06-08. Generated from state.json dependency graph.*

**Dependency Waves**:
| Wave | Tasks | Blocked by | Topics |
|------|-------|------------|--------|
| 1 | 78,87,634,635 | -- | -- |
| 2 | 636 | 634,635 | -- |
| 3 | 637 | 634,635,636 | -- |

**Grouped by Topic** (indented = depends on parent):

### Uncategorized

78 [PLANNED] — fix himalaya smtp authentication failure
87 [RESEARCHED] — investigate wezterm terminal directory change
634 [PLANNED] — port orchestrator system
  └─ 636 [NOT STARTED] — sync context rules extensions cleanup
    └─ 637 [NOT STARTED] — verification and drift detection
  └─ 637 [NOT STARTED] — verification and drift detection (see above)
635 [NOT STARTED] — port synthesis domain agents
  └─ 636 [NOT STARTED] — sync context rules extensions cleanup (see above)
  └─ 637 [NOT STARTED] — verification and drift detection (see above)

## Tasks

### 633. Port core script infrastructure from .claude/ to .opencode/
- **Effort**: 3-4 hours
- **Status**: [COMPLETED]
- **Task Type**: meta
- **Dependencies**: None

**Artifacts**:
- [Research Report](633_port_core_script_infrastructure/reports/01_core_script_infra_research.md)
- [Implementation Plan](633_port_core_script_infrastructure/plans/01_core_script_infra_plan.md)
- **Summary**: [633_port_core_script_infrastructure/summaries/01_core_script_infra-summary.md]

**Description**: Port all 14+ missing scripts from `.claude/scripts/` to `.opencode/scripts/`, including:
- `skill-base.sh` (516 lines) - shared lifecycle functions, extension hooks, orchestrator_mode
- Gate/routing scripts: `command-gate-in.sh`, `command-gate-out.sh`, `command-route-skill.sh`, `dispatch-agent.sh`
- Unified postflight: `postflight-workflow.sh`
- Support scripts: `archive-task.sh`, `generate-task-order.sh`, `tier-selection.sh`, `issue-grouping.sh`, `orphan-detection.sh`, `memory-harvest.sh`, `vault-operation.sh`, `validate-context-budgets.sh`, `parse-command-args.sh`
- Roadmap scripts as applicable

Adapt each script for `.opencode/` paths and conventions.

---

### 634. Port orchestrator system (.claude/ to .opencode/)
- **Effort**: 2-3 hours
- **Status**: [PLANNED]
- **Task Type**: meta
- **Dependencies**: Task #633
- **Research**: [634_port_orchestrator_system/reports/01_port_orchestrator_research.md]
- **Plan**: [634_port_orchestrator_system/plans/01_port_orchestrator_plan.md]

**Description**: Port the orchestrator system:
- `/orchestrate` command definition
- `skill-orchestrate` skill (1129 lines)
- Addition of orchestrator_mode to relevant skills
- Any orchestrator-related agents

---

### 635. Port synthesis and domain agents (.claude/ to .opencode/)
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: Task #633

**Description**: Port synthesis and domain-specific agents:
- `synthesis-agent.md`
- `neovim-*` agents (implementation, research)
- `nix-*` agents (implementation, research)
- `lean-implementation-agent`
- Update skill frontmatter to reference new agents

---

### 636. Sync context, rules, extensions, and cleanup (.claude/ to .opencode/)
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: Task #633, #634, #635

**Description**: Sync remaining components:
- Context files that are stale in .opencode/
- Missing rules: `neovim-lua.md`, `nix.md`
- Extension hooks in all manifests
- Delete stale `status-transitions.md` from both locations (if applicable)
- Sync settings.json

---

### 637. Verification and drift detection
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Task Type**: meta
- **Dependencies**: Task #633, #634, #635, #636

**Description**: End-to-end verification:
- Compare all .claude/ vs .opencode/ components for parity
- Verify dependency integrity
- Test key workflows
- Report any remaining gaps

---

### 87. Investigate terminal directory change when opening neovim in wezterm
- **Effort**: TBD
- **Status**: [PLANNED]
- **Research Started**: 2026-02-13
- **Research Completed**: 2026-02-13
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [087_investigate_wezterm_terminal_directory_change/reports/research-001.md]

**Description**: Investigate why the terminal working directory changes to a project root when opening neovim sessions in wezterm from the home directory (~). Determine whether this behavior is caused by neovim or wezterm (configured in ~/.dotfiles/config/). Identify if any functionality depends on this behavior before modifying it. Goal is to avoid changing the terminal directory unless necessary.

---

### 78. Fix Himalaya SMTP authentication failure when sending emails
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Task Type**: neovim
- **Dependencies**: None
- **Research**: [078_fix_himalaya_smtp_authentication_failure/reports/research-001.md]
- **Plan**: [078_fix_himalaya_smtp_authentication_failure/plans/implementation-001.md]

**Description**: Fix Gmail SMTP authentication failure when sending emails via Himalaya (<leader>me). Error: "Authentication failed: Code: 535, Enhanced code: 5.7.8, Message: Username and Password not accepted". The error occurs with TLS connection attempts and persists through multiple retry attempts. Identify and fix the root cause of the SMTP credential configuration.

