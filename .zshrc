# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


# Function to source files if they exist
function zsh_add_file() {
    [ -f "$ZDOTDIR/$1" ] && source "$ZDOTDIR/$1"
}

function zsh_add_plugin() {
    PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)
    PLUGIN_FILE_NAME=$([ -n "$2" ] && echo $2 || echo $PLUGIN_NAME)
    if [ -d "$ZPLUGINDIR/$PLUGIN_NAME" ]; then
        # For plugins
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_FILE_NAME.plugin.zsh" || \
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_FILE_NAME.zsh"
    else
        git clone "https://github.com/$1.git" "$ZPLUGINDIR/$PLUGIN_NAME"
    fi
}

function zsh_add_completion() {
    PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)
    if [ -d "$ZPLUGINDIR/$PLUGIN_NAME" ]; then
        # For completions
		completion_file_path=$(ls $ZPLUGINDIR/$PLUGIN_NAME/_*)
		fpath+="$(dirname "${completion_file_path}")"
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh"
    else
        git clone "https://github.com/$1.git" "$ZPLUGINDIR/$PLUGIN_NAME"
		fpath+=$(ls $ZPLUGINDIR/$PLUGIN_NAME/_*)
        [ -f $ZDOTDIR/.zccompdump ] && $ZDOTDIR/.zccompdump
    fi
	completion_file="$(basename "${completion_file_path}")"
	if [ "$2" = true ] && compinit "${completion_file:1}"
}

function init_fzf() {
    if [ ! -d $ZPLUGINDIR/fzf ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git $ZPLUGINDIR/fzf
        $ZPLUGINDIR/fzf/install
    fi
    source /usr/share/doc/fzf/examples/key-bindings.zsh
    source /usr/share/doc/fzf/examples/completion.zsh
}

function install_git_labeller() {
    if [ ! -d $ZPLUGINDIR/talon-git-labeller ]; then
        git clone --depth 1 https://github.com/mrob95/talon-git-labeller.git $ZPLUGINDIR/talon-git-labeller
    fi
}

function init_pdbrc() {
    cat <<EOF > ~/.pdbrc
import os
print("\033]0;PDB: %s\a" % os.getcwd(), end=None)
EOF
}

# User configuration
mkdir -p $ZPLUGINDIR

init_pdbrc

zsh_add_plugin "romkatv/powerlevel10k"
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "olets/zsh-window-title"
zsh_add_plugin "zsh-users/zsh-completions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "cpitt/zsh-dotenv" "dotenv"

init_fzf

install_git_labeller
labeller_path="$ZPLUGINDIR/talon-git-labeller/main.py"
talon_user_path="/mnt/c/Users/Mike/AppData/Roaming/talon/user"
function git() {
    if [ "$1" = "status" ] && [ "$#" = "1" ]; then
        python "$labeller_path" status "$talon_user_path/git_pt/status.py"
    elif [ "$1" = "branch" ] && [ "$#" = "1" ]; then
        python "$labeller_path" branch "$talon_user_path/git_pt/branch.py"
    elif [ "$1" = "publish" ] && [ "$#" = "1" ] && [ -n "$BROWSER" ]; then
        branch=$(command git rev-parse --abbrev-ref HEAD)
        url=$(command git push -u origin $branch 2>&1 | tee $(tty) | grep "/pull/new" | sed 's/remote:\s*//')
        [ $pipestatus[1] -eq 1 ] && return 1
        [ -n "$url" ] && $BROWSER $url
    else
        command git "$@"
    fi
}

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

HISTFILE=$ZDOTDIR/.zsh_history
HISTSIZE=500000
SAVEHIST=500000
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_FIND_NO_DUPS

source $ZDOTDIR/.zsh_aliases

export PATH=$PATH:/usr/local/go/bin

. "$HOME/.cargo/env"
export PATH="$HOME/.poetry/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

source $ZPLUGINDIR/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

fpath=(~/.zsh/zsh-completions/src /usr/share/zsh/vendor-completions $fpath)
autoload -U compinit; compinit
zstyle ':completion:*' menu yes
zmodload zsh/complist
_comp_options+=(globdots)		# Include hidden files.
