# luban-bps

[luban](../luban/) blueprint source — personal Win11 stack.

**Officially trusted.** `Coh1e` is on luban's official-owners allowlist
(DESIGN §8), so `bp src add Coh1e/luban-bps` shows a green prompt and
`bp apply` proceeds without the non-official confirmation gate. Apply
still prints a trust summary listing tools, configs, files, and any
`post_install` hooks before each run.

Two blueprints, applied in order:

| bp | what it installs | size |
|---|---|---|
| `bootstrap` | mingit + git-lfs + gcm + llvm-mingw + cmake + ninja + vcpkg | ~700 MB extracted |
| `onboarding` | pwsh 7 + Maple Mono NF CN + starship + zoxide + fd + ripgrep + dotfiles + Windows Terminal theme | ~150 MB extracted |

`onboarding` depends on `bootstrap` (`requires = { "main/bootstrap" }`).
Applying `onboarding` triggers `bootstrap` first if it isn't applied yet.

## What each one does

`bootstrap` — the C++ workshop foundation. Git stack with LFS filters and
GCM HTTPS credential helper, plus the portable Clang/MinGW toolchain
needed to compile anything (cmake + ninja + vcpkg). Replaces the v1.0
split of `foundation` + `cpp-toolchain`; nobody applied one without the
other in practice. `openssh` from the old `foundation` was dropped —
Windows 10 1809+ ships `System32\OpenSSH\ssh.exe`, and HTTPS+GCM covers
the typical workflow.

`onboarding` — open a new terminal and feel at home. PowerShell 7
portable (PSReadLine bundled), Maple Mono NF CN registered per-user
under `HKCU\...\Fonts`, the workbench CLIs (starship/zoxide/fd/rg), and
the dotfiles that wire them together: a pwsh profile, starship theme,
ripgrep config, fd ignore patterns, and a Windows Terminal
`settings.json` patch (RFC 7396 merge — note arrays REPLACE, so a
hand-curated `schemes` list will be clobbered). Replaces the v1.0 split
of `cli-tools` + `fonts` + `onboarding`.

## Layout

```
.
├── source.toml            source metadata (maintainer, luban_min = 1.0.0)
├── blueprints/
│   ├── bootstrap.lua
│   └── onboarding.lua
└── scripts/
    └── register-fonts.ps1 post_install for the maple-mono tool
```

## Use

```pwsh
# github shorthand (most common):
luban bp src add Coh1e/luban-bps
luban bp apply onboarding   # bootstrap auto-applies as a dep

# or local path during dev:
luban bp src add D:\Projects\luban-bps
luban bp apply onboarding

# update later:
luban bp src update luban-bps

# rename if the auto-derived name collides:
luban bp src add Coh1e/luban-bps --name dotfiles
```

Source name auto-derives from the URL — repo basename for github,
directory basename for local. `--name <override>` picks a custom local
nickname.

Requires luban ≥ 1.0.0 (per `source.toml`).

## Inspecting what each apply will do

`bp apply` (with or without `--dry-run`) prints a per-bp trust summary
before any write: tools to fetch with their resolved artifact ids and
`post_install` hooks, configs with the renderer's declared writable
dirs (DESIGN §4 / §7), files with their deploy mode, and `requires`
deps. `--dry-run` runs the same summary and skips every fs / HKCU
write.

```pwsh
luban bp apply main/bootstrap --dry-run    # preview only
luban describe tool:cmake                  # which lock pins it, to what sha256
luban doctor                               # Trust section flags non-official sources + TOFU tool pins
```

`luban describe tool:<name>` walks every reachable `.lock` (this source
+ user-local) and reports each platform's url + sha256, useful when a
tool moves between bps or you need a cross-source dependency view.
`luban doctor` always reports the officiality of every registered
source plus any tool whose lock entry has no sha256 (TOFU pin).
