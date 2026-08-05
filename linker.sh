#!/usr/bin/env bash
# ctrlUserKnown dotfiles symlinker
# date: 08-04-2026
# updated dotfiles linker script


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

for dir in "$PWD"/*/; do
    name="$(basename "$dir")"
    [ "$name" = "home" ] && continue
    target="$HOME/.config/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$backup_dir/"
    fi
    ln -sf "$dir" "$target"
    echo "linking $dir to .config directory"
    sleep 1
done

shopt -s dotglob
for item in "$PWD"/home/*; do
    target="$HOME/$(basename "$item")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$backup_dir/"
    fi
    ln -sf "$item" "$target"
    echo "adding $item into ~/.config"
done

echo "Backups saved to: $backup_dir"
