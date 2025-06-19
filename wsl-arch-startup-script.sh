#!/bin/bash

#if you want to exit on error
#set -e

#set -x will unsilence commands
#set -x

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
	cargo || { echo "pacman failed, aborting script."; exit 1; }

#creating sudo group
if ! getent group sudo > /dev/null; then
	echo "Creating sudo group..."
	groupadd sudo
fi
#uncommenting sudo line in sudoers
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL:ALL)\s\+ALL\)/\1/' /etc/sudoers

echo "------------------------"
echo ""
read -rp "Enter your new username: " USERNAME
echo ""

useradd -m -G sudo "$USERNAME"

cat <<EOF > /etc/wsl.conf
[user]
default=$USERNAME
EOF

#adds temporary sudo access to everything with no password
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/temp_user_010101

runuser -l "$USERNAME" -c '
	cd ~
	git clone https://aur.archlinux.org/yay-git.git
	cd yay-git
	makepkg -si --noconfirm
	rm -rf ~/yay-git
'

#sets up github ssh and clones the bernelius/dotfiles repo
runuser -l "$USERNAME" -c '
	cd ~
	git clone https://github.com/bernelius/dotfiles
	cd dotfiles
	chmod +x install.sh
	./install.sh
	git remote set-url origin git@github.com:bernelius/dotfiles.git

	echo "------------------------"
	echo ""
	read -rp "Enter github email address: " EMAIL
	read -rp "Enter github name to use for commits: " GITNAME
	echo ""

	git config --global user.email "$EMAIL"
	git config --global user.name "$GITNAME"

	ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/id_ed25519
	eval `ssh-agent`
	ssh-add ~/.ssh/id_ed25519
	cat ~/.ssh/id_ed25519.pub | win32yank.exe -i
	echo "------------------------"
	echo "ssh key copied to windows clipboard. Go to github.com/settings/keys to paste it"
	echo "------------------------"
'

#deletes temporary passwordless sudo access
rm /etc/sudoers.d/temp_user_010101
echo "------------------------"
echo ""
passwd "$USERNAME"
echo "------------------------"
su - "$USERNAME"
chsh -s /bin/zsh
