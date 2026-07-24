# Zsh Modules

Modules are grouped by who loads them:

```text
zsh/
├── shared/
│   ├── aliases.zsh
│   ├── completions.zsh
│   └── functions.zsh
└── mac/
    ├── aliases.zsh
    ├── development-aliases.zsh
    ├── development-functions.zsh
    ├── init.zsh
    ├── k8s.zsh
    ├── prompt.zsh
    ├── tooling.zsh
    └── personal/
        ├── aliases.zsh
        ├── development-aliases.zsh
        ├── development-functions.zsh
        └── init.zsh
```

- `shared/` is portable and safe for macOS, Ubuntu, and Fedora.
- `mac/aliases.zsh` is safe on every Mac, including the thin control plane.
- `mac/init.zsh` adds the complete Mac development shell.
- `mac/personal/aliases.zsh` contains safe personal host controls.
- `mac/personal/init.zsh` adds personal development workflows.

The thin Mac sources only the shared, safe Mac, safe personal, and VMware
modules. Full personal Macs source both `mac/init.zsh` and
`mac/personal/init.zsh`. Resilience sources only `mac/init.zsh`.

## Decision Record

### 2026-07-24 — Organize shell modules by consumer

- Keep portable behavior in `shared/`.
- Keep reusable macOS behavior in `mac/`.
- Keep Linux profile behavior in `setup/ubuntu/` and `setup/fedora/`.
- Add `config/zsh/linux/` only when multiple Linux profiles share Linux-only
  modules.
- Keep the thin Mac limited to safe host modules; development remains in VMs.
