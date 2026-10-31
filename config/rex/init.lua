-- Match config/tmux/tmux.conf: Escape is the prefix, s splits down, v splits right.
-- A one-shot mode lets Escape twice send a real Escape instead of cancelling a sequence.
rex.mode("tmux", { exclusive = true })
rex.bind("escape", "client.mode.enter", { name = "tmux", once = true })
rex.bind("tmux/escape", "pane.send_key", { key = "escape" })

rex.bind("tmux/r", "client.config.reload")
rex.bind("tmux/s", "pane.split", { direction = "down" })
rex.bind("tmux/v", "pane.split", { direction = "right" })

-- Keep the usual tmux window and pane shortcuts behind the same prefix.
rex.bind("tmux/c", "client.tab.new")
rex.bind("tmux/n", "client.tab.next")
rex.bind("tmux/p", "client.tab.previous")
rex.bind("tmux/,", "client.tab.rename")
rex.bind("tmux/shift+4", "session.rename")
for index = 1, 9 do
    rex.bind("tmux/" .. index, "client.tab.goto", { index = index })
end

rex.bind("tmux/left", "pane.focus", { direction = "left" })
rex.bind("tmux/down", "pane.focus", { direction = "down" })
rex.bind("tmux/up", "pane.focus", { direction = "up" })
rex.bind("tmux/right", "pane.focus", { direction = "right" })
rex.bind("tmux/o", "pane.focus_next")
rex.bind("tmux/z", "pane.zoom")
rex.bind("tmux/x", "pane.close")

-- shortcut: Rex has no copy-mode or vim-tmux-navigator action; revisit when supported.
-- Leave Ctrl+h/j/k/l to Neovim rather than stealing its window-navigation keys.
