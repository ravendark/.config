# Discord OpenCode Agents Guide

This guide describes how to use Discord to monitor and manage OpenCode agents from within Neovim. It covers the everyday workflow for users who already have the NixOS infrastructure running.

For initial setup of the Discord bot infrastructure, see [`~/.dotfiles/docs/discord-bot.md`](~/.dotfiles/docs/discord-bot.md).

> **Last verified**: 2026-05-14

## Overview

The integration bridges OpenCode TUI sessions running inside Neovim with Discord threads, enabling:

- **Mobile monitoring**: Watch OpenCode agent progress from your phone
- **Remote instruction**: Send commands to OpenCode from Discord
- **Bidirectional relay**: Messages typed in the TUI also appear in Discord
- **Progress feedback**: Visual status embeds for long-running tasks

## Architecture

```
Neovim (opencode --port 3000) --[SSE]--> discord-bot.service (:8080) --[Discord Gateway]--> Mobile/Desktop
```

The bot subscribes to the TUI's SSE event stream using native async `aiohttp`. Messages typed in Discord are relayed to the TUI via `POST /session/{id}/message`. Responses flow back through the same SSE connection.

Key characteristics:

- **Single-path delivery**: The SSE subscriber handles all responses; no ThreadPoolExecutor or synchronous blocking is used
- **Auto-reconnection**: The SSE subscriber reconnects automatically with exponential backoff (2s to 60s) if the TUI restarts
- **Bidirectional**: Messages typed directly in the OpenCode TUI also appear in the linked Discord thread
- **Headless fallback**: The `opencode-serve` service on port 4096 exists for direct API use but is not part of the relay path
- **No TUI auth**: TUI instances on localhost do not require authentication; only the headless server uses HTTP Basic Auth

## Prerequisites

### Required Services

| Service | Status Check | Required? |
|---------|-------------|-----------|
| `discord-bot.service` | `systemctl status discord-bot` | Yes |
| `opencode-serve.service` | `systemctl status opencode-serve` | Optional (not needed for TUI relay) |

The bot service must be running before any Neovim integration works.

### Secrets and Environment

Your NixOS configuration should already have these sops-nix secrets configured:

| Secret | Purpose |
|--------|---------|
| `discord_bot_token` | Discord bot authentication |
| `opencode_server_password` | Headless server auth (fallback) |
| `discord_channel_id` | Channel where threads are created |
| `link_api_token` | Bearer token for bot HTTP API |
| `ollama_api_key` | LLM provider API key |

The `DISCORD_BOT_LINK_TOKEN` environment variable is set automatically by fish shell init from `/run/secrets/link_api_token`:

```fish
if test -r /run/secrets/link_api_token
  set -gx DISCORD_BOT_LINK_TOKEN (cat /run/secrets/link_api_token)
end
```

### Required Tools

- Discord app (mobile or desktop) with access to the configured channel
- Neovim with Telescope and the neotex plugin collection

## Quick Start

1. **Open Neovim** in your project directory
2. **Start OpenCode**: Press `<C-CR>` to open the AI tool picker, select OpenCode, then choose "Create new session" (starts `opencode --port 3000` on the configured port)
3. **Create a session**: Type a message in the TUI to create a session (sessions are not created until first interaction)
4. **Link to Discord**: Press `<leader>ar` to link the session to Discord -- the thread URL is copied to your clipboard
5. **Open Discord mobile**: Navigate to the thread to monitor and send messages

## Everyday Workflow

### Starting an OpenCode Session

Press `<C-CR>` to open the AI tool picker:

| Option | Action |
|--------|--------|
| Create new session | Opens the TUI with a fresh session |
| Restore last session | Restores the previously active session (requires the session to have gone idle at least once) |
| Browse all sessions | Opens a picker to select from all available sessions |

If "Restore last session" shows "(none yet)", the session browser opens as a fallback.

### Linking to Discord

Press `<leader>ar` to link the current session:

1. The plugin discovers the TUI's embedded server (port 3000)
2. Queries the TUI's API for sessions
3. Shows a Telescope picker with preview (title, ID, directory, status, age, file changes)
4. Active/busy sessions are tagged `[active]` and sorted first
5. Results are capped at 20 most recent sessions
6. On selection, calls the bot's `POST /link` endpoint
7. The Discord thread URL is copied to your clipboard

### Monitoring from Discord Mobile

Responses appear in the linked thread. For long-running tasks, you will see:

- **Short exchanges** (< 10 seconds): Response text posted directly, no embed
- **Long tasks** (> 10 seconds): Yellow "Processing..." embed appears after the 10-second threshold
  - Updates every ~15 seconds with the latest activity snippet
  - Shows a live "Started X ago" timestamp (auto-updating client-side)
  - Turns green on completion
  - Full response text is posted below the embed

### Sending Instructions from Discord

Type a message in the linked Discord thread. The bot relays it to the OpenCode TUI via `POST /session/{id}/message`. The response flows back through the SSE connection and appears in the thread.

### Bidirectional Relay

Messages typed directly in the OpenCode TUI also appear in the linked Discord thread. The SSE subscriber reconnects automatically if the connection drops.

### Managing Linked Sessions

Press `<leader>as` to open the session management picker:

| Action | Key | Effect |
|--------|-----|--------|
| Kill session | `<CR>` | Aborts and unlinks the session |
| Copy thread URL | `<C-o>` | Copies the Discord thread URL to clipboard |

### Re-linking After Restart

The TUI port is fixed at 3000, so re-linking is usually not needed after a TUI restart. However, if you restart Neovim (which resets plugin state), you must run `<leader>ar` again to re-establish the Discord link.

## Keybinding Reference

| Key | Command | Description |
|-----|---------|-------------|
| `<C-CR>` | AI tool picker | Open the unified AI tool picker (OpenCode / ClaudeCode) |
| `<leader>ar` | `:OpenCodeLinkDiscord` | Discover TUI server, pick a session, link to Discord thread |
| `<leader>as` | `:DiscordSessions` | Browse/manage linked sessions |
| `<CR>` | (in `<leader>as` picker) | Kill selected session |
| `<C-o>` | (in `<leader>as` picker) | Copy thread URL to clipboard |
| `<leader>x` | (in OpenCode TUI) | Export session conversation to `.opencode/output/` |

## Bot HTTP API Reference

The bot exposes a local HTTP API on port 8080.

### Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/link` | POST | Bearer | Link a session to a Discord thread |
| `/sessions` | GET | Bearer | List all linked sessions |
| `/kill` | POST | Bearer | Abort and unlink a session |
| `/health` | GET | None | Health check |

### Example curl Commands

```bash
# Health check (no auth needed)
curl -s http://localhost:8080/health | jq .

# List linked sessions
curl -s -H "Authorization: Bearer $DISCORD_BOT_LINK_TOKEN" \
  http://localhost:8080/sessions | jq .

# Link a session
curl -s -X POST \
  -H "Authorization: Bearer $DISCORD_BOT_LINK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "ses_...", "session_name": "my-project"}' \
  http://localhost:8080/link | jq .

# Kill a session
curl -s -X POST \
  -H "Authorization: Bearer $DISCORD_BOT_LINK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "ses_..."}' \
  http://localhost:8080/kill | jq .
```

## Environment Variables

### User-Set Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DISCORD_BOT_LINK_TOKEN` | (from `/run/secrets/link_api_token`) | Bearer token for bot HTTP API; must exactly match the bot's `link_api_token` secret |
| `DISCORD_BOT_URL` | `http://localhost:8080` | Bot API base URL |
| `OPENCODE_SERVER_PORT` | `3000` | Default port the TUI binds to |
| `OPENCODE_SERVER_URL` | `http://127.0.0.1:4096` | Headless server URL (used for fallback health checks) |

### Bot-Side Variables

These are managed by systemd via `LoadCredential` and are not user-set:

| Variable | Source |
|----------|--------|
| `DISCORD_BOT_TOKEN` | `LoadCredential` |
| `OPENCODE_SERVER_PASSWORD` | `LoadCredential` |
| `DISCORD_CHANNEL_ID` | `LoadCredential` |
| `LINK_API_TOKEN` | `LoadCredential` |
| `OLLAMA_API_KEY` | `LoadCredential` |

## Service Management

### Check Status

```bash
systemctl status discord-bot
systemctl status opencode-serve
```

### Restart Services

```bash
# Restart the bot (required after updating bot source code)
sudo systemctl restart discord-bot

# Restart the headless server
sudo systemctl restart opencode-serve
```

> **Note**: `nixos-rebuild switch` alone does not restart running services. You must explicitly restart `discord-bot.service` after updating bot source code.

### View Logs

```bash
# Follow bot logs
journalctl -fu discord-bot

# Follow server logs
journalctl -fu opencode-serve

# Last 50 lines
journalctl -u discord-bot -n 50
```

## Troubleshooting

### Port 8080 not listening

**Symptom**: `curl` to `http://localhost:8080` fails with "Connection refused"

**Fix**: Restart the bot service:
```bash
sudo systemctl restart discord-bot
```

### No response in Discord after sending a message

**Symptom**: Message appears in Discord but no response comes back

**Fix**:
1. Check `journalctl -u discord-bot` for relay errors
2. Verify the TUI is still running on port 3000: `ss -tlnp | grep 3000`
3. Re-link with `<leader>ar` if the TUI was restarted

### DISCORD_BOT_LINK_TOKEN mismatch error

**Symptom**: Neovim shows "DISCORD_BOT_LINK_TOKEN mismatch -- check env"

**Fix**: The token must exactly match the sops `link_api_token` secret:
```bash
echo $DISCORD_BOT_LINK_TOKEN
cat /run/secrets/link_api_token
```
If they differ, open a new fish terminal (the token is set in interactive shell init) and relaunch Neovim from there.

### DISCORD_BOT_LINK_TOKEN not set

**Symptom**: Neovim shows "DISCORD_BOT_LINK_TOKEN not set -- check env"

**Fix**: Neovim was launched from a shell that did not source fish init. Open a new fish terminal and launch Neovim from there.

### No OpenCode TUI found

**Symptom**: `<leader>ar` shows "No OpenCode TUI found -- open OpenCode first"

**Fix**: The OpenCode TUI is not running. Press `<C-CR>` and create a new session.

### No sessions found in picker

**Symptom**: `<leader>ar` shows "No sessions found -- create one first"

**Fix**: Sessions are not created until you type a message in the TUI. Send at least one message first.

### Session linked but messages fail

**Symptom**: Session was linked but Discord messages are not relayed

**Fix**: The TUI may have been restarted. Re-link with `<leader>ar`. The bot auto-reconnects to the SSE stream, but re-linking ensures the correct port is registered.

### OpenCode returns empty response

**Symptom**: OpenCode responds with empty or generic error

**Fix**:
1. Check that `default_agent` in `opencode.json` references an existing agent
2. Verify the LLM provider API key is configured

### Heartbeat warnings in journalctl

**Symptom**: `journalctl -u discord-bot` shows heartbeat warnings

**Fix**: With the current fully async relay, heartbeat blocking should no longer occur. If you see heartbeat warnings, the bot may be running an outdated version. Restart `discord-bot.service` and verify `opencode_client.py` uses native `aiohttp` (not `urllib.request` in a `ThreadPoolExecutor`).

### Credential files stale after rebuild

**Symptom**: Bot fails after `nixos-rebuild switch`

**Fix**: `nixos-rebuild switch` does not update running service credentials. Restart the bot:
```bash
sudo systemctl restart discord-bot
```

### Responses stop appearing in Discord

**Symptom**: Messages were relaying but suddenly stop

**Fix**:
1. Check `journalctl -u discord-bot` for SSE reconnection logs
2. The TUI may have been restarted (port changed) or the SSE subscriber lost connection
3. Re-link with `<leader>ar` if the port changed

### No progress embed for a long task

**Symptom**: A long-running task shows no yellow "Processing..." embed

**Fix**:
1. Check `journalctl -u discord-bot` for SSE connection errors
2. Verify the TUI is running on port 3000: `ss -tlnp | grep 3000`
3. The SSE subscriber may have failed to connect to the TUI's event stream

### Restore last session shows "(none yet)"

**Symptom**: "Restore last session" shows "(none yet)" and does nothing

**Fix**:
1. Use "Browse all sessions" instead
2. Ensure the session has gone idle at least once after creating it (the session ID is captured from the `session.idle` event)

### OpenCode runs in wrong project directory

**Symptom**: Session exports or state lookups target the wrong directory

**Fix**: OpenCode inherits Neovim's CWD via `snacks.terminal`. Ensure `:pwd` matches your intended project before toggling the TUI. Session exports and state files are written relative to that directory.

### Commands revert after extension reload

**Symptom**: Custom improvements to active commands disappear after reloading extensions

**Fix**:
1. Add protected files to `.syncprotect` at the project root
2. Run `check-command-drift.sh` to detect divergence between active commands and extension source
3. Reloading the core extension via `<leader>al` overwrites active command files with extension source files

## Security Model

- All secrets are managed via sops-nix and injected via systemd `LoadCredential`
- Secrets exist only in RAM (tmpfs at `/run/secrets/` and `/run/credentials/`) -- never on persistent storage in plaintext
- The `link_api_token` is shared between the bot service and Neovim via fish shell init
- TUI instances on localhost do not use authentication
- The headless server on port 4096 uses HTTP Basic Auth with `OPENCODE_SERVER_PASSWORD`

## Related Resources

- [`~/.dotfiles/docs/discord-bot.md`](~/.dotfiles/docs/discord-bot.md) -- NixOS infrastructure setup and service configuration
- `lua/neotex/plugins/ai/opencode.lua` -- OpenCode plugin configuration (port 3000, idempotent start, command registrations)
- `lua/neotex/plugins/ai/opencode/discord-link.lua` -- Session linking (`<leader>ar`)
- `lua/neotex/plugins/ai/opencode/discord-session-picker.lua` -- Session management (`<leader>as`)
- `lua/neotex/plugins/ai/shared/picker/ai-tool-picker.lua` -- AI tool picker (`<C-CR>`, session restore/browse)
- `~/.dotfiles/opencode-discord-bot/` -- Bot source code
- `.opencode/extensions/core/scripts/check-command-drift.sh` -- Detect command drift after extension reloads
