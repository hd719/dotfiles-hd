{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hameldesai";
  home.homeDirectory = "/Users/hameldesai";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [];

  # SSH Configuration
  programs.ssh = {
    enable = false;
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".gitconfig" = {
      source = ../../../../config/git/.gitconfig;
      recursive = false;
    };
    ".zshrc" = {
      source = ../../../../setup/.zshrc;
      recursive = true;
      force = true;
    };
    ".gitignore_global" = {
      source = ../../../../config/git/.gitignore_global;
      recursive = false;
    };
    ".config/bat" = {
      source = ../../../../config/bat;
      recursive = true;
    };
    ".config/btop" = {
      source = ../../../../config/btop;
      recursive = true;
    };
    ".config/fastfetch" = {
      source = ../../../../config/fastfetch;
      recursive = true;
    };
    ".config/wtf" = {
      source = ../../../../config/wtf;
      recursive = true;
    };
    ".config/aerospace" = {
      source = ../../../../config/aerospace;
      recursive = true;
    };
    ".config/karabiner" = {
      source = ../../../../config/karabiner;
      recursive = true;
    };
    ".config/tmux"
  };

  # Configure Git
  programs.git = {
    enable = true;
    # Set up global gitignore
    extraConfig = {
      core = {
        excludesfile = "~/.gitignore_global";
      };
    };
  };

  # You can also manage environment variables
  home.sessionVariables = {
    # EDITOR = "vim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Add wallpaper setup
  home.activation = {
    setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "=== Setting up wallpaper ==="
      WALLPAPER_SOURCE="~/Developer/dotfiles-hd/config/wallpaper/wallpaper.png"
      WALLPAPER_DEST="$HOME/Developer/dotfiles-hd/config/wallpaper/wallpaper.png"

      # Check if source wallpaper exists
      if [ -f "$WALLPAPER_SOURCE" ]; then
        echo "Found wallpaper at source location"
        # Create destination directory if it doesn't exist
        mkdir -p "$(dirname "$WALLPAPER_DEST")"
        # Copy the wallpaper
        echo "Copying wallpaper to destination..."
        cp "$WALLPAPER_SOURCE" "$WALLPAPER_DEST"
        if [ $? -eq 0 ]; then
          echo "Wallpaper copied successfully to $WALLPAPER_DEST"
        else
          echo "Failed to copy wallpaper"
          exit 1
        fi
      else
        echo "Source wallpaper not found at $WALLPAPER_SOURCE"
        # Check if we have a local copy
        if [ -f "$WALLPAPER_DEST" ]; then
          echo "Using existing local wallpaper copy at $WALLPAPER_DEST"
        else
          echo "No wallpaper available at either source or destination"
          exit 1
        fi
      fi

      # Set the wallpaper using absolute path
      echo "Setting wallpaper using AppleScript..."
      WALLPAPER_ABS_PATH=$(realpath "$WALLPAPER_DEST")
      /usr/bin/osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$WALLPAPER_ABS_PATH"'"'
      if [ $? -eq 0 ]; then
        echo "Wallpaper set successfully"
      else
        echo "Failed to set wallpaper"
        exit 1
      fi
      echo "=== Wallpaper setup complete ==="
    '';
  };
}
