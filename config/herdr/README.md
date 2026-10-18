# Herdr status bar

The top bar shows the selected server's hostname, CPU, and memory every five
seconds. When configured, it also shows Docker context, Kubernetes context and
namespace, and AWS profile and region.

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

The shared Zsh profiles load `status-hook.zsh`. It reports only cloud/context
selectors to the current pane on each prompt; it does not report credentials.
Open a new tab after installing this change, or run this in an existing idle
Zsh pane:

```zsh
source ~/Developer/dotfiles-hd/config/herdr/status-hook.zsh
_dotfiles_herdr_report_environment
```

AWS region, Docker context, and Kubernetes context reads use local configuration,
without logging in or contacting cloud services. Changes to exported selectors
are picked up at the next prompt. Shell-local overrides used for one command
do not change the persistent selection displayed in the bar.

After checking the config, reload the Herdr UI with the existing `Ctrl+B`, then
`r` binding. A narrow terminal can hide Herdr's entire right status area when
there is insufficient room beside the tabs.

TrueNAS uses the same helper and hook in its private Herdr data-pool directory.
Its machine-owned config points to that helper, and its Zsh startup file sources
the hook. Only the status settings are shared; NAS keybindings stay local.

Check the helpers with:

```bash
bash config/herdr/tests/status-test.sh
```
