# Ops Fallback Modules

`../ops-fallback.sh` is the public entrypoint. It defines shared configuration,
loads these modules in dependency order, and routes the three supported
commands. No module should run work while it is being sourced.

```text
ops-fallback.sh
└── ops-fallback/
    ├── lib/
    │   ├── transport.sh       command capture and SSH routing
    │   ├── results.sh         result rows, verdicts, and Markdown tables
    │   └── dates.sh           BSD-date and ISO-8601 helpers
    ├── commands/
    │   ├── personal-ready.sh  thin Mac, Ubuntu VM, and Mac mini updates
    │   ├── home-lab-ready.sh  read-only readiness orchestration
    │   └── home-lab-recover.sh approved recovery branches
    └── checks/
        ├── runtime.sh         Cortana, PostgreSQL, Hermes, and queues
        ├── infrastructure.sh  Tailscale, TrueNAS, and Home Assistant
        └── providers.sh       secondary provider readiness
```

## Reading Order

1. Read `../ops-fallback.sh` to find the command.
2. Open the matching file under `commands/`.
3. Follow only the check or helper functions called by that command.

## Boundaries

- `personal-ready` owns the thin Mac, Ubuntu VM, and guarded Mac mini
  `goodMorning --updates-only` lane. It selects one SSH route before mutation
  and never retries a failed update through another route.
- `home-lab-ready` is inspection only.
- `home-lab-recover` contains only the documented unattended recovery branches.
- Command exit status matches the report: personal blockers and core home-lab
  failures return nonzero; notes and secondary-service warnings stay nonblocking.
- Full scheduled maintenance remains in the separately deployed
  `home-lab-maintenance` skill. It is not copied into this fallback.
- Fallback-owned logic is Bash plus `curl` and `jq`. External systems may still
  own Python executables; for example, the Google Workspace check calls its
  existing Hermes helper instead of duplicating it here.
