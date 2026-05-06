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

Local-path mode (no GitHub push needed):

```pwsh
luban bp source add personal "file:///D:/Projects/luban-bps"
luban bp apply personal/onboarding
```

Remote mode (after `git push` to a GitHub repo):

```pwsh
luban bp source add personal https://github.com/Coh1e/luban-bps
luban bp source update personal
luban bp apply personal/onboarding
```
