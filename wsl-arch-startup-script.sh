#!/bin/bash

#if you want to exit on error
#set -e

#set -x will unsilence commands
#set -x

prompt_username() {
	echo "------------------------"
	echo ""
	read -rp "Enter your new username: " USERNAME
	echo ""
	echo "------------------------"
}



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
	fastfetch \
	cargo || { echo "pacman failed, aborting script."; exit 1; }

#creating sudo group
if ! getent group sudo > /dev/null; then
	echo "Creating sudo group..."
	groupadd sudo
fi
#uncommenting sudo line in sudoers
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL:ALL)\s\+ALL\)/\1/' /etc/sudoers

while true; do
	prompt_username
	echo "Is this username correct: '$USERNAME'? (Y/n)"
	read answer
	answer=${answer:-Y}
	case "$answer" in
		[Yy]*)
			break
			;;
		[Nn]*)
			;;
		*)
			echo "Please enter y or n."
			;;
	esac
done

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
#if wsl, clone win32yank
if grep -qi microsoft /proc/sys/kernel/osrelease; then
	mkdir -p /usr/local/bin
	cd /tmp
	curl -LO https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
	unzip win32yank-x64.zip
	mv win32yank.exe /usr/local/bin/
	chmod +x /usr/local/bin/win32yank.exe
fi

#sets up github ssh and clones the bernelius/dotfiles repo
runuser -l "$USERNAME" -c '
	prompt_github_details() {
		echo "------------------------"
		echo ""
		read -rp "Enter github email address: " EMAIL
		read -rp "Enter github name to use for commits: " GITNAME
		echo ""
		echo "------------------------"
	}
	
	cd ~
	git clone https://github.com/bernelius/dotfiles
	cd dotfiles
	chmod +x install.sh
	./install.sh
	git remote set-url origin git@github.com:bernelius/dotfiles.git
	
	while true; do
		prompt_github_details
		echo "Is this information correct:"
		echo "github email address: $EMAIL"
		echo "github commit name: $GITNAME"
		echo "(Y/n)"
		read answer
		answer=${answer:-Y}
		case "$answer" in
			[Yy]*)
				break
				;;
			[Nn]*)
				;;
			*)
				echo "Please enter y or n."
				;;
		esac
	done
	


	git config --global user.email "$EMAIL"
	git config --global user.name "$GITNAME"

	ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/id_ed25519 -N ""
	eval `ssh-agent`
	ssh-add ~/.ssh/id_ed25519
	cat ~/.ssh/id_ed25519.pub | win32yank.exe -i
	echo ""
	echo ""
	echo "ssh key copied to windows clipboard. Go to github.com/settings/keys to paste it"
	echo ""
	echo ""
'

#deletes temporary passwordless sudo access
rm /etc/sudoers.d/temp_user_010101
echo "------------------------"
echo ""
echo "Set up a password for your linux user account ($USERNAME)"
passwd "$USERNAME"
echo ""
echo "------------------------"
su - "$USERNAME"
chsh -s /bin/zsh
echo "Welcome."
