# Installing Fonts on Ubuntu

## Quick Method (User fonts only)

Fonts installed in `~/.local/share/fonts/` are available for your user only.

### Steps:

1. **Create fonts directory** (if it doesn't exist):
   ```bash
   mkdir -p ~/.local/share/fonts
   ```

2. **Copy your font files** (`.ttf`, `.otf`, etc.) to the fonts directory:
   ```bash
   cp /path/to/your/font.ttf ~/.local/share/fonts/
   ```

3. **Refresh the font cache**:
   ```bash
   fc-cache -fv
   ```

4. **Verify the font is installed**:
   ```bash
   fc-list | grep "YourFontName"
   ```

## Installing Nerd Fonts

Nerd Fonts are patched fonts with tons of icons and glyphs. Great for terminal use.

### Example: Install Hasklug (Hasklig) Nerd Font

```bash
# Download and install Hasklug Nerd Font
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hasklig.zip -O /tmp/Hasklig.zip
unzip /tmp/Hasklig.zip -d ~/.local/share/fonts/Hasklig
rm /tmp/Hasklig.zip
fc-cache -fv
```

### Other Popular Nerd Fonts

Replace `Hasklig` with any of these:
- `FiraCode` - Fira Code
- `JetBrainsMono` - JetBrains Mono
- `Meslo` - Meslo LG
- `RobotoMono` - Roboto Mono
- `UbuntuMono` - Ubuntu Mono
- `CascadiaCode` - Cascadia Code

Full list: https://github.com/ryanoasis/nerd-fonts/releases/latest

## System-wide Installation (All users)

If you want fonts available for all users:

1. **Copy fonts to system directory**:
   ```bash
   sudo cp /path/to/your/font.ttf /usr/local/share/fonts/
   ```

2. **Refresh the font cache**:
   ```bash
   sudo fc-cache -fv
   ```

## Troubleshooting

- **Font not showing up?** Make sure you refreshed the cache with `fc-cache -fv`
- **Wrong font in terminal?** Restart your terminal application
- **Still not working?** Check the exact font name with `fc-list | grep -i "partial-font-name"`
