#!/usr/bin/env bash
set -euo pipefail

# Resolve the repository from this script so it works from any directory.
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# check for if the ~/.config directory is present on the system.
# if it is not then make it
echo "checking for ~/.config directory"
sleep 1
if [ -d "$HOME/.config/" ]; then
    echo "exists"
else
    echo "not exists"
    sleep 1
    echo "Making ~/.config directory"
    mkdir -p "$HOME/.config"
    sleep 1
fi

backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"

linux_only=" ghostty-linux "

for dir in "$repo_dir"/*/; do
    name="$(basename "$dir")"

    # Skip repository metadata and directories that are not ~/.config entries.
    case "$name" in
        .git|.claude|home) continue ;;
    esac

    # skip linux configs if not on linux
    if [ "$(uname -s)" != "Linux" ] && [[ "$linux_only" == *" $name "* ]]; then
        echo "Skipping $name (Linux Only)"
        continue
    fi

    # skip home as it will be place somewhere else
    [ "$name" = "home" ] && continue
    target="$HOME/.config/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$backup_dir/"
    fi

    # linking universal configs
    # -n so an existing symlink is replaced rather than followed, which would
    # otherwise nest the link inside the directory it already points at
    ln -sfn "$dir" "$target"
    echo "linking $dir to .config directory"
    sleep 1
done

shopt -s dotglob
for item in "$repo_dir"/home/*; do
    [ -e "$item" ] || continue
    target="$HOME/$(basename "$item")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$backup_dir/"
    fi
    ln -sf "$item" "$target"
    echo "adding $item into ~/.config"
done

echo "Backups saved to: $backup_dir"
