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
    AWS_PROFILE=${AWS_PROFILE:-default}

    echo "Current AWS Profile is '$AWS_PROFILE'."
    echo -n "Do you want to proceed with this profile? (y/n): "
    read choice

    if [[ "$choice" == "y" ]]; then
        echo "Proceeding with AWS Profile '$AWS_PROFILE'..."
    else
        echo "Select a new AWS profile:"
        select new_profile in "dev" "staging" "cancel"; do
            case $new_profile in
                dev) export AWS_PROFILE="dev"; break;;
                staging) export AWS_PROFILE="staging"; break;;
                cancel) return 1;;
                *) echo "Invalid option.";;
            esac
        done
    fi

    command terraform "$@"
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
