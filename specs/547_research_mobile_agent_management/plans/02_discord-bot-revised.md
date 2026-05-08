# Implementation Plan: Discord Bot and Neovim Integration for Mobile Agent Management (v2)

- **Task**: 547 - research_mobile_agent_management
- **Status**: [NOT STARTED]
- **Effort**: 10 hours
- **Dependencies**: None (NixOS prerequisites handled separately; P0 preflight gates relay phase)
- **Research Inputs**:
  - specs/547_research_mobile_agent_management/reports/01_mobile-agent-management-research.md (v1 baseline)
  - specs/547_research_mobile_agent_management/reports/02_team-research.md (round 2 synthesis -- 10 findings)
- **Artifacts**: plans/02_discord-bot-revised.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: markdown

## Overview

Build a production-quality Discord bot application and Neovim integration that bridges OpenCode agent sessions to Discord threads for mobile (iPhone) access. The bot is a thin relay (not an agent itself), consuming zero additional LLM tokens. This v2 plan incorporates 10 findings from round 2 team research: a P0 preflight phase for Discord intent/permission prerequisites, message pagination for 2000-char limits, gateway reconnect with outbound queue, thread lifecycle management, systemd security hardening, concurrent Pi development, CrewAI/AutoGen conceptual patterns, Channel-Oriented Agent Teams as strategic target, verified single-bot-token sufficiency, and implicit channel switching via Discord threads.

### Research Integration

**Round 1 (v1 baseline)**: OpenCode headless CLI (`opencode serve`, `opencode run --command`, `opencode session`), Nextcord 3.1.1, `/rc` slash command group, 1:1 session-to-thread mapping, `:OpenCodeLinkDiscord`, systemd pattern from `opencode-refresh.service`.

**Round 2 findings integrated in this v2 plan**:
1. **P0 preflight phase** (new Phase 1): MESSAGE_CONTENT intent filing, `opencode run --command` blocking behavior test, bot permission inventory -- all gating relay functionality
2. **Message pagination/splitting** (Phase 5): 2000-char Discord limit requires splitting or file attachment for OpenCode responses
3. **Gateway reconnect handler** (Phase 5): Outbound message queue prevents silent message loss on disconnect
4. **Thread auto-archive to 7 days** (Phase 5): Set `auto_archive_duration=10080` at thread creation
5. **Systemd security hardening** (Phase 7): `NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome=read-only`, `PrivateTmp`
6. **Pi concurrent development** (Overview & Phase 5): Pi deployment proceeds in parallel with bot code; bot assumes multiple hosts from start
7. **CrewAI/AutoGen patterns** (Phase 5): Flow+Crew and SelectorGroupChat patterns inform `SessionStore`/`AgentRegistry` design
8. **Single bot token** (confirmed): No multi-bot federation needed
9. **Implicit channel switching** (Phase 5): Discord threads provide natural context switching, no explicit mechanism needed
10. **Channel-Oriented Agent Teams readiness** (Phase 5): `SessionStore`/`AgentRegistry` abstraction supports both 1:1 thread-to-session and channel-to-team mappings from the start

### Prior Plan Reference

The v1 plan (01_discord-bot-neovim-setup.md, 6 phases, 8 hours) established the solid foundation: bot scaffolding, `/rc` command groups, OpenCode server integration, session-thread mapping, Neovim `:OpenCodeLinkDiscord`, and production readiness. This v2 plan preserves its phase structure but:
- Inserts a P0 preflight phase before scaffolding
- Adds 4 new tasks to the relay phase (pagination, reconnect queue, thread auto-archive, AgentRegistry abstraction)
- Adds 3 systemd security directives to the hardening phase
- Increases effort from 8h to 10h to accommodate additions
- Notes Pi deployment as concurrent, not sequential

### Roadmap Alignment

This plan does not directly advance current ROADMAP.md Phase 1 items (documentation infrastructure + agent system quality), but the team research report (D) identifies that future `/rc` commands can accelerate 4 roadmap items:
- Manifest-driven README generation -> `/rc generate-readme`
- CI doc-lint enforcement -> bot CI monitoring
- Slim standard enforcement -> `/rc lint-extension`
- Agent frontmatter validation -> `/rc validate-agents`

These are out of scope for the MVP but are natural expansions post-deployment.

## Goals & Non-Goals

**Goals**:
- P0 preflight: resolve MESSAGE_CONTENT intent, test `opencode run` behavior, create permission inventory
- Discord bot Python application using Nextcord 3.1.1 with `/rc` slash command group
- `/rc session join/list/leave` for session management from Discord
- `/rc task status/create/research/plan/implement` for task lifecycle from Discord
- `/rc status` for system health overview
- `/rc refresh` for cleanup operations
- Bot-to-OpenCode communication via `opencode run --command` and `opencode run`
- 1:1 session-to-Discord-thread mapping with persistent state store
- Message pagination/splitting for responses exceeding 2000 chars
- Gateway reconnect with outbound message queue
- Thread auto-archive set to 7 days at creation
- `SessionStore`/`AgentRegistry` abstraction supporting future Channel-Oriented Agent Teams
- Neovim `:OpenCodeLinkDiscord` command with `<leader>ar` keymap
- Local HTTP API on the bot for Neovim command to call
- Systemd service definition with security hardening directives
- Discord user ID whitelisting for authorization
- Bot token stored via environment variable, never hardcoded
- Structured JSON logging to journald

**Non-Goals**:
- NixOS SSH/Mosh/firewall setup (handled separately)
- sops-nix secrets management (handled separately)
- Raspberry Pi physical setup (concurrent infrastructure, not part of bot codebase)
- Discord bot for anything beyond OpenCode relay (no general-purpose bot)
- Mobile client other than Discord (Discord on iPhone is the target)
- Multi-user bot (single-user whitelist for initial deployment)
- SQLite-backed store (JSON for MVP; SQLite migration planned for multi-agent phase)
- Channel-Oriented Agent Teams (strategic target, not MVP; architecture supports future transition)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| MESSAGE_CONTENT intent denied by Discord | Critical | Low | File for approval immediately (Phase 1); fallback to slash-command-only relay mode; bot remains functional for command dispatch |
| `opencode run --command` blocks indefinitely on long tasks | High | Medium | Test actual durations in Phase 1; set subprocess timeout (120s default); long tasks return async task ID; status polling via `/rc task status`; stream JSON events incrementally |
| Discord bot token exposure | Critical | Low | Token via `DISCORD_BOT_TOKEN` env var only; never logged; systemd service runs as dedicated user with restricted permissions; `ProtectHome=read-only` |
| OpenCode server crashes leave orphaned session state | Medium | Medium | Leverage existing `opencode-refresh.timer`; add heartbeat check in bot health endpoint; auto-clean stale sessions on startup; state reconstruction on gateway reconnect |
| Gateway disconnect drops in-flight relayed responses | Medium | Medium | Outbound message queue with retry (Phase 5); reconstruct state from `sessions.json` + `opencode session list` on reconnect; halt retries at 401/403 threshold to avoid Cloudflare ban |
| Thread auto-archive during paused sessions | Medium | Medium | Set 7-day archive duration at creation (Phase 5); auto-unarchive on message send; optional heartbeat messages on a schedule |
| Session ID discovery unreliable (multiple OpenCode processes) | Medium | Medium | `opencode session list` provides authoritative listing; bot queries on startup and periodically; Neovim command passes explicit session ID |
| `<leader>ar` keymap collision | Low | Low | `<leader>ar` is currently unused in which-key (autolist uses `<leader>Lr`, not `<leader>ar`); verified free |
| Pi hardware unavailable or underpowered | Medium | Low | Bot development proceeds independently on local machine; Pi is scaling target, not MVP blocker; bot assumes multiple hosts from Phase 1 architecture |

## Implementation Phases

**Dependency Analysis**:
| Wave | Phases | Blocked by |
|------|--------|------------|
| 1 | 1, 2 | -- |
| 2 | 3 | 2 |
| 3 | 4 | 1, 2 |
| 4 | 5 | 3, 4 |
| 5 | 6 | 5 |
| 6 | 7 | 2, 3, 4, 5, 6 |

Phases within the same wave can execute in parallel. Phase 1 (P0 preflight) and Phase 2 (scaffolding) can start concurrently -- Phase 2's code scaffolding proceeds while Discord approvals are pending. Phase 4 waits for Phase 1's `opencode run` test results. Phase 5 waits for MESSAGE_CONTENT intent approval.

### Phase 1: P0 Preflight -- Discord Permissions and OpenCode Testing [NOT STARTED]

**Goal**: Resolve three prerequisites that gate full relay functionality: file for Discord MESSAGE_CONTENT privileged intent, test `opencode run --command` blocking behavior, and create the bot permission inventory with invite URL.

**Tasks**:
- [ ] **Task 1.1**: Create Discord application at discord.com/developers, file for MESSAGE_CONTENT privileged intent (gateway intent bit `1 << 15`), document expected approval timeline and fallback (slash-command-only relay mode)
- [ ] **Task 1.2**: Test `opencode run --command` behavior -- run `/research {test_task}`, `/implement {test_task}`, `/plan {test_task}` via `opencode run --command`; measure actual wall-clock durations for small/medium/complex tasks; determine if `--format json` streams events incrementally or returns only final result; document findings as input to Phase 4 executor design
- [ ] **Task 1.3**: Create bot invite URL with exact permissions: `SEND_MESSAGES_IN_THREADS` (required for relay), `CREATE_PUBLIC_THREADS`, `MANAGE_THREADS`, `READ_MESSAGE_HISTORY`, `USE_APPLICATION_COMMANDS`; verify `SEND_MESSAGES` alone does NOT cover threads
- [ ] **Task 1.4**: Document findings in `specs/547_research_mobile_agent_management/reports/03_p0-preflight.md` -- MESSAGE_CONTENT status/timeline, `opencode run` timing results, permission URL, and any architecture implications

**Timing**: 1 hour

**Depends on**: none

**Verification**:
- Discord application exists with MESSAGE_CONTENT intent filed
- `opencode run` timing data captured for at least one research, plan, and implement operation
- Bot invite URL covers all 5 required permissions plus gateway intents (GUILDS, GUILD_MESSAGES, MESSAGE_CONTENT)
- Report documents any surprises (e.g., `opencode run` blocks for 30+ min, JSON not streamed)

---

### Phase 2: Bot Project Scaffolding [NOT STARTED]

**Goal**: Establish the Python project structure, dependencies, configuration management, logging, and a minimal Nextcord bot that connects to Discord and responds to a ping command. Can run in parallel with Phase 1.

**Tasks**:
- [ ] **Task 2.1**: Create project directory structure at `~/.dotfiles/opencode-discord-bot/` with `src/`, `config/`, `tests/`, and `README.md`
- [ ] **Task 2.2**: Write `requirements.txt` (or `pyproject.toml`) pinning nextcord>=3.1.1 and anyio for structured concurrency
- [ ] **Task 2.3**: Implement `config/settings.py` -- load `DISCORD_BOT_TOKEN` from env, `WHITELISTED_USER_IDS` from env (comma-separated), `OPENCODE_SERVER_URL` (default `http://127.0.0.1:4096`), `OPENCODE_SERVER_PASSWORD` from env; add `LINK_API_TOKEN` for Phase 6 auth; add `MESSAGE_CONTENT_AVAILABLE` boolean flag (set from env, defaults to false until intent approved)
- [ ] **Task 2.4**: Implement `src/logging_config.py` -- structured JSON logger writing to stdout (captured by journald); log levels configurable via `LOG_LEVEL` env var
- [ ] **Task 2.5**: Implement `src/bot.py` -- minimal Nextcord bot with `on_ready` handler that logs bot user info, guild count, registered commands, and MESSAGE_CONTENT availability warning; add a `/rc ping` command that responds with latency and uptime; register gateway intents (GUILDS, GUILD_MESSAGES, MESSAGE_CONTENT conditional on flag)
- [ ] **Task 2.6**: Verify bot starts, connects to Discord, and `/rc ping` responds correctly

**Timing**: 1.5 hours

**Depends on**: none (can run parallel with Phase 1)

**Verification**:
- Bot starts without errors; logs show successful Discord connection
- `/rc ping` in Discord returns bot latency and uptime
- `DISCORD_BOT_TOKEN` not logged or printed anywhere
- JSON log lines appear in stdout with timestamp, level, message fields
- Conditional MESSAGE_CONTENT intent registration works (flag=false -> no crash, just warning log)

---

### Phase 3: Core `/rc` Slash Commands [NOT STARTED]

**Goal**: Implement all Discord slash commands under the `/rc` group with proper input validation, error handling, and user-facing feedback. Commands should be fully functional end-to-end (returning mock/simulated data before Phase 4 connects to OpenCode).

**Tasks**:
- [ ] **Task 3.1**: Implement command registration structure -- a `commands/` package with `__init__.py` that registers all command cogs; each command group (session, task, system) as a separate cog
- [ ] **Task 3.2**: Implement `src/commands/session_cog.py` -- `/rc session join [session_id]` (accepts optional session ID, lists available if omitted), `/rc session list` (shows all active sessions with status), `/rc session leave` (closes the Discord thread linked to current session)
- [ ] **Task 3.3**: Implement `src/commands/task_cog.py` -- `/rc task status [task_number]` (shows task state from TODO.md/state.json), `/rc task create "description"` (creates a new task), `/rc task research [N]`, `/rc task plan [N]`, `/rc task implement [N]` (trigger respective commands)
- [ ] **Task 3.4**: Implement `src/commands/system_cog.py` -- `/rc status` (system overview: CPU, memory, active sessions, running tasks), `/rc refresh` (triggers orphaned process cleanup via existing `opencode-refresh.sh`)
- [ ] **Task 3.5**: Add authorization check decorator -- before every command, verify `ctx.user.id` is in `WHITELISTED_USER_IDS`; return ephemeral "unauthorized" message for non-whitelisted users
- [ ] **Task 3.6**: Add command-level rate limiting -- max 10 commands per minute per user; configurable via `RATE_LIMIT_PER_MINUTE` env var; use an in-memory sliding window

**Timing**: 2 hours

**Depends on**: 2

**Verification**:
- All `/rc` commands appear in Discord with correct names, descriptions, and parameter schemas
- Commands return appropriate ephemeral or channel messages
- Non-whitelisted users receive "unauthorized" messages
- Rate limit exceeded produces a 429-style ephemeral response
- Commands work from iPhone Discord client (slash command autocomplete, mobile-friendly responses)

---

### Phase 4: OpenCode Server Integration [NOT STARTED]

**Goal**: Build the bridge layer that discovers running OpenCode server instances, authenticates via `OPENCODE_SERVER_PASSWORD`, and executes commands via `opencode run --command`. Incorporates Phase 1's `opencode run` test results for executor design. This is the core infrastructure that all `/rc` commands will call.

**Tasks**:
- [ ] **Task 4.1**: Implement `src/opencode/client.py` -- `OpenCodeClient` class that wraps `opencode session list` (to discover active sessions/ports), `opencode run --command <cmd> --format json` (for command execution), and `opencode run <message> --continue --session <id>` (for message relay); incorporate Phase 1 findings on blocking behavior and JSON streaming
- [ ] **Task 4.2**: Implement server discovery -- parse output of `opencode session list` to find active server URLs and session IDs; cache results with 30-second TTL; support explicit `OPENCODE_SERVER_URL` override for single-server deployments; design for multiple hosts (Pi + desktop) from start
- [ ] **Task 4.3**: Implement authentication -- set `OPENCODE_SERVER_PASSWORD` env var before `opencode run` calls; handle auth failures with clear error messages; retry once on auth error in case server just restarted
- [ ] **Task 4.4**: Implement `src/opencode/executor.py` -- async subprocess runner for `opencode` CLI with timeout (default 120s, configurable per command type based on Phase 1 data), stdout/stderr capture, and JSON output parsing; handle `--format json` streaming for long-running tasks; if `opencode run` blocks indefinitely, spawn as background process with status polling via `opencode session list`
- [ ] **Task 4.5**: Wire Phase 3 commands to use the client -- replace mock responses in session/task/system cogs with real OpenCode client calls; handle errors gracefully (server down, command timeout, parse failure) with user-friendly Discord messages
- [ ] **Task 4.6**: Add concurrency control -- max 3 concurrent `opencode run` processes; queue additional requests; expose queue depth in `/rc status`

**Timing**: 2 hours

**Depends on**: 1, 2

**Verification**:
- `OpenCodeClient.list_sessions()` returns correct list of active sessions from `opencode session list`
- `opencode run --command status --format json` executes and returns parsed JSON
- Commands timeout after configured duration and return partial results
- Authentication failures produce clear error messages
- Server-down state is handled gracefully (commands return "OpenCode server unavailable")
- Concurrent execution respects the max-3-processes limit
- Background execution model works if `opencode run` blocks (tested per Phase 1 findings)

---

### Phase 5: Session-to-Thread Mapping, Message Relay, and Resilience [NOT STARTED]

**Goal**: Build the persistent mapping store (designed for Channel-Oriented Agent Teams readiness), implement the core message relay loop with pagination and reconnection handling, add thread lifecycle management, and create the local HTTP API for Neovim linking.

**Tasks**:
- [ ] **Task 5.1**: Implement `src/state/store.py` -- `SessionStore` / `AgentRegistry` class backed by a JSON file at `~/.dotfiles/opencode-discord-bot/data/sessions.json`; interface abstracts backend (JSON now, SQLite-ready later); operations: `link(session_id, thread_id, channel_id, role=None)` (role field for future COAT), `unlink(session_id)`, `lookup_by_session(session_id)`, `lookup_by_thread(thread_id)`, `list_all()`, `list_by_role(role)` (future); file is read on startup and written on every mutation with atomic write (write to temp file, then rename); storage schema supports both 1:1 thread-to-session and channel-to-team mappings
- [ ] **Task 5.2**: Implement `src/relay.py` -- `MessageRelay` class with `relay_to_opencode(thread_id, message_content)` (looks up session by thread, calls `opencode run <message> --continue --session <id>`, returns response) and `relay_to_discord(session_id, response_text)` (looks up thread by session, sends message to that thread via Nextcord); **pagination**: split responses exceeding 2000 characters across multiple messages with continuation indicators (`(1/3)`, `(2/3)`, `(3/3)`); for very large outputs (>10k chars), attach as `.txt` file in addition to a summary message
- [ ] **Task 5.3**: Implement gateway reconnect handler -- outbound message queue (per-agent deque, max 100 messages) that persists unsent messages during disconnect; on reconnect, reconstruct state from `sessions.json` + `opencode session list`; drain queue in order; halt retries if 401/403 error count exceeds threshold (Cloudflare ban prevention); log reconnect events and queue depth
- [ ] **Task 5.4**: Implement Discord `on_message` handler -- intercept messages in linked threads (check store); ignore bot's own messages; if MESSAGE_CONTENT intent is available, forward content to `relay_to_opencode` and relay response back to thread; add typing indicator while processing; if MESSAGE_CONTENT not yet available, respond with ephemeral "relay unavailable -- MESSAGE_CONTENT intent pending approval" via slash command context
- [ ] **Task 5.5**: Add thread lifecycle management -- at thread creation, explicitly set `auto_archive_duration` to 10080 minutes (7 days); auto-unarchive threads on message send; periodic cleanup (every 5 min) detects stale sessions (no longer in `opencode session list`) and archives their threads; log all archive/unarchive events
- [ ] **Task 5.6**: Implement the local HTTP API using aiohttp -- `POST /link` (body: `{"session_id": "...", "session_name": "..."}`) creates a Discord thread in a designated channel, sets 7-day auto-archive, and stores the mapping; returns thread ID and jump URL; `GET /health` returns bot status, linked session count, MESSAGE_CONTENT availability; `GET /sessions` lists all linked sessions with thread URLs
- [ ] **Task 5.7**: Wire `/rc session join` to use the store -- when user specifies a session ID, create a thread with 7-day archive and store the mapping; `/rc session list` shows both linked and unlinked sessions with archive status and thread URLs; `/rc session leave` removes mapping and archives thread

**Timing**: 2.5 hours

**Depends on**: 3, 4

**Verification**:
- Linking a session via the HTTP API creates a Discord thread with 7-day auto-archive and stores the mapping
- Sending a message in a linked Discord thread triggers `opencode run` with the stored session ID (if MESSAGE_CONTENT approved)
- OpenCode response appears in the same Discord thread, paginated across multiple messages if >2000 chars
- Unlinking a session archives the thread and removes the store entry
- Store survives bot restart (sessions.json loaded on startup)
- Gateway disconnect does not lose in-flight messages (queue drains on reconnect)
- Thread auto-unarchives when a new message is sent to it
- `/rc session list` shows correct linked/unlinked status with thread URLs
- HTTP API returns correct health data including MESSAGE_CONTENT availability
- `AgentRegistry` role field is present but unused until COAT development

---

### Phase 6: Neovim `:OpenCodeLinkDiscord` Command and `<leader>ar` Keymap [NOT STARTED]

**Goal**: Create the Neovim user command `:OpenCodeLinkDiscord` that discovers the current OpenCode session, calls the bot's HTTP API (with auth token) to link it to a Discord thread, and displays the Discord jump URL to the user. Bind it to `<leader>ar`. Update which-key.

**Tasks**:
- [ ] **Task 6.1**: Determine the current OpenCode session ID within Neovim -- inspect the running `opencode --port` process; extract the port number; use `opencode session list` (filtered to current working directory) to find the matching session ID; handle the case where no session is active
- [ ] **Task 6.2**: Implement `lua/neotex/plugins/ai/opencode/discord-link.lua` -- module with `link_current_session()` function that calls the bot's HTTP `POST /link` endpoint with `Authorization: Bearer <LINK_API_TOKEN>` header, session ID, directory name, and optional description; parse the response to get the Discord thread jump URL
- [ ] **Task 6.3**: Register `:OpenCodeLinkDiscord` user command -- `vim.api.nvim_create_user_command("OpenCodeLinkDiscord", ...)` with `{ desc = "Link current OpenCode session to Discord thread" }`; command calls `link_current_session()` and displays the thread URL with a `vim.notify` (level INFO) and copies it to clipboard
- [ ] **Task 6.4**: Add `<leader>ar` keymap -- in `lua/neotex/plugins/ai/opencode.lua`, add to the `keys = {}` table: `{ "<leader>ar", "<cmd>OpenCodeLinkDiscord<CR>", desc = "Link session to Discord" }`; ensure it registers in the `<leader>a` (ai) group in which-key
- [ ] **Task 6.5**: Update `lua/neotex/plugins/editor/which-key.lua` -- add the `<leader>ar` entry in the `<leader>a` group section with `desc = "link discord session"` and `icon = "󰙯"` (Discord icon)
- [ ] **Task 6.6**: Handle error cases -- no active OpenCode session (notify user to start one first), bot HTTP API unreachable (notify user to start the bot), auth token missing/invalid (notify user to configure LINK_API_TOKEN), session already linked (notify with existing thread URL), linking fails (show error from API response)

**Timing**: 1.5 hours

**Depends on**: 5

**Verification**:
- `:OpenCodeLinkDiscord` in a Neovim instance with an active OpenCode session calls the bot API successfully with auth token
- Discord thread URL is displayed in a notification and copied to clipboard
- Pressing `<leader>ar` triggers the same behavior
- `<leader>a` which-key popup shows `ar` with "link discord session" label
- Error messages are clear and actionable for all failure cases
- Running the command when no session is active shows "No active OpenCode session"

---

### Phase 7: Security Hardening, Systemd Service, and Production Readiness [NOT STARTED]

**Goal**: Lock down the bot for production use with systemd security directives, proper user isolation, token protection, structured journald logging, health checks, and end-to-end testing from iPhone.

**Tasks**:
- [ ] **Task 7.1**: Create `~/.dotfiles/opencode-discord-bot/systemd/opencode-discord-bot.service` -- systemd service file following the pattern from `opencode-refresh.service` with enhanced security: `Type=simple`, `EnvironmentFile` for secrets, `Restart=always`, `RestartSec=10`, `After=network-online.target`; log to journald via `StandardOutput=journal`; **security hardening**: `NoNewPrivileges=yes`, `ProtectSystem=strict` (with `ReadWritePaths=~/.dotfiles/opencode-discord-bot/data` for sessions.json), `ProtectHome=read-only`, `PrivateTmp=yes`, `PrivateDevices=yes`, `ProtectKernelTunables=yes`, `ProtectKernelModules=yes`, `RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX`, `SystemCallFilter=@system-service`, `DynamicUser=yes`
- [ ] **Task 7.2**: Lock down the HTTP API -- bind to `127.0.0.1` only (no external access); require `Authorization: Bearer <LINK_API_TOKEN>` header on all requests to `/link`, `/health`, `/sessions`; reject without valid token with 401; `LINK_API_TOKEN` loaded from env (matching Phase 2 config)
- [ ] **Task 7.3**: Add health check endpoint enhancements -- `/health` returns JSON with bot uptime, Discord connection status, gateway latency, MESSAGE_CONTENT availability, OpenCode server connectivity status, linked session count, active task count, outbound queue depth, and last error; systemd can use `ExecStartPost` to curl the health endpoint
- [ ] **Task 7.4**: Create `~/.dotfiles/opencode-discord-bot/config/env.production` -- template showing all required env vars (`DISCORD_BOT_TOKEN`, `WHITELISTED_USER_IDS`, `OPENCODE_SERVER_PASSWORD`, `LINK_API_TOKEN`, `LOG_LEVEL=info`, `MESSAGE_CONTENT_AVAILABLE=true`); document each variable and its security sensitivity
- [ ] **Task 7.5**: End-to-end verification -- start OpenCode session in Neovim, run `:OpenCodeLinkDiscord`, open Discord on iPhone, send a message in the thread, verify response appears (paginated if >2000 chars), test `/rc session list`, `/rc task status`, `/rc status` from iPhone; test error recovery: kill OpenCode server (bot detects and reports), stop/start bot (sessions.json reloads correctly), simulate gateway disconnect (queue drains on reconnect)
- [ ] **Task 7.6**: Write `~/.dotfiles/opencode-discord-bot/README.md` -- setup instructions, env var reference, systemd install commands (`systemctl enable --now opencode-discord-bot`), security model summary, troubleshooting, and iPhone usage guide

**Timing**: 1.5 hours

**Depends on**: 2, 3, 4, 5, 6

**Verification**:
- `systemctl start opencode-discord-bot` starts with all security directives active (verify via `systemd-analyze security opencode-discord-bot`)
- `journalctl -u opencode-discord-bot -f` shows structured JSON log lines
- Bot reconnects to Discord within 10 seconds of Discord API disruption; outbound queue drains
- HTTP API rejects requests without valid `Authorization: Bearer` header (401)
- Health endpoint returns accurate status including MESSAGE_CONTENT availability, queue depth, and OpenCode connectivity
- Full end-to-end flow works from iPhone: session linking, message relay (paginated), command execution
- Bot survives OpenCode server restart (detects and reconnects)
- `systemd-analyze security` score improves over unhardened service

## Testing & Validation

- [ ] Unit tests for `SessionStore`/`AgentRegistry` (link, unlink, lookup, atomic write, role storage) using pytest with temp files
- [ ] Unit tests for `OpenCodeClient.list_sessions()` parsing (mock subprocess output)
- [ ] Unit tests for message pagination logic (split at 2000 chars, file attachment threshold)
- [ ] Unit tests for `rate_limit` sliding window logic (fast-forward time in test)
- [ ] Unit tests for `auth` whitelist decorator (authorized and unauthorized paths)
- [ ] Unit tests for outbound message queue (enqueue, drain, overflow, halt-on-4xx)
- [ ] Integration test: bot startup, Discord connection, `/rc ping` response
- [ ] Integration test: HTTP API `POST /link` -> Discord thread creation (with 7-day archive) -> store mapping verification
- [ ] Integration test: message relay from Discord thread to OpenCode with pagination (mock server returns >2000 char response)
- [ ] Integration test: gateway disconnect simulation -> queue drain on reconnect
- [ ] Manual test: full iPhone end-to-end flow (Neovim link -> Discord thread -> paginated message -> response)
- [ ] Manual test: error recovery scenarios (kill OpenCode, restart bot, verify graceful degradation)
- [ ] Manual test: rate limit enforcement produces correct ephemeral messages
- [ ] Manual test: MESSAGE_CONTENT-unavailable fallback (slash command relay works, thread relay shows graceful message)

## Artifacts & Outputs

- `~/.dotfiles/opencode-discord-bot/src/bot.py` - main bot entry point with conditional MESSAGE_CONTENT intent
- `~/.dotfiles/opencode-discord-bot/src/commands/` - slash command cogs (session, task, system)
- `~/.dotfiles/opencode-discord-bot/src/opencode/client.py` - OpenCode CLI wrapper
- `~/.dotfiles/opencode-discord-bot/src/opencode/executor.py` - subprocess executor (Phase 1-informed)
- `~/.dotfiles/opencode-discord-bot/src/state/store.py` - SessionStore/AgentRegistry (COAT-ready abstraction)
- `~/.dotfiles/opencode-discord-bot/src/relay.py` - message relay with pagination + outbound queue
- `~/.dotfiles/opencode-discord-bot/src/api.py` - local HTTP API with auth token
- `~/.dotfiles/opencode-discord-bot/src/logging_config.py` - structured JSON logging
- `~/.dotfiles/opencode-discord-bot/src/auth.py` - authorization decorator
- `~/.dotfiles/opencode-discord-bot/src/rate_limit.py` - rate limiter
- `~/.dotfiles/opencode-discord-bot/config/settings.py` - configuration with MESSAGE_CONTENT flag
- `~/.dotfiles/opencode-discord-bot/config/env.production` - env var template (production)
- `~/.dotfiles/opencode-discord-bot/config/example.env` - env var template (dev)
- `~/.dotfiles/opencode-discord-bot/systemd/opencode-discord-bot.service` - systemd service with security hardening
- `~/.dotfiles/opencode-discord-bot/data/sessions.json` - persistent state (runtime)
- `~/.dotfiles/opencode-discord-bot/requirements.txt` - Python dependencies
- `~/.dotfiles/opencode-discord-bot/README.md` - setup and usage guide
- `lua/neotex/plugins/ai/opencode/discord-link.lua` - Neovim link module with auth token
- `lua/neotex/plugins/ai/opencode.lua` - updated with command and keymap
- `lua/neotex/plugins/editor/which-key.lua` - updated with `<leader>ar` entry
- `specs/547_research_mobile_agent_management/reports/03_p0-preflight.md` - P0 preflight results

## Rollback/Contingency

- **Bot removal**: `systemctl stop opencode-discord-bot && systemctl disable opencode-discord-bot` (no persistent side effects beyond `sessions.json`, safe to delete)
- **Neovim integration removal**: delete `discord-link.lua`, revert `opencode.lua` and `which-key.lua` changes from git
- **File system**: Bot writes only to `~/.dotfiles/opencode-discord-bot/data/sessions.json` and log output (journald); `ProtectSystem=strict` enforces this
- **Discord threads**: Standard threads created by the bot; manually archivable/deletable in Discord client; 7-day auto-archive provides long window for manual cleanup
- **No database migrations**: JSON file is self-describing; if SQLite migration occurs later, interface is abstracted behind `SessionStore`
- **Graceful degradation**: If bot is removed, Neovim `:OpenCodeLinkDiscord` fails with clear "bot unreachable" error; no cascading failures
- **MESSAGE_CONTENT fallback**: If intent is denied or delayed, `/rc` slash commands remain fully functional; only passive thread message relay is unavailable
