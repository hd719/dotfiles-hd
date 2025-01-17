{
  description = "Hamel Desai's system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, ... }: {

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;

      nix = {
          # package = pkgs.nix;
          gc.automatic = true;
          optimise.automatic = true;
          settings = {
            auto-optimise-store = true;
            experimental-features = "nix-command flakes";
        };
      };

      environment.systemPackages = with pkgs;
        [
          vim
          fastfetch
          starship
          btop
          diff-so-fancy
          lsd
          zoxide
          bat
          nmap
          devbox
          nix-tree
          tmux
          # awscli2
          # kubectl
          # google-cloud-sdk
        ];

      # I'd rather not have telemetry on my package manager.
      environment.variables.HOMEBREW_NO_ANALYTICS = "1";

      homebrew = {
        enable = true;

        onActivation = {
         cleanup = "zap";
         autoUpdate = true;
         upgrade = true;
        };

        brews = [
          "mas"
          "yakitrak/yakitrak/obsidian-cli"
          "borders"
        ];

        # Update these applicatons manually.
        # As brew would update them by unninstalling and installing the newest
        # version, it could lead to data loss.
        casks = [
          "nikitabobko/tap/aerospace"
          "1password-cli"
          "orbstack"
          "pearcleaner"
          "obsidian"
          # "warp"
          "raycast"
          "karabiner-elements"
          "discord"
          "daisydisk"
          # "studio-3t"
          # "parsec"
          "zoom"
          # "slack"
          "tableplus"
          # "docker"
          # "postman"
          # "visual-studio-code"
          # "amphetamine"
          # "arc"
          "brave-browser"
          "wezterm"
          "jordanbaird-ice"
        ];

        taps = [
          "nikitabobko/tap" # emacs-mac
          "yakitrak/yakitrak"
          "FelixKratz/formulae"
        ];

        masApps = {
          Tailscale = 1475387142; # App Store URL id
          # Magnet = 441258766;
          # Logi Options = 668584891;
          # Microsoft Remote Desktop = 1295203466;
          # Xcode = 497799835;
        };
      };

      system.activationScripts.postUserActivation.text = ''
        # Following line should allow us to avoid a logout/login cycle
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        # Show the ~/Library folder
        chflags nohidden ~/Library
        # Show the /Volumes folder
        sudo chflags nohidden /Volumes
        # Stop iTunes from responding to the keyboard media keys
        launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2>/dev/null
        # Turns off spaces in mission control
        defaults write com.apple.spaces spans-displays -bool false
        # Reduce Motion
        defaults write com.apple.Accessibility reduceMotionEnabled -bool true
      '';

      system.defaults = {
        dock = {
          autohide = true;
          autohide-delay=0.0; # how long does the dock take to hide
          autohide-time-modifier=0.2; # how fast is the dock showing animation
          showhidden = true;
          show-recents = false;
          orientation = "bottom";
        };


        finder = {
          _FXShowPosixPathInTitle = true;
          ShowPathbar = true;
          AppleShowAllExtensions=true;
          FXPreferredViewStyle = "clmv";
          ShowStatusBar = true;
        };

        trackpad = {
          Clicking = true;  # enable tap to click
          TrackpadRightClick = true;  # enable two finger right click
          TrackpadThreeFingerDrag = true;  # enable three finger drag
        };

        # Customize settings that not supported by nix-darwin directly
        # Incomplete list of macOS `defaults` commands :
        # https://github.com/yannbertrand/macos-defaults
        NSGlobalDomain = {
          "com.apple.swipescrolldirection" = false; # enable natural scrolling(default to true)
          "com.apple.sound.beep.feedback" = 0; # disable beep sound when pressing volume up/down key
          AppleInterfaceStyle = "Dark"; # dark mode
          AppleICUForce24HourTime = false;

          # If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
          # This is very useful for vim users, they use `hjkl` to move cursor.
          # sets how long it takes before it starts repeating.
          InitialKeyRepeat = 15;  # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
          # sets how fast it repeats once it starts.
          KeyRepeat = 2;  # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)
        };

        # Customize settings that not supported by nix-darwin directly
        # see the source code of this project to get more undocumented options:
        #    https://github.com/rgcr/m-cli
        #
        # All custom entries can be found by running `defaults read` command.
        # or `defaults read xxx` to read a specific domain.
        CustomUserPreferences = {
          "com.apple.desktopservices" = {
            # Avoid creating .DS_Store files on network or USB volumes
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };

          "com.apple.screensaver" = {
            # Require password immediately after sleep or screen saver begins
            askForPassword = 1;
            askForPasswordDelay = 0;
          };

          "com.apple.finder" = {
            ShowExternalHardDrivesOnDesktop = true;
            ShowHardDrivesOnDesktop = false;
            ShowMountedServersOnDesktop = false;
            ShowRemovableMediaOnDesktop = true;
            # _FXSortFoldersFirst = true;

            # When performing a search, search the current folder by default
            FXDefaultSearchScope = "SCcf";
          };

          "com.apple.WindowManager" = {
            EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
            # StandardHideDesktopIcons = 0; # Show items on desktop
            # HideDesktop = 0; # Do not hide items on desktop & stage manager
            # StageManagerHideWidgets = 0;
            # StandardHideWidgets = 0;
          };

          "com.apple.screencapture" = {
            location = "~/Desktop";
            type = "png";
          };

          "com.apple.AdLib" = {
            allowApplePersonalizedAdvertising = false;
          };

          "com.apple.print.PrintingPrefs" = {
            # Automatically quit printer app once the print jobs complete
            "Quit When Finished" = true;
          };

          # Prevent Photos from opening automatically when devices are plugged in
          "com.apple.ImageCapture".disableHotPlug = true;

          "com.apple.SoftwareUpdate" = {
            AutomaticCheckEnabled = true;
            ScheduleFrequency = 1;
            AutomaticDownload = 1;
            CriticalUpdateInstall = 0;
          };
        };

        loginwindow = {
          GuestEnabled = false;  # disable guest user
          # SHOWFULLNAME = true;  # show full name in login window
        };

        menuExtraClock.Show24Hour = false;
        menuExtraClock.ShowAMPM = true;
        menuExtraClock.ShowDayOfWeek = true;
        menuExtraClock.ShowDate = 1;
      };

      # Add ability to used TouchID for sudo authentication
      security.pam.enableSudoTouchIdAuth = true;

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh = {
        enable = true;
        enableCompletion = true;
      };

      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Hamels-MacBook-Pro
    darwinConfigurations."hameldesai" = nix-darwin.lib.darwinSystem {
      modules = [ configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user="hameldesai";
          };
        }
       ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."hameldesai".pkgs;
  };
}
