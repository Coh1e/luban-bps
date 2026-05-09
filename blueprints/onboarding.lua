-- onboarding: personal Win11 shell + workbench layer.
--
-- Replaces the v1.0 split of cli-tools (4 CLIs + minimal profile) +
-- fonts (font registration) + onboarding (personal pwsh customization).
-- One bp now covers the whole "open a new terminal and feel at home"
-- experience.
--
-- Install footprint:
--   pwsh                    PowerShell 7 portable (~100 MiB extracted).
--                           Bundles PSReadLine; no separate module install.
--   maple-mono              Maple Mono NF CN font, registered per-user
--                           under HKCU\...\Fonts via post_install script.
--   starship + zoxide + fd  Workbench CLIs; small portable .exe each.
--   + ripgrep
--
-- Files dropped:
--   ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
--                           pwsh profile — PSReadLine config, basic env,
--                           tiny aliases, fzf helpers, init for zoxide
--                           and starship + RIPGREP_CONFIG_PATH wiring.
--                           mode = replace; this bp owns the file.
--   ~/.config/starship.toml          starship prompt theme.
--   ~/.config/ripgrep/ripgreprc      sane ripgrep defaults.
--   ~/.config/fd/ignore              sane fd ignore patterns.
--
-- Windows Terminal:
--   The pwsh tool's post_install runs scripts/register-wt-profile.ps1,
--   which appends a "PowerShell (luban)" profile entry to WT's
--   settings.json so users can pick the bp-installed pwsh from the
--   dropdown. The script SKIPS silently when WT isn't installed
--   (settings.json absent). WT defaults — font, theme, color scheme —
--   are NOT touched; users keep WT's out-of-box look.
--
--   Caveat: post_install runs only on fresh extraction. If you install
--   WT after applying this bp, the profile entry won't appear until
--   the next pwsh upgrade re-extracts. Force a re-run with
--   `luban bp apply main/onboarding --update` after a pwsh release
--   bump, or run scripts/register-wt-profile.ps1 manually.
--
-- PSReadLine is NOT installed as a separate tool — pwsh 7 ships with
-- it bundled at $PSHome/Modules/PSReadLine. The profile just configures
-- it (Set-PSReadLineOption / -KeyHandler).

return {
  schema = 1,
  name = "onboarding",
  description = "Personal Win11 shell: pwsh + Maple Mono + starship/zoxide/fd/rg (+ WT pwsh profile if WT installed)",

  tools = {
    -- PowerShell 7 portable. github.com/PowerShell/PowerShell ships
    -- PowerShell-X.Y.Z-win-x64.zip — the resolver picks the win-x64
    -- asset by host triplet match. pwsh.exe at the archive root.
    --
    -- Bundles PSReadLine + PowerShellGet + Microsoft.PowerShell.Archive
    -- in $PSHome\Modules; the profile just configures them.
    pwsh = {
      source = "github:PowerShell/PowerShell",
      bin = "pwsh.exe",
      -- After extraction, register a "PowerShell (luban)" profile in
      -- Windows Terminal so users can pick the bp-installed pwsh from
      -- the dropdown. The script no-ops when WT isn't installed; WT's
      -- default font / theme / colorScheme are left untouched.
      -- `bp:` prefix resolves the path against the bp source root,
      -- not the extracted artifact (DESIGN §9.9 post_install).
      post_install = "bp:scripts/register-wt-profile.ps1",
    },

    starship = { source = "github:starship/starship" },
    zoxide   = { source = "github:ajeetdsouza/zoxide" },
    fd       = { source = "github:sharkdp/fd" },
    ripgrep  = { source = "github:BurntSushi/ripgrep" },

    -- Maple Mono NF CN font. The GitHub release zip contains only
    -- .ttf files; the registration logic (HKCU font path + AddFontResourceEx
    -- broadcast) lives in scripts/register-fonts.ps1 next to this bp.
    -- `bp:` prefix resolves the script path against the bp source root,
    -- not the extracted artifact root (per DESIGN §9.9 post_install).
    --
    -- no_shim = true: .ttf files have no PATH binary to expose;
    -- post_install does all the work.
    ["maple-mono"] = {
      source = "github:subframe7536/maple-font",
      no_shim = true,
      post_install = "bp:scripts/register-fonts.ps1",
    },
  },

  files = {
    -- ripgrep config: smart-case, hidden, follow, extra type aliases.
    -- mode = replace because cli-tools (the v1.0 ancestor of this bp)
    -- owned this path too; subsequent applies overwrite cleanly.
    ["~/.config/ripgrep/ripgreprc"] = {
      mode = "replace",
      content = [[
# luban onboarding default ripgreprc. Override per-invocation if you
# need to.

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

    -- fd auto-loads this from ~/.config/fd/ignore (no env var needed).
    -- Pattern syntax is gitignore-compatible.
    ["~/.config/fd/ignore"] = {
      mode = "replace",
      content = [[
# luban onboarding default fd ignore — auto-loaded from
# ~/.config/fd/ignore. Pattern syntax is gitignore-compatible.

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
.vscode/

# Misc large local stores.
.cache/
.terraform/
.gradle/
]],
    },

    -- Starship prompt theme. Ayu-ish color choices; minimal, fast.
    ["~/.config/starship.toml"] = {
      mode = "replace",
      content = [[
add_newline = false
command_timeout = 1000

format = """
$directory\
$git_branch\
$git_status\
$c\
$cmake\
$rust\
$nodejs\
$python\
$cmd_duration\
$line_break\
$character"""

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"

[git_branch]
symbol = " "
format = "[$symbol$branch]($style) "
style = "bold purple"

[git_status]
format = "([$all_status$ahead_behind]($style) )"
style = "yellow"

[c]
symbol = " "
format = "[$symbol($version )]($style)"
style = "blue"

[cmake]
symbol = "△ "
format = "[$symbol($version )]($style)"
style = "blue"

[rust]
symbol = " "
format = "[$symbol($version )]($style)"
style = "red"

[nodejs]
symbol = " "
format = "[$symbol($version )]($style)"
style = "green"

[python]
symbol = " "
format = "[$symbol($version )]($style)"
style = "yellow"

[cmd_duration]
min_time = 500
format = "took [$duration]($style) "
style = "dimmed white"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
]],
    },

    -- pwsh profile. mode = replace; this bp owns the user's
    -- Microsoft.PowerShell_profile.ps1. PSReadLine config + tiny
    -- aliases + fzf helpers + zoxide / starship init + RIPGREP env wire.
    ["~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"] = {
      mode = "replace",
      content = [==[
# =========================================================
# luban onboarding pwsh profile
# Drives PSReadLine + zoxide + starship + ripgrep config wire-up.
# =========================================================

# ---------- helpers ----------

function Has-Cmd {
    param([Parameter(Mandatory)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ---------- basic env ----------

$env:EDITOR = "code"
$env:VISUAL = "code"
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"

# Point ripgrep at its config (rg only reads config when
# RIPGREP_CONFIG_PATH is set; there's no implicit lookup).
$rgrc = Resolve-Path "~/.config/ripgrep/ripgreprc" -ErrorAction SilentlyContinue
if ($rgrc) { $env:RIPGREP_CONFIG_PATH = $rgrc.Path }

try {
    [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    $OutputEncoding = [System.Text.UTF8Encoding]::new()
} catch {}

# ---------- PSReadLine (bundled with pwsh 7) ----------

try {
    Import-Module PSReadLine -ErrorAction Stop

    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView

    Set-PSReadLineKeyHandler -Key Tab    -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
    Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    Set-PSReadLineKeyHandler -Key Ctrl+f -Function ForwardWord
    Set-PSReadLineKeyHandler -Key Ctrl+b -Function BackwardWord
    Set-PSReadLineKeyHandler -Key Ctrl+l -Function ClearScreen
} catch {
    Write-Warning "PSReadLine not available or failed to configure."
}

# ---------- tiny aliases ----------

function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }

function reload {
    . $PROFILE.CurrentUserAllHosts
}

function prof {
    if (Has-Cmd code) {
        code $PROFILE.CurrentUserAllHosts
    } else {
        notepad $PROFILE.CurrentUserAllHosts
    }
}

# ---------- fzf: installed but mostly passive ----------

if (Has-Cmd fzf) {
    $env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"

    function fcd {
        $dir = Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName |
            fzf

        if ($dir) {
            Set-Location $dir
        }
    }

    function fh {
        Get-Content (Get-PSReadLineOption).HistorySavePath |
            fzf |
            Set-Clipboard
    }
}

# ---------- zoxide ----------

if (Has-Cmd zoxide) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ---------- starship prompt ----------

if (Has-Cmd starship) {
    Invoke-Expression (&starship init powershell)
}
]==],
    },

    -- Windows Terminal: handled by the pwsh tool's post_install
    -- (scripts/register-wt-profile.ps1) — appends a "PowerShell (luban)"
    -- profile to WT settings.json only when WT is installed. WT defaults
    -- (font / theme / schemes) are intentionally not touched.
  },

  meta = {
    requires = { "main/bootstrap" },
    conflicts = {},
  },
}
