-- Personal Win11 onboarding blueprint.
--
-- Stacks on top of foundation + cpp-toolchain + cli-tools (declared in
-- meta.requires below). Drops in:
--   - Personal PowerShell profile additions (PSReadLine, aliases, fzf
--     helpers) — APPENDED on top of cli-tools' base profile snippet.
--   - Starship prompt theme at ~/.config/starship.toml (REPLACE mode —
--     this bp owns the file).
--
-- Source for both content blobs: docs/ref/profile.ps1 +
-- docs/ref/starship.toml in the luban repo (canonical reference).

return {
  schema = 1,
  name = "onboarding",
  description = "Personal Win11 onboarding — pwsh profile additions + starship theme",

  tools = {},

  files = {
    -- PowerShell profile add-ons. cli-tools.lua already appended the
    -- zoxide / starship init + RIPGREP_CONFIG_PATH; this append stacks
    -- personal taste on top: env vars, PSReadLine config, tiny aliases,
    -- fzf helpers. Encoding to UTF-8 BOM-less so non-ASCII chars in
    -- subsequent commands don't garble.
    ["~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"] = {
      mode = "append",
      content = [==[

# ---------- helpers ----------

function Has-Cmd {
    param([Parameter(Mandatory)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ---------- basic env ----------

$env:EDITOR = "code"
$env:VISUAL = "code"
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"

try {
    [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    $OutputEncoding = [System.Text.UTF8Encoding]::new()
} catch {}

# ---------- PSReadLine ----------

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
]==],
    },

    -- Starship prompt theme. Mode = replace — onboarding owns the file.
    -- Edit docs/ref/starship.toml in the luban repo and re-apply if you
    -- want to retune.
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
  },

  meta = {
    requires = {
      "main/foundation",
      "main/cpp-toolchain",
      "main/cli-tools",
    },
    conflicts = {},
  },
}
