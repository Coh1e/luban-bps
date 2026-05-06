# luban-bps

[luban](../luban/) blueprint source.

Holds both the **foundation 3** (the universal C++ Windows toolchain layer
previously embedded in the luban binary, retired per DESIGN §9.10 议题 AG)
and personal additions:

| bp | what it installs |
|---|---|
| `foundation` | git + lfs + gcm + openssh — install.ps1 always pre-applies |
| `cpp-toolchain` | llvm-mingw + cmake + ninja + vcpkg (depends on foundation) |
| `cli-tools` | zoxide / starship / fd / ripgrep + ripgreprc + fd ignore + profile.ps1 init |
| `fonts` | Maple Mono (NF CN) — registers under HKCU\Fonts, no UAC |
| `pwsh-modules` | PowerShell modules from PSGallery (PSReadLine + commented examples) — needs luban v0.4.1+ |
| `onboarding` | personal Win11 setup |

## Layout

```
.
├── source.toml           source metadata (maintainer, min luban version)
├── blueprints/           one .lua/.toml per blueprint
│   └── onboarding.lua
└── scripts/              shared post_install scripts (optional)
```

## Use

```pwsh
# github shorthand (most common):
luban bp src add Coh1e/luban-bps
luban bp apply onboarding

# or local path during dev:
luban bp src add D:\Projects\luban-bps
luban bp apply onboarding

# update later:
luban bp src update luban-bps

# rename if the auto-derived name collides:
luban bp src add Coh1e/luban-bps --name dotfiles
```

Source name auto-derives from the URL — repo basename for github,
directory basename for local. `--name <override>` picks a custom
local nickname.
