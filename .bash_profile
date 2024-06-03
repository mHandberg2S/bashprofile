if [ -f ~/.bashrc ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    . ~/.bashrc
fi