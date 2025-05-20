{
  description = "Hamel Desai's system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
  let
    configuration = { pkgs, ... }: {

      nix = {
          enable = false; # Turn off Nix darwins management of Nix installation as we use Nix Determinate
          package = pkgs.nix;
          # gc.automatic = true; -> This requires enable to be true (but we are using Nix Determinate)
          # optimise.automatic = true; -> This requires enable to be true (but we are using Nix Determinate)
          settings = {
            experimental-features = "nix-command flakes";

            # Performance optimizations
            max-jobs = "auto"; # Utilize all available CPU cores
            cores = 0; # Let Nix determine the optimal number of cores
            sandbox = true; # Enable sandboxing for better security and reproducibility
            trusted-users = ["root" "hameldesai"]; # Allow your user to use Nix
            substituters = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];
          };
      };

      nixpkgs.config = {
        allowUnfree = true;
      };

      # Add SSH key management
      system.activationScripts.createSSHKey.text = ''
        USER_HOME="/Users/hameldesai"
        SSH_KEY="$USER_HOME/.ssh/id_ed25519"

        if [ ! -f "$SSH_KEY" ]; then
          echo "Creating new SSH key at $SSH_KEY"
          mkdir -p "$USER_HOME/.ssh"
          chmod 700 "$USER_HOME/.ssh"
          ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "hameldesai@$(hostname)"
          chown -R hameldesai:staff "$USER_HOME/.ssh"
        else
          echo "SSH key already exists at $SSH_KEY"
        fi
      '';



      # Add GPG key management
      system.activationScripts.gpgKeySetup = {
        text = ''
          # Create .gnupg directory if it doesn't exist
          mkdir -p ~/.gnupg
          chmod 700 ~/.gnupg

          # Generate GPG key only if it doesn't exist
          if [ ! -f ~/.gnupg/pubring.kbx ]; then
            echo "Generating new GPG key..."
            cat > /tmp/gpg-key-script <<EOF
              Key-Type: ED25519
              Key-Length: 256
              Subkey-Type: ED25519
              Subkey-Length: 256
              Name-Real: Hamel Desai
              Name-Email: your-email@example.com
              Expire-Date: 0
              %no-protection
              %commit
            EOF
            ${pkgs.gnupg}/bin/gpg --batch --gen-key /tmp/gpg-key-script
            rm /tmp/gpg-key-script
            echo "GPG key generated successfully!"
          else
            echo "GPG key already exists, skipping generation."
          fi

          # Get the key ID
          KEY_ID=$(${pkgs.gnupg}/bin/gpg --list-secret-keys --keyid-format LONG | grep "sec" | head -n 1 | awk '{print $2}' | cut -d'/' -f2)
          if [ -n "$KEY_ID" ]; then
            echo "Using GPG key ID: $KEY_ID"
            # Export the key ID to a temporary file
            echo "$KEY_ID" > /tmp/gpg-key-id

            # Export public key to desktop
            ${pkgs.gnupg}/bin/gpg --armor --export "$KEY_ID" > ~/Desktop/gpg-public-key.asc
            echo "Public key exported to ~/Desktop/gpg-public-key.asc"

            # Export private key to desktop (with warning)
            echo "WARNING: Private key is being exported to desktop. Keep it secure!"
            ${pkgs.gnupg}/bin/gpg --armor --export-secret-keys "$KEY_ID" > ~/Desktop/gpg-private-key.asc
            echo "Private key exported to ~/Desktop/gpg-private-key.asc"
          else
            echo "Warning: Could not determine GPG key ID"
          fi
        '';
        deps = [];
      };

      environment.systemPackages = with pkgs;
        [
          awscli2
          kubectl
          bat
          btop
          # devbox
          diff-so-fancy
          fastfetch
          ffmpeg
          ghostscript
          imagemagick
          jq
          lsd
          nix-tree
          nmap
          rbenv
          redis
          starship
          speedtest-cli
          terraform
          tmux
          vim
          vips
          zoxide
          zsh-completions
          zsh-fast-syntax-highlighting
          zstd
          go
          pnpm
        ];

      # Environment variables for development tools
      environment.variables = {
        # Go environment variables
        GOPATH = "$HOME/go";
        GOBIN = "$HOME/go/bin";
        PATH = "$HOME/go/bin:$PATH";

        # PNPM configuration
        PNPM_HOME = "$HOME/pnpm";
      };

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
          "anycable-go"
          "ffmpeg"
          "imagemagick"
          "llvm@14"
          "ruby-build"
          "ruby-lsp"
          "uv"
          "vips"
          "zsh-autosuggestions"
          "zsh-syntax-highlighting"
          "zsh-you-should-use"
          # "postgresql@15" -> Run through docker
          # "postgresql@17" -> Run through docker
          # "redis" -> Run through docker
          # "pgvector" -> Docker image has this already installed
        ];

        casks = [
          "1password"
          "1password-cli"
          "aerospace"
          "bartender"
          "brave-browser"
          "chatgpt"
          "cursor"
          "daisydisk"
          "deskflow"
          "discord"
          "figma"
          "istat-menus"
          "iterm2"
          "karabiner-elements"
          "little-snitch"
          "logi-options+"
          "micro-snitch"
          "microsoft-edge"
          "obsidian"
          "obsidian"
          "pearcleaner"
          "pycharm-ce"
          "raycast"
          "slack"
          "tableplus"
          "tableplus"
          "visual-studio-code"
          "zoom"
        ];

        taps = [
          # "mongodb/brew" -> Run through docker
          "nikitabobko/tap"
          "heroku/brew"
          "deskflow/homebrew-tap"
        ];

        masApps = {};
      };

      # NOTE: Important nix-darwin Activation Changes
      # Changelog: https://github.com/nix-darwin/nix-darwin/commit/b9e580c1130307c3aee715956a11824c0d8cdc5e#diff-ecec88c33adb7591ee6aa88e29b62ad52ef443611cba5e0f0ecac9b5725afdba
      # Github Issue: https://github.com/nix-darwin/nix-darwin/issues/1455
      # ============================================
      # As of recent nix-darwin updates, all activation scripts now run as root instead of the user level.
      # This is a significant architectural change made to:
      # 1. Improve multi-user support
      # 2. Provide more consistent system-wide configuration
      # 3. Better align with macOS's security model
      #
      # Current Workarounds:
      # - Use 'sudo -u username' for user-specific commands (current approach)
      # - Set system.primaryUser (as done above) for user-specific settings
      #
      # Future Migration Options:
      # 1. Move user-specific configurations to Home Manager
      # 2. Wait for nix-darwin to move more settings under users.users.* namespace
      # 3. Use Home Manager's activation scripts for user-level changes
      #
      # Reference: https://github.com/nix-darwin/nix-darwin/issues/

      # System activation scripts that run as root for the time being
      # TODO: Move to home-manager activation script
      system.activationScripts.extraActivation.text = ''
        # Following line should allow us to avoid a logout/login cycle
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

        # Show the ~/Library folder
        sudo -u hameldesai chflags nohidden /Users/hameldesai/Library

        # Show the /Volumes folder
        chflags nohidden /Volumes

        # Stop iTunes from responding to the keyboard media keys
        sudo -u hameldesai launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2>/dev/null

        # Turns off spaces in mission control
        sudo -u hameldesai defaults write com.apple.spaces spans-displays -bool false

        # Reduce Motion
        sudo -u hameldesai defaults write com.apple.Accessibility reduceMotionEnabled -bool false

        # Install Rosetta if not already installed
        if ! /usr/bin/pgrep -q oahd; then
          echo "Installing Rosetta..."
          /usr/sbin/softwareupdate --install-rosetta --agree-to-license
        else
          echo "Rosetta is already installed"
        fi
      '';

      system.defaults = {
        dock = {
          autohide = true;
          autohide-delay = 0.0;
          autohide-time-modifier = 0.2;
          showhidden = true;
          show-recents = false;
          orientation = "bottom";

          # Newer macOS features
          tilesize = 48; # Set icon size
          magnification = true; # Enable magnification
          largesize = 64; # Set magnification size
          minimize-to-application = false; # Minimize windows into application icon
          # Set persistent apps
          persistent-apps = [
            "/Applications/Brave Browser.app"
            "/Applications/Obsidian.app"
            "/Applications/Cursor.app"
            "/Applications/iTerm.app"
          ];
        };

        finder = {
          _FXShowPosixPathInTitle = false;
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          CreateDesktop = false; # Don't create .DS_Store files
          FXDefaultSearchScope = "SCcf"; # Search the current folder by default
          FXEnableExtensionChangeWarning = false; # Disable extension change warning
          FXPreferredViewStyle = "Nlsv"; # List view
          FXRemoveOldTrashItems = true; # Remove old trash items
          QuitMenuItem = true; # Enable quit menu item
          ShowPathbar = true;
          ShowStatusBar = true;
        };

        trackpad = {
          Clicking = true;
          TrackpadRightClick = true;
          TrackpadThreeFingerDrag = true;

          # Newer macOS features
          Dragging = true; # Enable dragging
          # FirstClickThreshold = 1; # Light click threshold
          # SecondClickThreshold = 1; # Force click threshold
        };

        # Customize settings that not supported by nix-darwin directly
        # Incomplete list of ma cOS `defaults` commands :
        # https://github.com/yannbertrand/macos-defaults

        # https://mynixos.com/options/system.defaults.NSGlobalDomain
        NSGlobalDomain = {
          "com.apple.mouse.tapBehavior" = 1; # enables tap to click
          "com.apple.trackpad.enableSecondaryClick" = true; # enables right click on trackpad
          "com.apple.trackpad.forceClick" = true; # enables force click on trackpad
          "com.apple.swipescrolldirection" = false; # enable natural scrolling(default to true)
          "com.apple.sound.beep.feedback" = 0; # disable beep sound when pressing volume up/down key
          # AppleInterfaceStyle = "dark"; # dark mode or light mode
          AppleInterfaceStyleSwitchesAutomatically = true;
          AppleICUForce24HourTime = false;
          AppleMeasurementUnits = "Inches";
          AppleMetricUnits = 0;
          AppleTemperatureUnit = "Fahrenheit";
          AppleShowAllExtensions = true; # show all file extensions
          AppleShowScrollBars = "WhenScrolling";

          # If you press and hold certain keyboard keys when in a text area, the key's character begins to repeat.
          # This is very useful for vim users, they use `hjkl` to move cursor.
          # sets how long it takes before it starts repeating.
          InitialKeyRepeat = 15;  # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
          # sets how fast it repeats once it starts.
          KeyRepeat = 2;  # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)

          AppleShowAllFiles = true;  # show hidden files in Finder

          NSScrollAnimationEnabled = true; # enable scroll animation
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
            # askForPassword = 1;
            # askForPasswordDelay = 0;
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
          # GuestEnabled = false;
         #  SHOWFULLNAME = true;
          # Newer macOS features
          # AdminHostInfo = "HostName"; # Show hostname in login window -> Deprecated
          # PowerOffDisabled = false; # Allow power off -> Deprecated
          #RestartDisabled = false; # Allow restart
          #ShutDownDisabled = false; # Allow shutdown
        };

        menuExtraClock.Show24Hour = false;
        menuExtraClock.ShowAMPM = true;
        menuExtraClock.ShowDayOfWeek = true;
        menuExtraClock.ShowDate = 1;
      };

      # Add ability to used TouchID for sudo authentication
      security.pam.services.sudo_local.touchIdAuth = true; # Now supported sudo TouchID authentication

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh = {
        enable = true;
        enableCompletion = true;
	      enableBashCompletion = true;
        enableSyntaxHighlighting = true;
        enableFzfCompletion = true;
      };

      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Set the primary user for user-specific configurations
      system.primaryUser = "hameldesai";
    };
  in
  {
    # Build darwin flake using:
    # darwin-rebuild build --flake .#Hamels-MacBook-Pro
    darwinConfigurations."hameldesai" = nix-darwin.lib.darwinSystem {
      modules = [ configuration
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user="hameldesai";
          };
        }
        {
          # Home Directory Configuration
          # ===========================
          # This configuration resolves a common conflict between nix-darwin and home-manager.
          # Both systems need to know where your home directory is located, and without proper
          # configuration, they can conflict with each other.
          #
          # The solution:
          # 1. Set the home directory in the system configuration using mkDefault
          # 2. Also set it in home.nix for home-manager
          #
          # About mkDefault:
          # ----------------
          # mkDefault is a function from nixpkgs.lib that helps manage configuration priorities.
          # It marks a value as a default value, allowing other modules to override it if needed.
          #
          # Nix's priority system for configuration values:
          # - mkDefault (lowest priority) - Suggested default value
          # - Direct assignments (medium priority) - Regular value
          # - mkForce (highest priority) - Forced value
          #
          # Why use mkDefault?
          # - Flexibility: Allows other modules to override the value if needed
          # - Clarity: Makes it explicit that this is a default value
          # - Maintainability: Makes configuration hierarchy clear
          # - Safety: Prevents accidental overrides of important values
          #
          # When to use mkDefault:
          # - When providing sensible default values
          # - When allowing other modules to override the value
          # - When setting configuration that might need customization
          # - When avoiding conflicts between different parts of the system
          #
          # If you get an error like:
          # "A definition for option `home-manager.users.<username>.home.homeDirectory' is not of type `absolute path'"
          # This is the configuration you need to add.
          users.users.hameldesai.home = nixpkgs.lib.mkDefault "/Users/hameldesai";
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.hameldesai = import ./home.nix;
            backupFileExtension = "backup";
          };
        }
       ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."hameldesai".pkgs;
  };
}
