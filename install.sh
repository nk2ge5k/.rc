#!/bin/bash

SCRIPT_DIR=$(realpath $(dirname $0))
SOURCE_DIR="$HOME/src"
BINARY_DIR="$HOME/bin"

mkdir -p $SOURCE_DIR
mkdir -p $BINARY_DIR

ssh-add

################################# DEPENDENCIES #################################

echo "=========================== INSTALLING DEPENDENCIES ==========================="

OS=$(uname)

echo "Installing dependencies for $OS..."

LUAROCKS="luarocks"
if [[ "$OS" == "Linux" ]]; then
    sudo apt install -y $(cat packages.txt)
elif [[ "$OS" == "Darwin" ]]; then
    for package in $(cat mac-packages.txt); do
        sudo port install $package
    done
    export PATH=/opt/local/bin:/opt/local/sbin:$PATH
    LUAROCKS="luarocks-5.3"
    SCRIPT_DIR=$(grealpath $(dirname $0))
else
    echo "Unexpected operation system $OS"
    exit 1;
fi

##################################### VIM ######################################

if ! command -v nvim &> /dev/null
then
echo "============================== INSTALLING NEOVIM ==============================="

    sudo $LUAROCKS build mpack
    sudo $LUAROCKS build lpeg
    sudo $LUAROCKS build inspect

    NEOVIM_DIR="$SOURCE_DIR/github.com/neovim/neovim"
    if [ ! -d "$NEOVIM_DIR" ]
    then
        git clone git@github.com:neovim/neovim.git "$NEOVIM_DIR"
    fi

    cd $NEOVIM_DIR && \
        make clean && git checkout master && git pull origin master && \
        make CMAKE_BUILD_TYPE=RelWithDebInfo && \
        sudo make install

    INIT_VIM="$HOME/.config/nvim/init.vim"
    if [ -f "$INIT_VIM" ]
    then
        if ! grep -q "vimrc" $INIT_VIM
        then
            echo 'source ~/.vimrc' >> $INIT_VIM
        fi
    fi
fi


if [ ! -f "$HOME/.vimrc" ]
then
    if [ ! -d "$HOME/.vim/plugged" ]
    then
echo "============================= INSTALLING VIM-PLUG ============================="

        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
fi

(cat <<EOF
let &runtimepath.=',$SCRIPT_DIR/vim'
source $SCRIPT_DIR/vim/vimrc
EOF
) > $HOME/.vimrc

##################################### GIT ######################################

if [ ! -f "$HOME/.gitconfig" ]
then
echo "============================ INSTALLING GIT CONFIG ============================="

(cat  <<EOF
[include]
    path = $SCRIPT_DIR/git/gitconfig
EOF
) > $HOME/.gitconfig

fi

##################################### TMUX #####################################
if ! command -v tmux &> /dev/null
then
echo "================================ INTALLING TMUX ================================"

    TMUX_DIR="$SOURCE_DIR/github.com/tmux/tmux"
    if [ ! -d "$TMUX_DIR" ]
    then
        git clone git@github.com:tmux/tmux.git "$TMUX_DIR"
    else
        cd $TMUX_DIR && make clean && git pull origin master
    fi

    cd "$SOURCE_DIR/github.com/tmux/tmux" && \
        ./autogen.sh && ./configure --enable-utf8proc && make && sudo make install

fi

if [ ! -f "$HOME/.tmux.conf" ]
then
    ln -s "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
fi

##################################### ZSH ######################################
if ! command -v zsh &> /dev/null
then
echo "================================ INTALLING ZSH ================================"

    if [[ "$OS" == "Linux" ]]; then
        sudo apt install -y zsh
    elif [[ "$OS" == "Darwin" ]]; then
        sudo port install -y zsh
    else
        echo "Unexpected operation system $OS"
        exit 1;
    fi
fi

echo "source $SCRIPT_DIR/zsh/zshrc" > $HOME/.zshrc
if [[ "$OS" == "Darwin" ]]; then
   echo "alias realpath=grealpath" >> $HOME/.zshrc
fi

##################################### RUST #####################################
if ! command -v rustup &> /dev/null
then
echo "=============================== INSTALLING RUST ==============================="

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

fi

###################################### GO ######################################
if ! command -v go &> /dev/null
then
echo "================================ INSTALLING GO ================================"

curl --proto '=https' --tlsv1.2 -sSf https://storage.googleapis.com/golang/go1.16.4.linux-amd64.tar.gz | tar -C $BINARY_DIR -xzf -

fi


#################################### NOTES #####################################
if [ ! -d "$HOME/notes" ]
then
echo "=============================== INSTALLING NOTES =============================="
git clone git@github.com:nk2ge5k/notes.git "$HOME/notes"

fi
