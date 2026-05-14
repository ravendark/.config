# Implementation Plan: Discord OpenCode Agents Guide

- **Task**: 571 - Create guide for using Discord to manage OpenCode agents from Neovim
- **Status**: [NOT STARTED]
- **Effort**: 1.5 hours
- **Dependencies**: None
- **Research Inputs**: reports/01_discord-opencode-guide.md, reports/02_link-api-token-setup.md
- **Artifacts**: plans/01_discord-opencode-guide.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: general
- **Lean Intent**: false

## Overview

Create a comprehensive workflow guide documenting how to use Discord to manage OpenCode agents from within Neovim. The guide targets an everyday user who already has the NixOS infrastructure running (services deployed, sops-nix secrets configured). It covers the three-tier architecture (Neovim -> Discord bot -> OpenCode server), the Neovim keybindings for linking and managing sessions, the environment variable requirements (now secured via sops-nix), service management commands, and known issues with troubleshooting steps. The definition of done is a single complete guide file at `.opencode/docs/guides/discord-opencode-agents.md` and an updated `guides/README.md`.

### Research Integration

Two research reports inform this plan:

1. **reports/01_discord-opencode-guide.md** -- Primary research covering the full system architecture, Neovim plugin implementations (`discord-link.lua`, `discord-session-picker.lua`), bot HTTP API endpoints, the everyday workflow pattern, environment variable requirements, and known issues (heartbeat blocking, LINK_API_TOKEN quirk, session discovery).

2. **reports/02_link-api-token-setup.md** -- Documents the completed sops-nix wiring of `link_api_token` through the full pipeline: `secrets.yaml` -> sops-nix decryption -> `/run/secrets/link_api_token` -> both the discord-bot service (via LoadCredential) and fish shell init (for Neovim). This supersedes the "empty token" issue described in report 01.

### Prior Plan Reference

No prior plan.

### Roadmap Alignment

This task does not directly advance any items in ROADMAP.md. It is a standalone documentation task for the Discord/OpenCode integration workflow.

### Literature Source Mapping

No literature source referenced.

## Goals & Non-Goals

**Goals**:
- Write a complete, self-contained guide for the everyday Discord + OpenCode + Neovim workflow
- Document the architecture at a level sufficient for troubleshooting (three-tier diagram)
- Cover prerequisites, quick-start steps, detailed workflow, keybinding reference, and troubleshooting
- Follow the existing guide conventions (matching `tts-stt-integration.md` style)
- Update `guides/README.md` to list the new guide

**Non-Goals**:
- Do not duplicate the NixOS infrastructure setup (that lives in `~/.dotfiles/docs/discord-bot.md`)
- Do not document OpenCode server internals beyond what the user needs for troubleshooting
- Do not modify any Lua plugin code or NixOS configuration
- Do not create separate guides for setup vs. usage -- one integrated document

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Guide becomes stale as bot evolves | M | M | Include "last verified" date and reference canonical source files |
| Heartbeat bug fix changes the troubleshooting steps | L | M | Document the symptom generically (HTTP API unresponsive) so fix steps remain valid |
| Token setup changes (sops-nix path or fish init location) | L | L | Reference `configuration.nix` as the source of truth rather than hardcoding paths |

## Implementation Phases

**Dependency Analysis**:
| Wave | Phases | Blocked by |
|------|--------|------------|
| 1 | 1 | -- |
| 2 | 2 | 1 |

Phases within the same wave can execute in parallel.

### Phase 1: Write the Guide Document [NOT STARTED]

**Goal**: Create the complete guide file at `/home/benjamin/.config/nvim/.opencode/docs/guides/discord-opencode-agents.md`.

**Tasks**:
- [ ] Create file with title and introductory overview (what the integration does, target audience: everyday users with running infrastructure)
- [ ] Write **Architecture** section with text-based three-tier diagram (Neovim -> Discord bot HTTP API -> OpenCode server -> Discord Gateway -> mobile)
- [ ] Write **Prerequisites** section covering:
  - Running services (`opencode-serve.service`, `discord-bot.service`)
  - sops-nix token pipeline (`DISCORD_BOT_LINK_TOKEN` set via fish shell init from `/run/secrets/link_api_token`)
  - Discord mobile app with access to the configured channel
  - Reference `~/.dotfiles/docs/discord-bot.md` for initial NixOS setup
- [ ] Write **Quick Start** section (3-step: open OpenCode in Neovim, `<leader>ar` to link, check Discord)
- [ ] Write **Everyday Workflow** section with detailed steps:
  - Starting an OpenCode session from Neovim
  - Linking to Discord with `<leader>ar` (what happens: session discovered, thread created, URL copied)
  - Monitoring from Discord mobile (responses appear in thread)
  - Sending instructions from Discord mobile (typed in thread, relayed to OpenCode)
  - Managing sessions with `<leader>as` (Telescope picker: `<CR>` kills, `<C-o>` copies URL)
- [ ] Write **Keybinding Reference** table (`<leader>ar`, `<leader>as`, Telescope actions)
- [ ] Write **Bot HTTP API Reference** section with endpoint table and example curl commands (health, sessions, link, kill)
- [ ] Write **Environment Variables** section covering both user-side (`DISCORD_BOT_URL`, `DISCORD_BOT_LINK_TOKEN`) and bot-side (managed by systemd, not user-set)
- [ ] Write **Service Management** section with systemctl commands (status, restart, logs via journalctl)
- [ ] Write **Troubleshooting** section covering:
  - HTTP API unresponsive / heartbeat blocking (symptom, diagnosis via journalctl, fix via restart)
  - `DISCORD_BOT_LINK_TOKEN not set` error (verify fish shell init, check `/run/secrets/link_api_token` exists)
  - Session discovery failures (no session for CWD, multiple sessions)
  - OpenCode server not running (check `opencode-serve.service`)
  - Discord thread not appearing (check bot token validity, channel ID)
- [ ] Write **Security Model** section (brief: sops-nix pipeline, no plaintext tokens, RAM-only tmpfs)
- [ ] Write **Related Resources** section with links to `discord-bot.md`, plugin source files, bot source code
- [ ] Review full document for accuracy against both research reports

**Timing**: 1 hour

**Depends on**: none

**Files to modify**:
- `/home/benjamin/.config/nvim/.opencode/docs/guides/discord-opencode-agents.md` - Create new guide file

**Verification**:
- Guide file exists at the expected path
- All sections listed above are present
- Architecture diagram is readable
- Keybinding table matches the actual plugin implementations
- Troubleshooting covers all known issues from research
- No duplicated NixOS setup content (references `discord-bot.md` instead)

---

### Phase 2: Update Guides README [NOT STARTED]

**Goal**: Add the new guide to the `guides/README.md` index so it is discoverable.

**Tasks**:
- [ ] Add a new subsection or entry under an appropriate category in `guides/README.md`
- [ ] Use category "Mobile/Remote Access" or "Integrations" (whichever fits best with existing structure)
- [ ] Entry format: `discord-opencode-agents.md` with a short description

**Timing**: 10 minutes

**Depends on**: 1

**Files to modify**:
- `/home/benjamin/.config/nvim/.opencode/docs/guides/README.md` - Add guide listing

**Verification**:
- README.md contains the new guide entry
- Entry description accurately reflects guide content
- Category placement is logical within the existing structure

## Testing & Validation

- [ ] Guide file exists at `/home/benjamin/.config/nvim/.opencode/docs/guides/discord-opencode-agents.md`
- [ ] All required sections are present (Architecture, Prerequisites, Quick Start, Everyday Workflow, Keybinding Reference, API Reference, Environment Variables, Service Management, Troubleshooting, Security Model, Related Resources)
- [ ] `guides/README.md` includes the new guide entry
- [ ] No broken cross-references or dead links
- [ ] Token setup information reflects the sops-nix pipeline (report 02), not the outdated "any non-empty string" pattern
- [ ] Guide follows existing conventions from `tts-stt-integration.md` (markdown structure, table formats, code block style)

## Artifacts & Outputs

- `/home/benjamin/.config/nvim/.opencode/docs/guides/discord-opencode-agents.md` - The workflow guide
- `/home/benjamin/.config/nvim/.opencode/docs/guides/README.md` - Updated index

## Rollback/Contingency

This is a documentation-only task with no code changes. Rollback is trivial:
- Delete the guide file: `rm .opencode/docs/guides/discord-opencode-agents.md`
- Revert the README.md edit via git: `git checkout -- .opencode/docs/guides/README.md`
