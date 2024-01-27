# profiling
# zmodload zsh/zprof

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

function init_pdbrc() {
    cat <<EOF > ~/.pdbrc
import os
print("\033]0;PDB: %s\a" % os.getcwd(), end=None)
EOF
}

function init_ssh_agent() {
    if [ $(ps ax | grep "[s]sh-agent" | wc -l) -eq 0 ] ; then
        eval $(ssh-agent -s) > /dev/null
        if [ "$(ssh-add -l)" = "The agent has no identities." ] ; then
            ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1
        fi
    fi
}

function init_starship() {
    if [ ! command -v starship &> /dev/null ];then
        echo "Installing starship"
        curl -sS https://starship.rs/install.sh | sh
    fi
    export STARSHIP_CONFIG="${ZDOTDIR}/starship.toml"
    eval "$(starship init zsh)"
}

# User configuration
mkdir -p $ZPLUGINDIR

init_pdbrc
init_ssh_agent
init_starship

zsh_add_plugin "romkatv/powerlevel10k"
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "olets/zsh-window-title"
zsh_add_plugin "zsh-users/zsh-completions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "cpitt/zsh-dotenv" "dotenv"

init_fzf

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
export PATH="$HOME/.local/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$ZDOTDIR/bin:$PATH"
eval "$(pyenv init --path)"

fpath=(~/.zsh/zsh-completions/src /usr/share/zsh/vendor-completions $fpath)
autoload -U compinit; compinit  2> /dev/null
zstyle ':completion:*:*:make:*' tag-order 'targets'
setopt noautomenu
setopt nomenucomplete
_comp_options+=(globdots)		# Include hidden files.
