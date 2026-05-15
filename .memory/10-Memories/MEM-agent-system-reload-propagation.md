---
title: "Agent system changes propagate via extension loader reload"
created: 2026-05-15
tags: [WORKFLOW]
topic: "agent-system/extension-loader"
source: "user input"
modified: 2026-05-15
retrieval_count: 0
last_retrieved: null
keywords: [extension-loader, reload, leader-al, propagation, agent-system, neovim, child-projects]
summary: "Agent system changes in nvim-config propagate to child projects (ProofChecker etc.) by reloading via <leader>al -- no separate porting tasks needed."
token_count: 78
---

# Agent system changes propagate via extension loader reload

Agent system changes made in nvim-config propagate to ProofChecker (and other child projects) by reloading the agent system via `<leader>al` in Neovim. There is no need to create separate tasks to port `.claude/` changes to other projects -- the extension loader handles synchronization when the user reloads.

## Connections
<!-- Add links to related memories using [[filename]] syntax -->
