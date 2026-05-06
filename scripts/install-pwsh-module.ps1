# install-pwsh-module.ps1 — copy a PowerShell module from the luban store
# into the user's PSModulePath, where pwsh auto-discovers it.
#
# Generic across modules: the .nupkg gets extracted by luban's archive::extract
# into the artifact root (cwd at script-time). This script:
#   1. Locates the module manifest (the single .psd1 at the artifact root).
#   2. Reads ModuleName + ModuleVersion from it.
#   3. Copies all module files (everything EXCEPT NuGet metadata) into
#      `~/Documents/PowerShell/Modules/<Name>/<Version>/`.
#
# Per-user scope, no UAC. PowerShell 7+ default $PSModulePath includes that
# directory and auto-loads modules at session start. PowerShell 5.x users
# need to substitute `Documents/WindowsPowerShell/Modules` instead — most
# luban users are on pwsh 7 so we hard-code the modern path. If you need
# both, fork this script in your own bp source.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# 1. Find the manifest. NuGet packs typically have exactly one .psd1 at the
#    archive root; >1 is unusual and ambiguous, 0 means it's not actually
#    a PowerShell module package.
$manifests = @(Get-ChildItem -Path . -Filter *.psd1 -File)
if ($manifests.Count -ne 1) {
    throw "install-pwsh-module: expected exactly 1 .psd1 at artifact root, found $($manifests.Count). " +
          "If you're calling this on a non-PowerShell-module package the .nupkg likely has the manifest in a subdirectory."
}
$manifestPath = $manifests[0].FullName
$moduleName = [System.IO.Path]::GetFileNameWithoutExtension($manifests[0].Name)

# 2. Read ModuleVersion from the manifest. Import-PowerShellDataFile is the
#    safe, sandboxed way to read a .psd1 — it parses the data section
#    without executing arbitrary script blocks.
$data = Import-PowerShellDataFile $manifestPath
if (-not $data.ModuleVersion) {
    throw "install-pwsh-module: $moduleName.psd1 has no ModuleVersion field"
}
$moduleVer = $data.ModuleVersion

# 3. Copy. Wipe destination first to avoid stale files from a previous
#    install of the same name+version.
$psModulesRoot = Join-Path $env:USERPROFILE 'Documents/PowerShell/Modules'
$dest = Join-Path $psModulesRoot "$moduleName/$moduleVer"
if (Test-Path $dest) {
    Remove-Item -Path $dest -Recurse -Force
}
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# Skip NuGet packaging metadata that pwsh doesn't need / shouldn't see.
$skip = @('_rels', 'package', '[Content_Types].xml')
Get-ChildItem -Path . -Force | Where-Object {
    -not ($skip -contains $_.Name) -and ($_.Extension -ne '.nuspec')
} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
}

Write-Host "  $moduleName $moduleVer -> $dest"
Write-Host "  (loads automatically in new pwsh sessions via `$PSModulePath)"
