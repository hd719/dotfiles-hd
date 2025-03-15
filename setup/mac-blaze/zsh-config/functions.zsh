# [Functions]
# --------------------------------------------------------------------------------------------------------

killport() {
    if [[ $# -ne 1 ]]; then
        echo "Add a port number to kill the process on that port. Example: killport 3000"
        return 1
    fi

    local port="$1"
    local pid=$(lsof -ti tcp:"$port")

    if [[ -z $pid ]]; then
        echo "No process found on port $port"
        return 1
    else
        echo "Killing process on port $port"
        echo "$pid" | xargs kill -9
    fi
}

clean() {
    # echo "Cleaning up Nix store..."
    # nix-env --delete-generations old
    # nix-store --gc
    # nix-collect-garbage -d
    # nix-store --optimise
    # echo "Nix store cleaned and optimized!"

    echo "Cleaning up Homebrew..."
    brew cleanup
    brew autoremove
    brew doctor
    echo "Homebrew cleaned!"

    echo "Cleaning up npm..."
    pnpm cache clean --force
    pnpm store prune

    echo "Cleaning up Docker..."
    docker system prune -a
}

hex_to_decimal_ip() {
  local hex_ip="$1"

  # Check if a hexadecimal IP is provided
  if [ -z "$hex_ip" ]; then
    echo "Usage: hex_to_decimal_ip <HEX_IP>"
    return 1
  fi

  # Remove '0x' prefix if present
  hex_ip="${hex_ip#0x}"

  # Split the hexadecimal IP into four 2-character segments
  local seg1="${hex_ip:0:2}"
  local seg2="${hex_ip:2:2}"
  local seg3="${hex_ip:4:2}"
  local seg4="${hex_ip:6:2}"

  # Convert each segment from hexadecimal to decimal
  local decimal_seg1=$((16#$seg1))
  local decimal_seg2=$((16#$seg2))
  local decimal_seg3=$((16#$seg3))
  local decimal_seg4=$((16#$seg4))

  # Create the decimal IP address by joining the segments with dots
  local decimal_ip="$decimal_seg1.$decimal_seg2.$decimal_seg3.$decimal_seg4"

  echo "$decimal_ip"
}

network_info() {
  local interface="$1"

  # Check if the interface name is provided
  if [ -z "$interface" ]; then
    echo "Usage: parse_network_info <INTERFACE_NAME>"
    return 1
  fi

  # Use ifconfig to retrieve network information
  local ifconfig_output
  ifconfig_output=$(ifconfig "$interface" 2>/dev/null)

  # Check if the interface exists and is active
  if [ -z "$ifconfig_output" ]; then
    echo "Interface '$interface' not found or not active."
    return 1
  fi

  # Parse and display IPv4 address, netmask, and default gateway
  local ipv4_address
  ipv4_address=$(echo "$ifconfig_output" | grep -oE 'inet (addr:)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}')

  local netmask
  netmask=$(echo "$ifconfig_output" | grep -o 'netmask 0x[0-9a-f]*' | awk '{print $2}' | cut -c3- | awk '{gsub(/^0[xX]/,""); print}')

  local default_gateway
  default_gateway=$(route -n get default | grep 'gateway:' | awk '{print $2}')

  # Display the parsed network information
  echo "Interface...............: $interface"
  echo "IPv4 Address............: $ipv4_address"
  echo "Subnet Mask.............: $(hex_to_decimal_ip $netmask)"
  echo "Default Gateway.........: $default_gateway"
}

terraform() {
    # Get the current AWS profile from the environment variable
    AWS_PROFILE=${AWS_PROFILE:-default}

    # Prompt the user to either proceed with the current profile or switch to a new one
    echo "Current AWS Profile is '$AWS_PROFILE'."
    echo -n "Do you want to proceed with this profile? (y/n): "
    read choice

    if [[ "$choice" == "y" ]]; then
        echo "Proceeding with AWS Profile '$AWS_PROFILE'..."
    else
        echo "Please select a new AWS profile to switch to:"
        select new_profile in "dev" "staging" "cancel"; do
            case $new_profile in
                dev)
                    export AWS_PROFILE="dev"
                    echo "AWS Profile is now set to 'dev'."
                    break
                    ;;
                staging)
                    export AWS_PROFILE="staging"
                    echo "AWS Profile is now set to 'staging'."
                    break
                    ;;
                cancel)
                    echo "Profile change canceled. Exiting..."
                    return 1
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
            esac
        done
    fi

    # Call the original terraform command with all arguments passed to this function
    command terraform "$@"
}

# Pull all repos on master branch
gda() {
  startdir=$(pwd);

	echo '******Pulling Almanac Editor  ******';
	cdalmanac && git checkout master && gpp;

	echo '******Pulling Blaze on Rails ******';
	cdblazeonrails && git checkout master && gpp;

	echo '******Pulling Monospace ******';
	cdmonospace && git checkout master && gpp;

	echo '******Pulling Prosecore ******';
	cdprosecore && git checkout master && gpp;

  cd "$startdir";
}

goodMorning() {
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
  brew update && brew upgrade
	gda
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
}


# alias for new obsidian daily note
function daily {
    TODAY=$(date "+%Y-%m-%d")
    NOTE_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/HD/Daily notes/${TODAY}.md"
    [ -f "$NOTE_PATH" ] || touch "$NOTE_PATH"

    COMMAND="$1"
    shift

    if [ "$COMMAND" = "add" ] || [ "$COMMAND" = "todo" ]; then
        TIME=$(date "+%H:%M")
        # Extract the last timestamp, if present
        LAST_TIME=$(grep '####' "$NOTE_PATH" | tail -1 | awk '{print $2}')

        if [ "$LAST_TIME" != "$TIME" ]; then
            [ -s "$NOTE_PATH" ] && echo "" >> "$NOTE_PATH"
            echo "#### $TIME" >> "$NOTE_PATH"
        fi

        ENTRY_TEXT="$*"
        if [ "$COMMAND" = "todo" ]; then
            echo "- [ ] $ENTRY_TEXT" >> "$NOTE_PATH"
        else
            echo "- $ENTRY_TEXT" >> "$NOTE_PATH"
        fi
    else
        code "$NOTE_PATH"
    fi
}

alias daily=daily
