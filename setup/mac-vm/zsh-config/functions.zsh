# [Functions]
# --------------------------------------------------------------------------------------------------------

# Lazy loading functions

lazy_kubectl() {
    unset -f kubectl
    source <(command kubectl completion zsh)
    kubectl "$@"
}

terraform() {
    unset -f terraform
    source <(command terraform completion zsh)

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

# docker() {
#     unset -f docker
#     source <(command docker completion zsh)
#     docker "$@"
# }

# docker-compose() {
#     unset -f docker-compose
#     source <(command docker-compose completion zsh)
#     docker-compose "$@"
# }

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
    echo "Cleaning up Nix store..."
    nix-env --delete-generations old
    nix-store --gc
    nix-collect-garbage -d
    nix-store --optimise
    echo "Nix store cleaned and optimized!"

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

scpc() {
    # Display usage information
    echo "  scpc to <local_path> <user@host> <remote_path>    # Copy local to remote"
    echo "  scpc from <user@host> <remote_path> <local_path>  # Copy remote to local"
    echo ""

    echo "Select transfer mode:"
    select mode in "Local to Remote" "Remote to Local"; do
        case "$mode" in
            "Local to Remote")
                read "local_path?Enter local file path: "
                # Optionally, check if file exists
                if [[ ! -e "$local_path" ]]; then
                    echo "Local file '$local_path' not found!"
                    return 1
                fi
                read "remote_host?Enter remote user@host: "
                read "remote_path?Enter remote destination path: "
                scp "$local_path" "$remote_host:$remote_path"
                break
                ;;
            "Remote to Local")
                read "remote_host?Enter remote user@host: "
                read "remote_path?Enter remote file path: "
                read "local_path?Enter local destination path: "
                scp "$remote_host:$remote_path" "$local_path"
                break
                ;;
            *)
                echo "Invalid selection. Try again."
                ;;
        esac
    done
}

daily() {
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

show_ports() {
    # Check if lsof is installed
    if ! command -v lsof &> /dev/null; then
        echo "Error: lsof is not installed. Please install it and try again."
        return 1
    fi

    # Fetch port usage data
    PORTS=$(lsof -i -P -n | awk 'NR>1 {print $9, $1}' | awk -F: '{if (NF>1) print $2, $1}' | sort -n | uniq -c | sort -nr)

    # Check if any ports are in use
    if [[ -z "$PORTS" ]]; then
        echo "No active ports found."
        return 0
    fi

    # Format and display as a chart
    echo "\nActive Ports and Associated Processes:\n"
    echo "Count   Port   Process"
    echo "--------------------------------"
    echo "$PORTS" | column -t
}

delete_zoom_folder() {
  rm -rf "$HOME/Documents/Zoom" &>/dev/null && echo "Deleted: $HOME/Documents/Zoom" || echo "No Zoom directory found at: $HOME/Documents/Zoom"
}

reload() {
  source ~/.zshrc && echo "Zsh configuration reloaded! 🎉"
}

countfiles() {
  find . -type f | wc -l
}

cleanup_dsstore() {
  # sudo find . -name ".DS_Store" -type f -delete 2>/dev/null
  find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null
}

sslcheck() {
  echo | openssl s_client -connect "$1":443 -servername "$1" 2>/dev/null | openssl x509 -noout -dates
}

lan_scan() {
  sudo arp -a
}

correct() {
  setopt correct_all
}

matrix() {
  cmatrix -b
}

flushdns() {
  sudo killall -HUP mDNSResponder 2>/dev/null || sudo systemctl restart systemd-resolved
}

# Add spinner function before internet_speed_test
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local progress=0
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf "\r${spinstr:0:1} Running speed test... %d%%" $progress
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        progress=$(( (progress + 5) % 100 ))
    done
    printf "\r✅ Speed test completed!     \n"
}

version_check_spinner() {
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while true; do
        local temp=${spinstr#?}
        printf "\r${spinstr:0:1} Checking version... %s" "${spinstr:$i:1}"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        i=$(( (i + 1) % ${#spinstr} ))
    done
}

# Rename speedtest to internet_speed_test
internet_speed_test() {
    echo "\n🚀 Running Speed Test...\n"

    local result
    local tool=""

    echo "🔍 Checking available speed test tools..."
    # Detect which speedtest is installed and which version
    if command -v speedtest &>/dev/null; then
        echo "📡 Found speedtest command"
        echo "🔎 Checking if it's Ookla's version..."

        # Start version check spinner in background
        version_check_spinner &
        local spinner_pid=$!

        # Run the version check
        local is_ookla=false
        if speedtest --help 2>&1 | grep -q -- '--format'; then
            is_ookla=true
        fi

        # Kill the spinner
        kill $spinner_pid 2>/dev/null
        printf "\r\033[K"  # Clear the spinner line

        if $is_ookla; then
            tool="ookla"
            echo "✅ Confirmed: This is Ookla's speedtest"
            echo "🌐 Finding best server..."
            # Start the speed test in background
            command speedtest --format=json --progress=no 2>&1 > /tmp/speedtest_result &
            local pid=$!
            # Show spinner while test is running
            spinner $pid
            # Get the result
            result=$(cat /tmp/speedtest_result)
            rm /tmp/speedtest_result
            if ! echo "$result" | jq empty 2>/dev/null; then
                echo "❌ Error: Invalid JSON output from Ookla speedtest"
                echo "Raw output: $result"
                return 1
            fi
        else
            # It's actually speedtest-cli installed as speedtest
            tool="cli"
            echo "✅ Confirmed: This is speedtest-cli (installed as speedtest)"
            echo "🌐 Finding best server..."
            # Start the speed test in background
            command speedtest --json 2>&1 > /tmp/speedtest_result &
            local pid=$!
            # Show spinner while test is running
            spinner $pid
            # Get the result
            result=$(cat /tmp/speedtest_result)
            rm /tmp/speedtest_result
            if ! echo "$result" | jq empty 2>/dev/null; then
                echo "❌ Error: Invalid JSON output from speedtest-cli (as speedtest)"
                echo "Raw output: $result"
                return 1
            fi
        fi
    elif command -v speedtest-cli &>/dev/null; then
        tool="cli"
        echo "✅ Found speedtest-cli"
        echo "🌐 Finding best server..."
        # Start the speed test in background
        command speedtest-cli --json 2>&1 > /tmp/speedtest_result &
        local pid=$!
        # Show spinner while test is running
        spinner $pid
        # Get the result
        result=$(cat /tmp/speedtest_result)
        rm /tmp/speedtest_result
        if ! echo "$result" | jq empty 2>/dev/null; then
            echo "❌ Error: Invalid JSON output from speedtest-cli"
            echo "Raw output: $result"
            return 1
        fi
    else
        echo "❌ No speed test tools found"
        echo "💡 Tip: Install speedtest-cli with 'brew install speedtest-cli' or Ookla's speedtest with 'brew install --cask speedtest'"
        return 1
    fi

    echo "📊 Processing results..."

    # Debug: Print the raw JSON output
    echo "Debug: Raw JSON output:"
    echo "$result" | jq '.'

    if [[ "$tool" == "ookla" ]]; then
        # Ookla JSON fields
        local download=$(echo "$result" | jq -r '.download.bandwidth // 0')
        local upload=$(echo "$result" | jq -r '.upload.bandwidth // 0')
        local latency=$(echo "$result" | jq -r '.ping.latency // 0')
        local server_name=$(echo "$result" | jq -r '.server.name // "Unknown"')
        local server_location=$(echo "$result" | jq -r '.server.location // "Unknown"')
        local isp=$(echo "$result" | jq -r '.isp // "Unknown"')
    else
        # speedtest-cli JSON fields
        local download=$(echo "$result" | jq -r '.download // 0')
        local upload=$(echo "$result" | jq -r '.upload // 0')
        local latency=$(echo "$result" | jq -r '.ping // 0')
        local server_name=$(echo "$result" | jq -r '.server.name // "Unknown"')
        local server_location=$(echo "$result" | jq -r '.server.location // "Unknown"')
        local isp=$(echo "$result" | jq -r '.client.isp // "Unknown"')
    fi

    # Validate numeric values
    if ! [[ "$download" =~ ^[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$upload" =~ ^[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$latency" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "❌ Error: Invalid numeric values in speed test results"
        echo "Download: $download"
        echo "Upload: $upload"
        echo "Latency: $latency"
        return 1
    fi

    # Convert from bytes/sec to various units
    # To Gbps (Gigabits per second - what ISPs advertise)
    local download_gbps=$(printf "%.2f" $(echo "$download * 8 / 1000000000" | bc -l))
    local upload_gbps=$(printf "%.2f" $(echo "$upload * 8 / 1000000000" | bc -l))

    # To Mbps (Megabits per second - common speed unit)
    local download_mbps=$(printf "%.2f" $(echo "$download * 8 / 1000000" | bc -l))
    local upload_mbps=$(printf "%.2f" $(echo "$upload * 8 / 1000000" | bc -l))

    # To GB/s (Gigabytes per second - actual file transfer speeds)
    local download_GBs=$(printf "%.2f" $(echo "$download / 1000000000" | bc -l))
    local upload_GBs=$(printf "%.2f" $(echo "$upload / 1000000000" | bc -l))

    echo "💡 Speed Test Results:"
    echo "📍 Server: $server_name, $server_location"
    echo "🏢 ISP: $isp"
    echo "🏓 Latency: ${latency}ms\n"

    echo "⬇️  Download Speed:"
    echo "   $download_gbps Gbps (ISP advertised speed unit)"
    echo "   $download_mbps Mbps"
    echo "   $download_GBs GB/s (actual file transfer speed)"

    # Calculate percentage of advertised 1Gbps
    local download_percentage=$(printf "%.1f" $(echo "min($download_gbps / 1 * 100, 100)" | bc -l))
    echo "   📊 You're getting $download_percentage% of advertised 1 Gbps speed"

    # Download speed analysis
    if (( $(echo "$download_gbps >= 1" | bc -l) )); then
        echo "   ✅ Excellent - Exceeding advertised speed"
    elif (( $(echo "$download_gbps >= 0.9" | bc -l) )); then
        echo "   ✅ Excellent - Near maximum advertised speed"
    elif (( $(echo "$download_gbps >= 0.7" | bc -l) )); then
        echo "   👍 Very Good - Above 70% of advertised speed"
    elif (( $(echo "$download_gbps >= 0.5" | bc -l) )); then
        echo "   👌 Good - Above 50% of advertised speed"
    else
        echo "   ⚠️  Below Expected - Less than 50% of advertised speed"
        echo "   💡 Tip: Try running test with ethernet cable or closer to router"
    fi
    echo ""

    echo "⬆️  Upload Speed:"
    echo "   $upload_gbps Gbps (ISP advertised speed unit)"
    echo "   $upload_mbps Mbps"
    echo "   $upload_GBs GB/s (actual file transfer speed)"

    # Calculate percentage of advertised upload (assuming symmetric 1Gbps)
    local upload_percentage=$(printf "%.1f" $(echo "min($upload_gbps / 1 * 100, 100)" | bc -l))
    echo "   📊 You're getting $upload_percentage% of advertised 1 Gbps speed"

    # Upload speed analysis
    if (( $(echo "$upload_gbps >= 1" | bc -l) )); then
        echo "   ✅ Excellent - Exceeding advertised speed"
    elif (( $(echo "$upload_gbps >= 0.9" | bc -l) )); then
        echo "   ✅ Excellent - Near maximum advertised speed"
    elif (( $(echo "$upload_gbps >= 0.7" | bc -l) )); then
        echo "   👍 Very Good - Above 70% of advertised speed"
    elif (( $(echo "$upload_gbps >= 0.5" | bc -l) )); then
        echo "   👌 Good - Above 50% of advertised speed"
    else
        echo "   ⚠️  Below Expected - Less than 50% of advertised speed"
        echo "   💡 Tip: Try running test with ethernet cable or closer to router"
    fi
    echo "\n💻 Real-world Examples (with current speed):"
    echo "• 4K Netflix Movie (15GB): $(printf "%.1f" $(echo "15 / $download_GBs / 60" | bc -l)) minutes to download"
    echo "• iPhone Backup (50GB): $(printf "%.1f" $(echo "50 / $upload_GBs / 60" | bc -l)) minutes to upload"
    echo "• PS5 Game (100GB): $(printf "%.1f" $(echo "100 / $download_GBs / 60" | bc -l)) minutes to download"
    echo "\n🕒 Test completed at $(date '+%Y-%m-%d %H:%M:%S')\n"
}

ytplay() {
  mpv "https://www.youtube.com/watch?v=$1"
}

md2pdf() {
  pandoc "$1" -o "${1%.md}.pdf"
}

largest_dirs() {
  du -ah . | sort -rh | head -n 10
}

open_ports() {
  sudo lsof -i -P -n | grep LISTEN
}

check_ports() {
  local suspicious_ports=("22" "3283" "5900" "5000" "7000" "63743")
  local open_ports=$(netstat -an | grep LISTEN | awk '{print $4}' | awk -F. '{print $NF}' | sort -u)
  local found=()

  for port in "${suspicious_ports[@]}"; do
    if echo "$open_ports" | grep -q "^$port$"; then
      found+=("$port")
    fi
  done

  if [[ ${#found[@]} -eq 0 ]]; then
    echo "✅ No suspicious ports open."
  else
    echo "⚠️  Suspicious ports open: ${found[*]}"
  fi
}

# Full generation map with size
nix-gen-map() {
  echo "🔗 Generation -> Nix Store Path + Size:"
  printf "%-12s %-70s %10s\n" "Generation" "Store Path" "Size"
  echo "-----------------------------------------------------------------------------------------------"
  sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | while read gen rest; do
    link="/nix/var/nix/profiles/system-${gen}-link"
    if [[ -L "$link" ]]; then
      target=$(readlink "$link")
      if [[ -n "$target" && -e "$target" ]]; then
        size=$(du -sh "$target" | awk '{print $1}')
        printf "%-12s %-70s %10s\n" "$gen" "$target" "$size"
      fi
    fi
  done
}

nix-gen-size() {
  for link in /nix/var/nix/profiles/system-*-link; do
    target=$(readlink "$link")
    if [[ -n "$target" && -e "$target" ]]; then
      du -sh "$target"
    fi
  done
}

goodMorning() {
  echo ""
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
  echo ""
  echo "Updating Homebrew..."
  brew update && brew upgrade
  echo ""
  echo "Cleaning up Homebrew..."
  brew cleanup && brew autoremove;
  echo ""
  echo "Cleaning up Zoom folder..."
  delete_zoom_folder
  echo ""
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
}
