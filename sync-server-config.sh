#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/CtrlUserKnown/dotfiles-ctrluserknown.git"
repo_dir="${DOTFILES_DIR:-$HOME/dotfiles}"

if [ -d "$repo_dir/.git" ]; then
    git -C "$repo_dir" pull --ff-only
else
    if [ -e "$repo_dir" ]; then
        printf 'Error: %s exists but is not a git checkout. Set DOTFILES_DIR to another path.\n' "$repo_dir" >&2
        exit 1
    fi
    git clone --branch main -- "$repo_url" "$repo_dir"
fi

bash "$repo_dir/linker.sh"
printf '\nConfig files are linked from %s. Restart or reload services that cache their config.\n' "$repo_dir"
