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
    # Set the default AWS profile if not set
    AWS_PROFILE=${AWS_PROFILE:-default}

    # Get the list of AWS profiles from the ~/.aws/credentials file
    profiles=( $(awk -F '[][\n]' '/\[/ {print $2}' ~/.aws/credentials) )

    # If no profiles exist, print an error and exit
    if [[ ${#profiles[@]} -eq 0 ]]; then
        echo -e "\033[0;31mNo AWS profiles found in ~/.aws/credentials file.\033[0m"
        return 1
    fi

    # Show current AWS profile in Cyan
    echo -e "\033[0;36mCurrent AWS Profile is '$AWS_PROFILE'.\033[0m"
    echo -n -e "\033[0;33mDo you want to proceed with this profile? (y/n): \033[0m"
    read choice

    if [[ "$choice" == "y" ]]; then
        echo -e "\033[0;32mProceeding with AWS Profile '$AWS_PROFILE'...\033[0m"
    else
        echo -e "\033[0;33mSelect a new AWS profile:\033[0m"
        # Add "cancel" as an option
        PS3="Please select an option: "
        select new_profile in "${profiles[@]}" "cancel"; do
            case $new_profile in
                cancel)
                    echo -e "\033[0;31mOperation canceled.\033[0m"
                    return 1 ;;  # Cancel the operation
                *)
                    if [[ -n "$new_profile" ]]; then
                        export AWS_PROFILE="$new_profile"
                        echo -e "\033[0;32mNow using AWS Profile '\033[1;36m$AWS_PROFILE\033[0m\033[0;32m'\033[0m"
                        break
                    else
                        echo -e "\033[0;31mInvalid option. Please select a valid profile.\033[0m"
                    fi
                    ;;
            esac
        done
    fi

    # Run terraform with the selected profile (in Blue)
    echo -e "\033[0;34mRunning Terraform with AWS Profile: $AWS_PROFILE\033[0m"
    command terraform "$@"
    echo ""
    echo ""
    echo -e "\033[0;34mRan Terraform with AWS Profile: $AWS_PROFILE\033[0m"
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
