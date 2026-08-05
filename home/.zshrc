# zsh runtime configuration
# Author: CrtlUserUnknown

# --- config:locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- config:Homebrew ---
# /opt/homebrew is apple silicon, /usr/local is intel
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# --- config:local bin ---
# ~/.local/bin holds user-installed tools (pip --user, Antigravity CLI, etc.) on both Linux and macOS
export PATH="$HOME/.local/bin:$PATH"

# --- config:editor ---
# both needed — some programs check EDITOR (tty), others check VISUAL (full-screen)
for _e in nvim vim nano; do
    command -v "$_e" >/dev/null 2>&1 && { export EDITOR="$_e" VISUAL="$_e"; break; }
done
unset _e

# --- config:eza ---
export EZA_COLORS="\
da=38;5;246:\
di=38;2;196;167;231:\
ln=38;5;211:\
ex=38;2;86;148;159:\
*.txt=38;5;224:\
*.md=38;5;224:\
*.json=38;5;180:\
*.yml=38;5;180:\
*.yaml=38;5;180"

# LS_COLORS subset is used by zsh completions via zstyle
export LS_COLORS="di=38;2;196;167;231:ln=38;5;211:ex=38;2;86;148;159"

# --- config:fzf ---
# fd respects .gitignore by default & is faster than find
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# alt-enter opens the selected file in $EDITOR without exiting fzf
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --preview "bat --style=numbers --color=always {}"
  --bind "alt-enter:execute($EDITOR {})"
  --color=fg:-1,bg:-1,hl:13
  --color=fg+:-1,bg+:8,hl+:14
  --color=info:12,prompt:10,pointer:13
  --color=marker:11,spinner:13,header:6
  --color=border:8,preview-bg:-1
'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview "bat --color=always --line-range :500 {}"'
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS='--preview "tree -C {} | head -200"'
export FZF_CTRL_R_OPTS='--preview "echo {}" --preview-window down:3:wrap'

# --- config:history ---
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# HISTSIZE is in-memory, SAVEHIST is written to disk — both should match
HISTSIZE=10000
SAVEHIST=10000
# IGNORE_ALL_DUPS deduplicates globally, SHARE_HISTORY syncs across open sessions
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY APPEND_HISTORY INC_APPEND_HISTORY

# --- config:options ---
# removes / so ctrl+w stops at path separators
WORDCHARS=${WORDCHARS//[\/]}
# EXTENDED_GLOB enables ** & ^pattern globs, AUTO_CD lets you enter a dir without typing cd
setopt EXTENDED_GLOB AUTO_CD

# --- config:fastfetch ---
# $$ is the shell pid — runs once per terminal process, not once per subshell
if [[ ! -f /tmp/zsh_fastfetch_$$ ]] && [[ $- == *i* ]]; then
    fastfetch
    touch /tmp/zsh_fastfetch_$$
fi

# --- config:completions ---
if [[ -d "/opt/homebrew/share/zsh-completions" ]]; then
    fpath=(/opt/homebrew/share/zsh-completions $fpath)
elif [[ -d "/usr/share/zsh/site-functions" ]]; then
    fpath=(/usr/share/zsh/site-functions $fpath)
fi

autoload -Uz compinit
zmodload zsh/complist

# only rebuild the completion dump once a day — regenerating on every shell start is slow
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# --- config:zoxide ---
# smarter cd that learns & ranks your most visited directories
eval "$(zoxide init zsh)"

# --- config:carapace ---
# completion engine for many cli tools — cache the generated script since invoking carapace itself is slow
if command -v carapace >/dev/null 2>&1; then
    _carapace_cache="$HOME/.cache/carapace_zsh.sh"
    if [[ ! -f "$_carapace_cache" ]] || [[ -n ${_carapace_cache}(#qN.mh+24) ]]; then
        mkdir -p "${_carapace_cache:h}"
        carapace _carapace > "$_carapace_cache"
    fi
    source "$_carapace_cache"
    unset _carapace_cache
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# --- config:fzf-tab ---
# clone with: git clone https://github.com/Aloxaf/fzf-tab ~/.config/zsh/plugins/fzf-tab
if [[ -f ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
    source ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh

    # disable sort for files/dirs so they appear in natural order
    zstyle ':completion:*' sort false

    # use fd for path completion
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --icons $realpath'
    zstyle ':fzf-tab:complete:-command-:*' fzf-preview 'whence -v $word 2>/dev/null'

    # show what a command name resolves to (alias, function, or binary)
    zstyle ':fzf-tab:complete:*:command-word' fzf-preview 'whence -v $word'

    # show file preview for most completions
    zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers $realpath 2>/dev/null || eza --color=always --icons $realpath'

    # use terminal-native colors so fzf matches the current ghostty theme
    zstyle ':fzf-tab:*' fzf-flags \
        --color=fg:-1,bg:-1,hl:13 \
        --color=fg+:-1,bg+:8,hl+:14 \
        --color=info:12,prompt:10,pointer:13 \
        --color=marker:11,spinner:13,header:6 \
        --color=border:8

    # switch between tab/shift-tab to cycle through results
    zstyle ':fzf-tab:*' switch-group '<' '>'
fi

# --- config:aliases ---
# command bypasses alias lookup — ensures the real binary is called
alias cls="command clear"                        # clear the terminal
alias ls="command eza --color=auto"              # list with color
alias la="command eza -al --icons --color=auto"  # list all with icons
alias lla="command eza -al --icons --color=auto" # same as la — alt name for muscle memory
alias ll="command eza -l --icons --color=auto"   # list with icons
alias reload='source ${ZDOTDIR:-$HOME}/.zshrc'   # reload shell config
alias exi="exit"                                 # exit shell

alias y="yazi"          # file manager
alias py="python3"      # python
alias ipy="ipython3"    # interactive python
alias swiftinit="swift package init"
alias sps="swift package show-dependencies"
alias spt="swift package test"
alias jv="java"
alias jc="javac"
alias rn="rustc"
alias crun="cargo run"

alias lz="lazygit"      # git TUI

alias opc="opencode"    # opencode AI
alias llama="ollama"    # local LLMs
if [[ "$(uname -s)" == "Darwin" ]]; then
    alias antigravity="open -a Antigravity"
    alias anti="open -a Antigravity"
fi

alias mux="herdr"        # multiplexer
alias attach="herdr"     # attach to a session
alias b="command btop"   # system monitor
alias f="fzf"            # fuzzy finder

# suffix aliases — typing file.rs runs $EDITOR file.rs automatically
alias -s md="$EDITOR"
alias -s rs="$EDITOR"
alias -s swift="$EDITOR"
alias -s py="$EDITOR"
alias -s c="$EDITOR"
alias -s cr="$EDITOR"

# --- config:functions ---
function duplicate() {
    if [ $# -eq 0 ]; then
        echo "Usage: duplicate <file_or_folder> [destination_name]"
        return 1
    fi

    local source="$1"
    local destination="$2"

    if [ ! -e "$source" ]; then
        echo "Error: '$source' does not exist"
        return 1
    fi

    if [ -z "$destination" ]; then
        local basename="${source%/}"
        local parent_dir="${basename%/*}"
        local filename="${basename##*/}"

        if [[ "$parent_dir" == "$basename" ]]; then
            parent_dir=""
        else
            parent_dir="${parent_dir}/"
        fi

        if [[ "$filename" =~ ^\.[^.]+$ || "$filename" != *.* ]]; then
            destination="${parent_dir}${filename} copy"
        else
            local extension="${filename##*.}"
            local name="${filename%.*}"
            destination="${parent_dir}${name} copy.${extension}"
        fi
    fi

    cp -R "$source" "$destination"

    if [ $? -eq 0 ]; then
        echo "Duplicated '$source' to '$destination'"
    else
        echo "Error: Failed to duplicate '$source'"
        return 1
    fi
}

# --- config:hooks ---
# auto-run ls when entering these frequently-navigated directories
chpwd() {
    local current_dir="${PWD}"
    if [[ "$current_dir" == "${HOME}/.config" || "$current_dir" == "${HOME}/development" ]]; then
        ls
    fi
}

# --- config:theme ---
source ~/.config/zsh/themes/charModel

# --- config:keybindings ---
autoload -Uz edit-command-line
zle -N edit-command-line
# opens the current command in $EDITOR — alt+e, not ^E, so cmd+right-arrow's
# terminal-emulated "end of line" (^E) keeps its default zsh behavior.
# this overrides emacs' default alt+e (capitalize-word)
bindkey '^[e' edit-command-line
# ctrl+_ is zsh's built-in line-edit undo
bindkey '^_' undo

# --- config:ruby ---
if [[ "$(uname -s)" == "Darwin" && -d "/opt/homebrew/opt/ruby@3.4/bin" ]]; then
    export PATH="/opt/homebrew/opt/ruby@3.4/bin:$PATH"
    # needed to build native gems that link against homebrew ruby instead of system ruby
    export LDFLAGS="-L/opt/homebrew/opt/ruby@3.4/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/ruby@3.4/include"
fi

# --- config:java ---
if [[ "$(uname -s)" == "Darwin" && -d "/opt/homebrew/opt/openjdk@21" ]]; then
    export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
    export PATH="$JAVA_HOME/bin:$PATH"
fi
if [[ -z "$JAVA_HOME" ]] && command -v java &>/dev/null; then
    # macOS's stock readlink doesn't support -f; only follow the symlink if GNU coreutils is present
    if command -v greadlink >/dev/null 2>&1; then
        export JAVA_HOME=$(dirname "$(dirname "$(greadlink -f "$(which java)")")")
    elif [[ "$(uname -s)" != "Darwin" ]]; then
        export JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
    fi
fi

# --- config:plugins ---
# zsh-autosuggestions
if [[ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
# async mode can cause rendering glitches
unset ZSH_AUTOSUGGEST_USE_ASYNC
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
# skip suggestions on long lines for performance
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
# clear the ghost suggestion when tab is pressed
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(expand-or-complete)

# zsh-history-substring-search
if [[ -f "/opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
elif [[ -f "$HOME/.config/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    source "$HOME/.config/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
fi
if (( $+widgets[history-substring-search-up] )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    # application-mode arrows (terminfo kcuu1/kcud1) — sent by many Linux terminals
    bindkey '^[OA' history-substring-search-up
    bindkey '^[OB' history-substring-search-down
fi

# zsh-syntax-highlighting — must be sourced last
# main colors syntax, brackets highlights matched pairs
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=242'
if [[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
