{ config, pkgs, ... }:

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
    # Create .gitconfig symlink
    ".gitconfig" = {
      source = ../../../../config/git/.gitconfig;
      recursive = false;
    };
    # Create .zshrc symlink
    ".zshrc" = {
      source = ../../../../setup/.zshrc;
      recursive = true;
      force = true;
    };
    # Create global gitignore symlink
    ".gitignore_global" = {
      source = ../../../../config/git/.gitignore_global;
      recursive = false;
    };
    # Create config directory symlinks
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
}
