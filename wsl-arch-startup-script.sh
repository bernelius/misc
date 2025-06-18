#!/bin/bash

#if you want to exit on error
#set -e

#silence commands
set -x

echo "Installing packages..."
pacman -Syu --noconfirm \
	sudo \
	unzip \
	base-devel \
	git \
	neovim \
	curl \
	zsh \
	zsh-completions \
	git-zsh-completion \
	zsh-syntax-highlighting \
	tmux \
	openssh \
	ripgrep \
	lazygit \
	fzf \
	npm \
	python \
	mc \
	wget \
	htop \
	pv \
	go \
	yazi \
	git \
	cargo

chsh -s /bin/zsh

if ! getent group sudo > /dev/null; then
	echo "Creating sudo group..."
	groupadd sudo
fi

sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL:ALL)\s\+ALL\)/\1/' /etc/sudoers

read -rp "Enter new username: " USERNAME
useradd -m -G sudo -s /bin/zsh "$USERNAME"

cat <<EOF > /etc/wsl.conf
[user]
default=$USERNAME
EOF

echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/temp_user_010101

runuser -l "$USERNAME" -c '
	cd ~
	git clone https://aur.archlinux.org/yay-git.git
	cd yay-git
	makepkg -si --noconfirm
	rm -rf ~/yay-git
'

runuser -l "$USERNAME" -c '
	cd ~
	git clone https://github.com/bernelius/dotfiles
	cd dotfiles
	chmod +x install.sh
	./install.sh
	git remote set-url origin git@github.com:bernelius/dotfiles.git
	
	read -rp "Enter github email address: " EMAIL
	read -rp "Enter github name to use for commits: " GITNAME
	git config --global user.email "$EMAIL"
	git config --global user.name "$GITNAME"
	ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/id_ed25519
	eval `ssh-agent`
	ssh-add ~/.ssh/id_ed25519
	cat ~/.ssh/id_ed25519.pub | win32yank.exe -i
	passwd "$USERNAME"
	echo "ssh key copied to windows clipboard. Go to github.com/settings/keys to paste it"
'


rm /etc/sudoers.d/temp_user_010101

su - "$USERNAME"