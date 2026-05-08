# Research Report: NixOS Discord Bot Prerequisites

**Task**: 550 - nixos_discord_bot_prerequisites
**Started**: 2026-05-08T01:24:00Z
**Completed**: 2026-05-08T01:45:00Z
**Effort**: ~1 hour
**Dependencies**: 547 (research_mobile_agent_management)
**Sources/Inputs**:
- Codebase: `/home/benjamin/.dotfiles/configuration.nix` (existing systemd services, package list)
- Codebase: `/home/benjamin/.dotfiles/flake.nix` (flake inputs, overlays, host configs)
- Codebase: `/home/benjamin/.dotfiles/home.nix` (user systemd service patterns)
- Platform: `nix eval nixpkgs#python312Packages.nextcord.version` → "3.1.1"
- Platform: `nix eval nixpkgs#sops.version` → "3.12.2"
- Platform: `nix eval nixpkgs#age.version` → "1.3.1"
- External: sops-nix GitHub repo (`Mic92/sops-nix`, master branch, actively maintained)
- Reference: specs/547_research_mobile_agent_management/reports/01_mobile-agent-management-research.md
**Artifacts**:
  - specs/550_nixos_discord_bot_prerequisites/reports/01_nixos-discord-bot-prerequisites.md
**Standards**: report-format.md, return-metadata-file.md

## Executive Summary

- **Packages confirmed**: `python312Packages.nextcord` (3.1.1), `sops` (3.12.2), and `age` (1.3.1) are all available in current nixpkgs. No custom overlays or flakes needed for these.
- **sops-nix integration**: Not a nixpkgs package -- must be added as a flake input (`github:Mic92/sops-nix`) and imported as a NixOS module. Requires `.sops.yaml` at repo root with age key configuration.
- **opencode-serve service**: Simple systemd service running `opencode serve` with `OPENCODE_SERVER_PASSWORD` loaded from sops-nix secret. Uses `Type=simple`, `Restart=always`, after `network-online.target`.
- **discord-bot service**: Python service depending on `opencode-serve.service`. Injects Discord bot token via `LoadCredential` from sops-nix secrets. Points to a bot script path that will be created during implementation.
- **All config changes are confined to**: `flake.nix` (sops-nix input + module import), `configuration.nix` (2 systemd services + 3 packages), new `.sops.yaml` file, new `secrets/secrets.yaml` encrypted file.

## Context & Scope

This task configures the NixOS declarative system prerequisites for the Phase 1 Discord bot component of the mobile agent management system. It covers:

1. Installing nixpkgs packages (nextcord, sops, age)
2. Adding sops-nix flake input and NixOS module for secrets management
3. Creating the `opencode-serve` systemd service
4. Creating the `discord-bot` systemd service

Excluded by design: SSH, Mosh, firewall port rules, Raspberry Pi tooling (all deferred to later phases per the 547 research report).

## Findings

### 1. Package Availability (Verified)

All required packages are available directly in nixpkgs:

```bash
nix eval nixpkgs#python312Packages.nextcord.version  # → "3.1.1"
nix eval nixpkgs#sops.version                         # → "3.12.2"
nix eval nixpkgs#age.version                          # → "1.3.1"
```

**Package addition to `configuration.nix`:**

```nix
environment.systemPackages = with pkgs; [
  # ... existing packages ...

  # Discord Bot Prerequisites (Task 550)
  python312Packages.nextcord  # Discord bot library (3.1.1, slash-command-native, async)
  sops                        # Secrets encryption/decryption (3.12.2)
  age                         # Encryption backend for sops (age 1.3.1)
];
```

**Note**: `age` is listed explicitly for transparency. It's also a dependency of sops and typically pulled in transitively, but explicit listing ensures it's in the closure and available for `age-keygen` during key setup.

**Important**: The `nextcord` package in nixpkgs is `python3Packages.nextcord` (aliased from `python312Packages.nextcord`). Use `python312Packages.nextcord` to match the existing python312 convention in `home.nix`.

### 2. sops-nix Secrets Management

sops-nix is a NixOS module (not a standalone nixpkgs package). It must be added as a flake input and imported.

#### 2a. Flake Input Addition (`flake.nix`)

Add to the `inputs` block:

```nix
inputs = {
  # ... existing inputs ...
  sops-nix.url = "github:Mic92/sops-nix";
  sops-nix.inputs.nixpkgs.follows = "nixpkgs";
};
```

Pass through to `outputs` function arguments:

```nix
outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, lean4, niri, lectic, nix-ai-tools, utils, sops-nix, ... }@inputs:
```

#### 2b. Module Import (in each host's `modules` list)

Add `sops-nix.nixosModules.sops` to each `nixosConfigurations` host. For example, for `hamsa`:

```nix
hamsa = lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hosts/hamsa/hardware-configuration.nix
    { networking.hostName = "hamsa"; }
    sops-nix.nixosModules.sops          # ← ADD THIS
    { nixpkgs = nixpkgsConfig; }
    # ... home-manager ...
  ];
};
```

Repeat for `nandi`, `iso`, and `usb-installer` hosts.

#### 2c. `.sops.yaml` (Repository Root)

Create at `/home/benjamin/.dotfiles/.sops.yaml`:

```yaml
keys:
  - &benjamin_age age180d5r...  # Replace with actual age public key

creation_rules:
  - path_regex: secrets/[^/]+\.yaml$
    key_groups:
      - age:
          - *benjamin_age
```

The age public key is generated once with:

```bash
age-keygen -o ~/.config/sops/age/keys.txt
# Outputs: Public key: age1...
```

**Key storage location**: Following the Arch Linux wiki and sops-nix conventions, the age private key should live at `~/.config/sops/age/keys.txt`. This path is used by sops and sops-nix by default. Do NOT store it in the dotfiles repo.

#### 2d. Encrypted Secrets File

Create `secrets/secrets.yaml` (encrypted with sops):

```bash
mkdir -p /home/benjamin/.dotfiles/secrets
sops secrets/secrets.yaml
```

Content (plaintext before encryption):

```yaml
discord-bot-token: "YOUR_DISCORD_BOT_TOKEN_HERE"
opencode-server-password: "YOUR_GENERATED_PASSWORD_HERE"
```

After saving, sops encrypts the file. The encrypted file is committed to git; the plaintext never touches disk unencrypted after initial creation.

#### 2e. sops-nix NixOS Configuration (`configuration.nix`)

```nix
# sops-nix secrets management (Task 550)
sops = {
  defaultSopsFile = ./secrets/secrets.yaml;
  age.sshKeyPaths = [ "/home/benjamin/.config/sops/age/keys.txt" ];

  secrets = {
    "discord_bot_token" = {
      owner = config.users.users.benjamin.name;
    };
    "opencode_server_password" = {
      owner = config.users.users.benjamin.name;
    };
  };
};
```

**Note on key names**: sops-nix converts hyphens in YAML keys to underscores in the secret path. The YAML key `discord-bot-token` becomes the sops secret path `discord_bot_token`. Systemd services reference these via `LoadCredential=discord_bot_token:...` or `EnvironmentFile=`.

### 3. opencode-serve Systemd Service

Following the existing service patterns in `configuration.nix` (e.g., `disable-speaker-amp`, which uses `wantedBy = [ "multi-user.target" ]`):

```nix
systemd.services = {
  # ... existing services ...

  # OpenCode Headless Server (Task 550)
  opencode-serve = {
    description = "OpenCode headless agent server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.opencode}/bin/opencode serve --hostname 127.0.0.1";
      Restart = "always";
      RestartSec = "10s";

      # Inject the server password from sops-nix
      LoadCredential = "opencode_server_password:${config.sops.secrets."opencode_server_password".path}";
      Environment = "OPENCODE_SERVER_PASSWORD=%d/opencode_server_password";
      # Working directory: use the user's dotfiles path so opencode finds its .opencode/ config
      WorkingDirectory = "/home/benjamin/.dotfiles";

      User = config.users.users.benjamin.name;
      Group = "users";
    };
  };
};
```

**Key decisions**:
- `Type = "simple"` rather than "oneshot" because opencode serve is a persistent daemon, not a one-shot task. This matches how the research report's Appendix A describes `opencode serve` as a "Headless server."
- `Restart = "always"` ensures the server comes back if it crashes.
- `RestartSec = "10s"` provides a brief cooldown between restarts.
- `WorkingDirectory = "/home/benjamin/.dotfiles"` so OpenCode finds its `.opencode/` configuration and agent definitions.
- **IMPORTANT**: The `%d` in the Environment value is a systemd specifier for the credential directory. When `LoadCredential` is used with the path from sops-nix, systemd stores the credential at `/run/credentials/opencode-serve.service/opencode_server_password`, and `%d` expands to that directory.
- **Auth model**: OpenCode's built-in basic auth via `OPENCODE_SERVER_PASSWORD` is used (as documented in the 547 research report). The `opencode attach` and `opencode run --attach` commands will need to pass this password.
- Port is **not** specified -- OpenCode picks a random available port. The server's port is discoverable via mDNS or by checking the process output. If a fixed port is desired, add `--port 4096`.

### 4. discord-bot Systemd Service

```nix
systemd.services = {
  # ... existing services ...

  # Discord Bot Relay (Task 550)
  discord-bot = {
    description = "Discord bot relay for OpenCode agent management";
    after = [ "network-online.target" "opencode-serve.service" ];
    wants = [ "network-online.target" ];
    requires = [ "opencode-serve.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      # The bot script path -- will be created during bot implementation
      # For now use a placeholder; the implementation task creates the actual script
      ExecStart = "${pkgs.python312Packages.nextcord}/bin/python -m discord_bot";
      Restart = "always";
      RestartSec = "10s";

      # Inject secrets from sops-nix
      LoadCredential = [
        "discord_bot_token:${config.sops.secrets."discord_bot_token".path}"
        "opencode_server_password:${config.sops.secrets."opencode_server_password".path}"
      ];

      Environment = [
        "DISCORD_BOT_TOKEN=%d/discord_bot_token"
        "OPENCODE_SERVER_PASSWORD=%d/opencode_server_password"
        "OPENCODE_SERVER_URL=http://127.0.0.1"
      ];

      WorkingDirectory = "/home/benjamin/.dotfiles";
      User = config.users.users.benjamin.name;
      Group = "users";
    };
  };
};
```

**Key decisions**:
- `requires = [ "opencode-serve.service" ]` ensures the OpenCode server is running before the bot starts. If opencode-serve crashes, the bot also stops (which is correct -- the bot can't function without the server).
- `LoadCredential` is used for both secrets, following the same pattern as opencode-serve.
- `OPENCODE_SERVER_URL` is set to `http://127.0.0.1` since the server runs locally. The bot script will need to discover the actual port (via mDNS or by examining the server process), or the server should be pinned to a specific port.
- `ExecStart` currently uses a module-based invocation (`-m discord_bot`), but the actual implementation task should replace this with a specific script path (e.g., `${pkgs.writeShellScriptBin "discord-bot" ''...''}`) or a Python file path.

**Recommendation for ExecStart**: The implementation task should use a Nix-packaged script rather than a module import:

```nix
ExecStart = let
  botScript = pkgs.writeShellScriptBin "discord-bot-relay" ''
    exec ${pkgs.python312}/bin/python ${./scripts/discord-bot.py}
  '';
in "${botScript}/bin/discord-bot-relay"
```

Or better, create a proper Nix derivation for the bot:

```nix
discordBotPkg = pkgs.stdenv.mkDerivation {
  name = "discord-bot-relay";
  src = ./scripts/discord-bot.py;
  buildInputs = [ pkgs.python312Packages.nextcord ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/discord-bot.py
    cat > $out/bin/discord-bot <<EOF
    #!/bin/sh
    exec ${pkgs.python312}/bin/python $out/bin/discord-bot.py "\$@"
    EOF
    chmod +x $out/bin/discord-bot
  '';
};
```

Then: `ExecStart = "${discordBotPkg}/bin/discord-bot";`

## Decisions

1. **sops-nix over agenix**: sops-nix is the recommended approach per the 547 research report. agenix is not in nixpkgs and would also require a flake input. sops-nix has broader community adoption and supports age natively.

2. **Service dependencies**: `discord-bot` uses `requires` (hard dependency) on `opencode-serve`, not just `after`. This is correct because the bot is non-functional without the OpenCode server. If the server crashes, systemd restarts both.

3. **Service user**: Both services run as `benjamin` (not root). This is the correct user for accessing `/home/benjamin/.dotfiles/.opencode/` configuration and agent definitions.

4. **Credential-based secrets**: `LoadCredential` is preferred over `EnvironmentFile` because it uses systemd's built-in credential system, stores the secret in a memory-backed tmpfs at `/run/credentials/`, and never exposes it on disk or in `/proc`.

5. **No hardcoded port**: The opencode-serve service does not pin a port. This requires the bot to discover the port dynamically. If this proves unreliable, the implementation task should add `--port 4096` to the ExecStart line and update `OPENCODE_SERVER_URL` accordingly.

6. **Bot ExecStart placeholder**: The current ExecStart is a placeholder. The implementation task that creates the actual bot script must replace it.

## Recommendations

### Implementation (to be done in a follow-up task)

1. **Add sops-nix flake input**: Add to `inputs` block, pass through to `outputs`, import module in each host, run `nix flake lock`.

2. **Generate age key**: Run `age-keygen -o ~/.config/sops/age/keys.txt`, record the public key.

3. **Create `.sops.yaml`**: At repo root with the age public key.

4. **Create encrypted secrets**: `sops secrets/secrets.yaml` with `discord-bot-token` and `opencode-server-password`.

5. **Add packages to `configuration.nix`**: Python312 nextcord, sops, age under `environment.systemPackages`.

6. **Add sops-nix config to `configuration.nix`**: `sops.defaultSopsFile`, `sops.age.sshKeyPaths`, `sops.secrets` blocks.

7. **Add systemd services to `configuration.nix`**: `opencode-serve` and `discord-bot` service definitions.

8. **Replace bot ExecStart placeholder**: Create the actual bot script (Python) and wire it into the service.

9. **Verify build**: Run `nix flake check` and `nixos-rebuild build --flake .#hamsa` before attempting a switch.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| sops-nix module import breaks existing builds | Low | High | Add to all hosts in one pass; `nix flake check` before each host build |
| OpenCode picks random port, bot can't find it | Medium | Medium | Implementation task can add `--port 4096` if mDNS discovery proves unreliable |
| Age key lost after disk failure | Low | High | Back up age private key separately; document recovery procedure |
| Bot references non-existent Python script | High (with placeholder) | Low | Placeholder is expected to fail; implementation task replaces it before merging |

## Appendix

### A. Modified Files Summary

| File | Change Type | What Changes |
|------|-------------|--------------|
| `flake.nix` | New input, module import | Add `sops-nix` input + module import per host |
| `configuration.nix` | Package addition | Add nextcord, sops, age to systemPackages |
| `configuration.nix` | New NixOS config block | Add `sops = { ... }` block |
| `configuration.nix` | New systemd service | Add `opencode-serve` service definition |
| `configuration.nix` | New systemd service | Add `discord-bot` service definition |
| `.sops.yaml` | New file | Age key + creation rules |
| `secrets/secrets.yaml` | New encrypted file | Bot token + server password (encrypted on disk) |

### B. Full `configuration.nix` Additions (Consolidated)

```nix
# ==========================================================================
# Discord Bot Prerequisites (Task 550)
# ==========================================================================
# sops-nix decryption: injects bot token and OpenCode password into
# systemd services via LoadCredential (never on disk unencrypted).
# See: specs/547_research_mobile_agent_management/reports/01_mobile-agent-management-research.md
# See: specs/550_nixos_discord_bot_prerequisites/reports/01_nixos-discord-bot-prerequisites.md
# ==========================================================================

# --- PACKAGES ---
# Add nextcord, sops, age to environment.systemPackages (see Finding 1)

# --- SOPS-NIX ---
# sops-nix secrets management
sops = {
  defaultSopsFile = ./secrets/secrets.yaml;
  age.sshKeyPaths = [ "/home/benjamin/.config/sops/age/keys.txt" ];

  secrets = {
    "discord_bot_token" = {
      owner = config.users.users.benjamin.name;
    };
    "opencode_server_password" = {
      owner = config.users.users.benjamin.name;
    };
  };
};

# --- SERVICES ---
systemd.services = {
  # (existing services remain above)

  opencode-serve = {
    description = "OpenCode headless agent server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.opencode}/bin/opencode serve --hostname 127.0.0.1";
      Restart = "always";
      RestartSec = "10s";
      LoadCredential = "opencode_server_password:${config.sops.secrets."opencode_server_password".path}";
      Environment = "OPENCODE_SERVER_PASSWORD=%d/opencode_server_password";
      WorkingDirectory = "/home/benjamin/.dotfiles";
      User = config.users.users.benjamin.name;
      Group = "users";
    };
  };

  discord-bot = {
    description = "Discord bot relay for OpenCode agent management";
    after = [ "network-online.target" "opencode-serve.service" ];
    wants = [ "network-online.target" ];
    requires = [ "opencode-serve.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python312Packages.nextcord}/bin/python -m discord_bot";  # PLACEHOLDER — replace in implementation
      Restart = "always";
      RestartSec = "10s";
      LoadCredential = [
        "discord_bot_token:${config.sops.secrets."discord_bot_token".path}"
        "opencode_server_password:${config.sops.secrets."opencode_server_password".path}"
      ];
      Environment = [
        "DISCORD_BOT_TOKEN=%d/discord_bot_token"
        "OPENCODE_SERVER_PASSWORD=%d/opencode_server_password"
        "OPENCODE_SERVER_URL=http://127.0.0.1"
      ];
      WorkingDirectory = "/home/benjamin/.dotfiles";
      User = config.users.users.benjamin.name;
      Group = "users";
    };
  };
};
```

### C. sops-nix Flake Input (Consolidated)

```nix
# In inputs {...}:
sops-nix.url = "github:Mic92/sops-nix";
sops-nix.inputs.nixpkgs.follows = "nixpkgs";

# In outputs = { ... sops-nix, ... }@inputs:

# In each host's modules list, BEFORE the nixpkgs config:
sops-nix.nixosModules.sops
```

### D. Step-by-Step Setup Commands (Manual, Run Once)

```bash
# 1. Generate age key (one-time)
age-keygen -o ~/.config/sops/age/keys.txt
# Note the public key (starts with "age1")

# 2. Create .sops.yaml with the public key
# (use template from Finding 2c)

# 3. Create encrypted secrets file
mkdir -p /home/benjamin/.dotfiles/secrets
# Use sops to create the file; it opens $EDITOR:
sops /home/benjamin/.dotfiles/secrets/secrets.yaml
# Content:
# discord-bot-token: "YOUR_ACTUAL_TOKEN"
# opencode-server-password: "A_GENERATED_LONG_RANDOM_STRING"

# 4. Add sops-nix flake input and lock
# (edit flake.nix per Appendix C, then:)
nix flake lock

# 5. Rebuild
nixos-rebuild build --flake .#hamsa
```
