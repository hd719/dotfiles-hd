# Lesson 5 Go Practice

This harmless local module exists for Neovim LSP practice. Break it, undo it,
and restore it freely.

## Lesson 5 targets

- `:checkhealth vim.lsp`: run Neovim's language-server diagnostics. Seeing
  `gopls` confirms that Go intelligence is attached to `main.go`.
- `gh`: hover over `New`, `Greeter`, `Greet`, or `Goodbye`.
- `gd`: jump from `greeting.New` in `main.go` to its definition.
- `grr`: find every reference to `Greet`; close its list with `Space c q`.
- `Space S`: search workspace symbols such as `Greeter` or `Goodbye`.
- Completion: type `greeter.` in `main.go` and choose a method.

Run the module with `go run .` and verify it with `go test ./...`.

Before editing, confirm the current filename in the status line or with
`:echo expand('%:t')`. `Space w` saves the current buffer exactly as written; it
does not generate or repair code.
