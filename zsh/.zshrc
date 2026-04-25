# ============================================================================
# ~/.zshrc
# ============================================================================

# ----------------------------------------------------------------------------
# Powerlevel10k instant prompt — MUST stay near the top of .zshrc.
# Initialization code that may require console input (password prompts,
# [y/n] confirmations, etc.) must go ABOVE this block; everything else
# goes below.
# ----------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----------------------------------------------------------------------------
# zinit — plugin manager, self-installs on first run
# ----------------------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ----------------------------------------------------------------------------
# History
# ----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # timestamps in history
setopt HIST_EXPIRE_DUPS_FIRST    # trim dupes first when trimming
setopt HIST_IGNORE_DUPS          # no consecutive dupes
setopt HIST_IGNORE_ALL_DUPS      # drop older dupes entirely
setopt HIST_IGNORE_SPACE         # don't record lines starting with space
setopt HIST_FIND_NO_DUPS         # no dupes in search
setopt HIST_SAVE_NO_DUPS         # no dupes in history file
setopt HIST_VERIFY               # expand !! but wait for enter
setopt SHARE_HISTORY             # share history across sessions in real time

# ----------------------------------------------------------------------------
# Behavior
# ----------------------------------------------------------------------------
setopt AUTO_CD                   # `cd` optional if argument is a directory
setopt AUTO_PUSHD                # cd pushes to dir stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt CORRECT                   # offer typo fixes for commands
setopt INTERACTIVE_COMMENTS      # allow # comments in interactive shell
setopt NO_BEEP
setopt EXTENDED_GLOB             # nicer glob syntax (^, ~, etc.)

# ----------------------------------------------------------------------------
# Key bindings — emacs-style (matches bash default)
# ----------------------------------------------------------------------------
bindkey -e

# Home / End / Delete — bind every common terminal escape variant so they work
# under TERM=xterm-256color (bare kitty), TERM=tmux-256color (in tmux), and
# typical SSH remotes. terminfo-based binds catch anything else.
bindkey '^[[H'   beginning-of-line     # xterm       Home
bindkey '^[[F'   end-of-line           # xterm       End
bindkey '^[[1~'  beginning-of-line     # tmux/rxvt   Home
bindkey '^[[4~'  end-of-line           # tmux/rxvt   End
bindkey '^[[7~'  beginning-of-line     # urxvt/linux Home
bindkey '^[[8~'  end-of-line           # urxvt/linux End
bindkey '^[OH'   beginning-of-line     # application mode Home
bindkey '^[OF'   end-of-line           # application mode End

# terminfo-driven fallback (authoritative for the current TERM)
typeset -g -A _hm_key
_hm_key[Home]=${terminfo[khome]}
_hm_key[End]=${terminfo[kend]}
_hm_key[Delete]=${terminfo[kdch1]}
[[ -n ${_hm_key[Home]}   ]] && bindkey "${_hm_key[Home]}"   beginning-of-line
[[ -n ${_hm_key[End]}    ]] && bindkey "${_hm_key[End]}"    end-of-line
[[ -n ${_hm_key[Delete]} ]] && bindkey "${_hm_key[Delete]}" delete-char

# Keep the cursor-key state sane across readline / vim / editors.
# When the terminal enters "application cursor keys" mode, sequences flip from
# ^[[X to ^[OX; the -s/-e hooks below make sure zsh handles both.
autoload -Uz add-zle-hook-widget
function _hm_zle_init { echoti smkx 2>/dev/null }
function _hm_zle_finish { echoti rmkx 2>/dev/null }
add-zle-hook-widget -Uz line-init     _hm_zle_init
add-zle-hook-widget -Uz line-finish   _hm_zle_finish

bindkey '^[[3~'    delete-char           # Delete
bindkey '^[[1;5C'  forward-word          # Ctrl+Right
bindkey '^[[1;5D'  backward-word         # Ctrl+Left

# ----------------------------------------------------------------------------
# Completion system
# ----------------------------------------------------------------------------
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''

# ----------------------------------------------------------------------------
# Plugins (zinit)
# Load order matters: fzf-tab BEFORE fast-syntax-highlighting,
# fast-syntax-highlighting LAST.
# ----------------------------------------------------------------------------

# Powerlevel10k prompt
zinit ice depth=1
zinit light romkatv/powerlevel10k

# fzf-tab — replaces zsh's tab completion menu with fzf
zinit light Aloxaf/fzf-tab
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null'

# Autosuggestions — greys out match from history as you type, accept with →
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6b5555'

# Extra completions (loaded before compinit refresh? — zinit handles this)
zinit light zsh-users/zsh-completions

# Syntax highlighting (must be last among shell-UI plugins)
zinit light zdharma-continuum/fast-syntax-highlighting

# ----------------------------------------------------------------------------
# Tool integrations
# ----------------------------------------------------------------------------

# zoxide — smarter cd. Use `z <partial>` or `zi` for interactive pick.
eval "$(zoxide init zsh)"

# atuin — shell history replacement. Ctrl+R opens fuzzy TUI.
# --disable-up-arrow keeps traditional Up = previous command from local session.
eval "$(atuin init zsh --disable-up-arrow)"

# direnv — per-directory env vars via .envrc
eval "$(direnv hook zsh)"

# fzf — shell key bindings (Ctrl+T file picker, Alt+C cd picker, Ctrl+R if not
# overridden by atuin). Atuin wins Ctrl+R; fzf keeps Ctrl+T and Alt+C.
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi
if [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# ----------------------------------------------------------------------------
# Aliases — modern CLI replacements
# ----------------------------------------------------------------------------
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons --group-directories-first'
alias llt='eza -la --tree --level=2 --icons --git --group-directories-first'
alias cat='bat --style=plain --paging=never'
alias less='bat --paging=always'
# Keep the real cat/less available when needed
alias rcat='/usr/bin/cat'
alias rless='/usr/bin/less'

# git shortcuts
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate --all'
alias gp='git pull'

# safety / useful
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -p'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# hypr helpers
alias hr='hyprctl reload'
alias hc='hyprctl clients'

# ----------------------------------------------------------------------------
# Environment
# ----------------------------------------------------------------------------
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export LESS='-R --mouse --wheel-lines=3'

# PATH additions migrated from ~/.bashrc
export PATH="$HOME/.local/share/pinata:$PATH"
export PATH="$HOME/.local/share/pinata-go-cli:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ----------------------------------------------------------------------------
# Powerlevel10k config (run `p10k configure` on first launch to generate)
# ----------------------------------------------------------------------------
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
