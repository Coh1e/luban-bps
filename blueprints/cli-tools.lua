-- cli-tools: minimal CLI quality of life — zoxide / starship / fd / ripgrep
-- + sensible config defaults.

return {
  schema = 1,
  name = "cli-tools",
  description = "minimal CLI quality of life: zoxide / starship / fd / ripgrep + sensible config defaults",

  tools = {
    zoxide   = { source = "github:ajeetdsouza/zoxide" },
    starship = { source = "github:starship/starship" },
    fd       = { source = "github:sharkdp/fd" },
    ripgrep  = { source = "github:BurntSushi/ripgrep" },
  },

  -- ripgrep + fd ship without any default config; users typically end up
  -- replicating the same handful of flags (smart-case, hidden, common
  -- ignores, color tweaks). Land them as deployable file blocks so a
  -- fresh install gets useful behaviour out of the box. All paths follow
  -- upstream's documented config locations:
  --
  --   ripgreprc:   ~/.config/ripgrep/ripgreprc, picked up via
  --                $env:RIPGREP_CONFIG_PATH (we wire that via the profile.d
  --                append below — the env var is the only mechanism rg
  --                recognises; there's no implicit auto-discovery).
  --
  --   fd ignore:   ~/.config/fd/ignore, AUTO-loaded by fd ≥ 8.6 from
  --                that exact path (XDG-respecting). No env var needed.
  --
  -- Both files are mode = replace — this bp owns them. Users wanting
  -- personal additions can either fork the bp or layer an onboarding bp
  -- with mode = append on the same paths.
  files = {
    ["~/.config/ripgrep/ripgreprc"] = {
      mode = "replace",
      content = [[
# luban cli-tools default ripgreprc — sensible "do what I mean" flags
# for ad-hoc code search. Override per-invocation if you need to.

# Smart case: case-insensitive unless the pattern has uppercase.
--smart-case

# Search hidden files (.config, .vscode, ...) but still respect .gitignore.
--hidden

# Follow symlinks — common in monorepo node_modules / pnpm setups.
--follow

# Cap match line length so a minified single-line bundle doesn't eat
# the terminal.
--max-columns=200
--max-columns-preview

# A few file types upstream doesn't ship by default.
--type-add=cmake:*.{cmake,CMakeLists.txt}
--type-add=just:Justfile
--type-add=docker:{Dockerfile,*.dockerfile,docker-compose*.yml}

# Cosmetic — emphasize line numbers a touch.
--colors=line:fg:yellow
--colors=line:style:bold
--colors=path:fg:green
--colors=match:fg:red
--colors=match:style:bold
]],
    },

    ["~/.config/fd/ignore"] = {
      mode = "replace",
      content = [[
# luban cli-tools default fd ignore — fd auto-loads this file from
# ~/.config/fd/ignore (no env var needed). Pattern syntax is gitignore-
# compatible.

# Big build / package dirs that almost never want to be searched.
node_modules/
.venv/
__pycache__/
target/
dist/
build/
out/

# IDE caches.
.idea/
.vs/
.vscode/    # most users still want to search content of .vscode/settings.json — keep folder out of `fd`'s default but rg will see it via --hidden + .gitignore-respect

# Misc large local stores.
.cache/
.terraform/
.gradle/
]],
    },

    -- Profile snippet wires $RIPGREP_CONFIG_PATH so rg picks up the
    -- ripgreprc above + initializes zoxide / starship. Append (not
    -- replace) so onboarding bp can layer personal aliases / keybinds
    -- on top via additional appends.
    ["~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"] = {
      mode = "append",
      content = [[
# Point ripgrep at its config (rg only reads config when
# RIPGREP_CONFIG_PATH is set; there's no implicit lookup).
$env:RIPGREP_CONFIG_PATH = (Resolve-Path "~/.config/ripgrep/ripgreprc" -ErrorAction SilentlyContinue)?.Path

# zoxide — fuzzy `cd`. Adds `z` and `zi` (interactive picker).
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# starship — pretty prompt. Honors $env:STARSHIP_CONFIG (defaults to
# ~/.config/starship.toml; users layer their own onboarding bp on top).
Invoke-Expression (&starship init powershell)
]],
    },
  },

  meta = {
    requires = {},
    conflicts = {},
  },
}
