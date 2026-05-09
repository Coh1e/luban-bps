# register-wt-profile.ps1 — append a "PowerShell (luban)" profile entry
# to Windows Terminal's settings.json, pointing at the bp-installed
# portable pwsh.cmd shim.
#
# Designed to be invoked as the `pwsh` tool's [tool.X] post_install hook.
# Skips silently when WT is not installed (settings.json missing) so the
# bp applies cleanly on machines without WT — the only hard requirement
# is pwsh itself, which luban just extracted into the store.
#
# WT defaults (font, theme, color scheme) are NOT touched. The user keeps
# WT's out-of-box look; we only add a profile entry they can pick from
# the dropdown. Override defaultProfile manually if you want luban-pwsh
# as the default — that's a personal preference we don't impose.
#
# Idempotent: re-running updates the existing entry by stable GUID
# instead of stacking duplicates.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Standard WT install path (Microsoft Store). The Preview build lives at
# Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe; we only target stable
# WT here. Users on Preview can copy the snippet to its settings.json.
$wtSettings = Join-Path $env:LOCALAPPDATA `
    'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

if (-not (Test-Path $wtSettings)) {
    Write-Host "Windows Terminal settings.json not found at:"
    Write-Host "  $wtSettings"
    Write-Host "Skipping WT profile registration. Re-apply this bp after"
    Write-Host "installing + first-launching Windows Terminal."
    return
}

# Stable GUID for the "PowerShell (luban)" entry. WT identifies profiles
# by guid, so reusing the same one across applies = update-in-place.
# Generated once via New-Guid and pinned forever in this bp.
$profileGuid = '{4d52b1c0-7b2e-4b0a-9a1f-ebf1ba1ba1ba}'

# Stable absolute path to the luban-managed pwsh shim. The .cmd shim
# auto-redirects to whatever pwsh.exe luban currently owns, so the WT
# entry survives `bp apply --update` style upgrades without rewriting
# this file.
$pwshShim = Join-Path $env:USERPROFILE '.local\bin\pwsh.cmd'

# ---- read + parse ---------------------------------------------------

# WT settings.json allows JSONC (// comments + trailing commas). pwsh
# 7's ConvertFrom-Json doesn't support comments. Strip line comments
# defensively before parsing — block comments are rare in WT output.
$raw = Get-Content -Raw -Path $wtSettings -Encoding UTF8
$stripped = ($raw -replace '(?m)^\s*//[^\r\n]*', '')
try {
    $settings = $stripped | ConvertFrom-Json
} catch {
    Write-Warning "Failed to parse WT settings.json — leaving it alone."
    Write-Warning $_.Exception.Message
    return
}

# ---- ensure profiles.list exists ------------------------------------

# WT's settings.json schema: profiles can be either an array (legacy)
# or an object { defaults: {...}, list: [...] } (current). New installs
# always emit the object form. Defensive: handle both.
if (-not $settings.PSObject.Properties.Match('profiles').Count) {
    $settings | Add-Member -NotePropertyName 'profiles' `
        -NotePropertyValue ([pscustomobject]@{ list = @() })
}
$profilesNode = $settings.profiles

if ($profilesNode -is [System.Array]) {
    # Legacy flat-array form — promote to the object-with-list shape so
    # we have a stable place to land the new entry. WT accepts either.
    $settings.profiles = [pscustomobject]@{
        defaults = [pscustomobject]@{}
        list     = [System.Collections.ArrayList]@($profilesNode)
    }
    $profilesNode = $settings.profiles
} elseif (-not $profilesNode.PSObject.Properties.Match('list').Count) {
    $profilesNode | Add-Member -NotePropertyName 'list' `
        -NotePropertyValue @()
}

# ---- build / replace our entry --------------------------------------

$lubanProfile = [pscustomobject]@{
    guid              = $profileGuid
    name              = 'PowerShell (luban)'
    commandline       = $pwshShim
    icon              = 'ms-appx:///ProfileIcons/{61c54bbd-c2c6-5271-96e7-009a87ff44bf}.png'
    hidden            = $false
    startingDirectory = '%USERPROFILE%'
}

# Coerce list to ArrayList so we can mutate by index. ConvertFrom-Json
# returns Object[] which is fixed-size.
$list = [System.Collections.ArrayList]@($profilesNode.list)

$existingIdx = -1
for ($i = 0; $i -lt $list.Count; $i++) {
    if ($list[$i].guid -eq $profileGuid) { $existingIdx = $i; break }
}
if ($existingIdx -ge 0) {
    $list[$existingIdx] = $lubanProfile
    $action = 'updated'
} else {
    [void]$list.Add($lubanProfile)
    $action = 'added'
}
$profilesNode.list = $list

# ---- atomic write back ----------------------------------------------

$json = $settings | ConvertTo-Json -Depth 32
$tmp = "$wtSettings.luban-tmp"
[System.IO.File]::WriteAllText($tmp, $json, [System.Text.UTF8Encoding]::new($false))
Move-Item -Path $tmp -Destination $wtSettings -Force

Write-Host "WT profile '$($lubanProfile.name)' $action"
Write-Host "  guid:        $profileGuid"
Write-Host "  commandline: $pwshShim"
Write-Host "  font/theme:  (left at WT defaults — not touched)"
