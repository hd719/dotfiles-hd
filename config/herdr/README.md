# Herdr status bar

The top bar shows the selected server's hostname, CPU, and memory every ten
seconds. Docker context, Kubernetes context and namespace, and AWS profile and
region are displayed separately and refreshed every five seconds.

Nord overrides give the status text a cyan tint and blue separators. The top
bar uses the terminal's transparent background. Herdr 0.9.5 uses one theme color for all status entries; it does not
support a separate color for each metric. These theme colors also apply to
other UI hints and inactive tab labels.

`config.toml` is shared by the MacBook, Mac mini, Air, and work profiles. The
commands read `status.sh` from `~/Developer/dotfiles-hd/config/herdr/`, so the
existing Herdr config link is enough. No new packages or managed links are
needed. AWS and Kubernetes show `not set` when no selection is available;
Docker stays hidden when unavailable. An ellipsis (`…`) means that the pane
has not reported its selections yet: open a new tab or source the hook below.

The shared Zsh profiles load `status-hook.zsh`. It checks selectors and local
config file timestamps at each prompt, without launching another reporter when
nothing changed. It retries after 30 seconds on the next prompt, including after
a failed report. Only cloud/context labels go to the pane; credentials do not.
Open a new tab after installing this change, or run this in an existing idle
Zsh pane:

```zsh
source ~/Developer/dotfiles-hd/config/herdr/status-hook.zsh
_dotfiles_herdr_report_environment
```

AWS region, Docker context, and Kubernetes context reads use local configuration,
without logging in or contacting cloud services. Changes to exported selectors
are picked up at the next prompt. Shell-local overrides used for one command
do not change the persistent selection displayed in the bar. A config change
with identical file size and timestamps can wait until the 30-second recheck.

The agent panel puts agents needing attention first and uses distinct state
symbols. Each row shows the agent and state, followed by its machine, workspace,
and tab. Background completion/input alerts go through Ghostty after two
seconds; Herdr sounds are off. Use `Ctrl+B`, then `o`, to jump to a notification
target. Desktop delivery depends on terminal/OS notification permissions.

New panes cap scrollback at 20 MB, rather than 100 MB. This is an upper limit,
not reserved RAM. Existing panes retain their creation-time limit until they
are recreated. Existing saved pane history remains enabled.

After checking the config, reload the Herdr UI with the existing `Ctrl+B`, then
`r` binding. A narrow terminal can hide Herdr's entire right status area when
there is insufficient room beside the tabs.

TrueNAS uses the same helper and hook in its private Herdr data-pool directory.
Its machine-owned config points to that helper, and its Zsh startup file sources
the hook. Only the status settings are shared; NAS keybindings stay local.

Official agent integrations are machine-owned. Install only for CLIs used
inside Herdr with `herdr integration install codex` or
`herdr integration install hermes`, then check `herdr integration status`.
The local Codex hook is current; the mini uses Codex and the default Hermes
home. Its Hermes hook loads in the next CLI process. It does not require
restarting the shared gateway or make gateway bots into Herdr terminal agents.

Check the helpers with:

```bash
bash config/herdr/tests/status-test.sh
```
