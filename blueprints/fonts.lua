-- fonts: developer fonts — per-user HKCU registration, no UAC.
--
-- Per-user font installation under Windows 10 1809+:
--   1. Files copy to %LOCALAPPDATA%\Microsoft\Windows\Fonts\
--   2. Registry entries land at HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts
--   3. AddFontResourceEx(W) broadcasts WM_FONTCHANGE so already-running apps see them
--
-- All three steps run inside scripts/register-fonts.ps1 (post_install). No admin /
-- UAC needed since everything is per-user. invariant 6 (零 UAC) preserved.
--
-- Why `bp:scripts/register-fonts.ps1` rather than artifact-relative: the
-- Maple Mono GitHub release zip ships only .ttf files, no registration
-- logic. The script lives in this bp source repo and luban resolves it
-- against `bp_source_root` at apply time (luban v0.2.x post_install
-- extension).

return {
  schema = 1,
  name = "fonts",
  description = "developer fonts — per-user HKCU registration, no UAC",

  tools = {
    -- subframe7536/maple-font's GitHub releases publish multiple zip flavors —
    -- CN / NF / NF-CN / unhinted / etc. The luban github resolver's asset
    -- scorer picks one by host triplet match; for fonts which have no platform
    -- axis, it falls back to shortest-match preference. If the wrong zip ends
    -- up picked you can pin via explicit `platform = { ... }` blocks.
    --
    -- `no_shim = true`: this isn't a CLI tool — extracted .ttf files have no
    -- PATH binary to expose. luban skips Step 4 (shim writing) entirely; the
    -- only install action is the post_install hook below.
    --
    -- `bp:` prefix → script path is relative to the bp source root, NOT the
    -- extracted artifact root. The script's cwd at run time IS the artifact
    -- root, so `Get-ChildItem -Recurse *.ttf` finds the upstream font files.
    ["maple-mono"] = {
      source = "github:subframe7536/maple-font",
      no_shim = true,
      post_install = "bp:scripts/register-fonts.ps1",
    },
  },

  meta = {
    requires = {},
    conflicts = {},
  },
}
