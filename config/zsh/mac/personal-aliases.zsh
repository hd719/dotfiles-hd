# [Personal Mac Aliases]
# --------------------------------------------------------------------------------------------------------

## Codex
alias cod='codex'
alias coda='carchive'
alias codd='codex doctor'
alias codr='codex resume'
alias codrl='codex resume --last'
alias codrv='codex review --uncommitted'
alias codu='brew upgrade --cask codex'
alias codx='codex exec'

## SSH
alias blaze="ssh hamels-macbook-pro-2"

# OpenClaw
alias opdash='lsof -ti:18789 | xargs kill -9 2>/dev/null; ssh -L 18789:127.0.0.1:18789 hd@100.120.198.12 -f -N && open "http://127.0.0.1:18789/#token=$(op read "op://Development/OpenClaw-Gateway-Token/password")"'

# Monorepo Shell Scripts
# --------------------------------------------------------------------------------------------------------

# HealthMetrics
alias hm-dev='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bun run dev)'
alias hm-build='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bun run build)'
alias hm-prisma-studio='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bunx prisma studio)'
alias hm-prisma-migrate='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bunx prisma migrate dev)'
alias hm-prisma-generate='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bunx prisma generate)'
alias hms-dev='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go run main.go'
alias hms-build='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go build -o healthmetrics main.go'
alias hms-test='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go test ./...'

# Run bun/bunx commands in healthmetrics with 1Password env vars loaded
# Usage: hm-bun run dev | hm-bunx prisma migrate diff ...
hm-bun() {
  (cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bun "$@")
}
hm-bunx() {
  (cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bunx "$@")
}

# Portfolio
alias pf-dev='(cd ~/Developer/nextjs-monorepo/apps/portfolio && bun run dev)'
alias pf-build='(cd ~/Developer/nextjs-monorepo/apps/portfolio && bun run build)'
alias pf-start='(cd ~/Developer/nextjs-monorepo/apps/portfolio && bun run start)'
alias pf-lint='(cd ~/Developer/nextjs-monorepo/apps/portfolio && bun run lint)'
