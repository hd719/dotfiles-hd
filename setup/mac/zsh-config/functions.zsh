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


goodMorning() {
    switch
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
