# register-fonts.ps1 — install every .ttf / .otf in cwd as a per-user font.
#
# Designed to be invoked as a luban [tool.X] post_install hook with cwd
# at the extracted artifact root. Picks up all font files (recursively),
# copies them to %LOCALAPPDATA%\Microsoft\Windows\Fonts\, registers each
# in HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts, and broadcasts
# AddFontResourceEx so already-running apps that respond to WM_FONTCHANGE
# (Windows Terminal, VS Code's host) pick them up without a logout.
#
# Per-user scope — no admin / UAC. Win10 1809+ honors HKCU font registration.
# This script is idempotent: re-running on already-installed fonts overwrites
# the file + reasserts the registry entry, which is harmless.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$fontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$regKey   = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

New-Item -ItemType Directory -Path $fontsDir -Force | Out-Null
if (-not (Test-Path $regKey)) {
    New-Item -Path $regKey -Force | Out-Null
}

# AddFontResourceExW makes the new font visible to already-running apps
# without a logout. fl=0 = default scope (system table); HKCU registration
# above gives persistence across reboots. P/Invoke through Add-Type so we
# don't need an external helper exe.
$pinvoke = @'
[DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
public static extern int AddFontResourceExW(string lpszFilename, uint fl, IntPtr pdv);
'@
if (-not ('Win32.Gdi32Fonts' -as [type])) {
    Add-Type -MemberDefinition $pinvoke -Name 'Gdi32Fonts' -Namespace 'Win32' | Out-Null
}

$ttfs = @(Get-ChildItem -Path . -Recurse -Include *.ttf, *.otf -File)
if ($ttfs.Count -eq 0) {
    Write-Host "no .ttf / .otf files found in $(Get-Location) — nothing to register"
    return
}

Write-Host "registering $($ttfs.Count) font file(s) under HKCU (per-user, no UAC)..."

foreach ($ttf in $ttfs) {
    $dest = Join-Path $fontsDir $ttf.Name
    Copy-Item -Path $ttf.FullName -Destination $dest -Force

    # Registry name convention: "<facename> (TrueType)" / "(OpenType)".
    # Windows is forgiving about exact name — face name also works for
    # lookups, and using the file stem is what most installers do.
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($ttf.Name)
    $kind = if ($ttf.Extension -ieq '.otf') { 'OpenType' } else { 'TrueType' }
    $regName = "$stem ($kind)"

    Set-ItemProperty -Path $regKey -Name $regName -Value $dest -Force

    [Win32.Gdi32Fonts]::AddFontResourceExW($dest, 0, [IntPtr]::Zero) | Out-Null
    Write-Host "  $regName"
}

Write-Host "done — $($ttfs.Count) fonts in $fontsDir, registered in HKCU"
