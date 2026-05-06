# luban-bps

Personal [luban](../luban/) blueprint source.

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
