#!/usr/bin/env bash

#if you want to exit on error

# exit on error, undefined variable and pipefail
set -euo pipefail

#set -x will unsilence commands
#set -x

if ! grep -qi microsoft /proc/sys/kernel/osrelease; then
  pacman -Syu --noconfirm timeshift || { echo "pacman failed, aborting script."; exit 1; }
  timeshift --create --comments "Pre-install script backup"
fi

prompt_username() {
  echo "------------------------"
  echo ""
  read -rp "Enter your new username: " USERNAME
  echo "e"
  echo "------------------------"
}



echo "Installing packages..."
pacman -Syu --noconfirm \
  sudo \
  unzip \
  base-devel \
  git \
  github-cli \
  neovim \
  curl \
  zsh \
  zsh-completions \
  git-zsh-completion \
  zsh-syntax-highlighting \
  tmux \
  openssh \
  ripgrep \
  fd \
  zoxide \
  lazygit \
  fzf \
  npm \
  python \
  python-uv \
  mc \
  man \
  wget \
  htop \
  pv \
  go \
  yazi \
  fastfetch \
  eza \
  postgresql \
  meson \
  ninja \
  nix \
  direnv \
  rustup \
  cargo \
  libappindicator || { echo "pacman failed, aborting script."; exit 1; }

if ! grep -qi microsoft /proc/sys/kernel/osrelease; then
  #uncomment multilib
  sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
  ./tuxedo-pacman-installer.sh
  #EOF needs to be all the way left or bash will get confused
  cat <<EOF >> /etc/NetworkManager/conf.d/wifi_backend.conf
[device]
wifi.backend=iwd
EOF
fi


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
  answer=${answer:-N}
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

#EOF needs to be all the way left or bash will get confused
if grep -qi microsoft /proc/sys/kernel/osrelease; then
  cat <<EOF > /etc/wsl.conf
[user]
default=$USERNAME
EOF
fi

#adds temporary sudo access to everything with no password
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/temp_user_010101

runuser -l "$USERNAME" -c '
  cd ~
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  rm -rf ~/yay

  yay -S --noconfirm \
    sesh-bin \
    gitmux-git

  if ! grep -qi microsoft /proc/sys/kernel/osrelease; then
    yay -S --noconfirm \
      cable \
      tuxedo-control-center-bin \
      tuxedo-drivers-dkms \
      catppuccin-gtk-theme-mocha \
      grimblast-git \
      localsend \
      vesktop \
      webapp-manager \
    yay -R --noconfirm \
      vesktop-debug
    yay -S --noconfirm \
      pgadmin4-server \
      pgadmin4-desktop
    yay -R --noconfirm pgadmin4-debug
  fi
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

  if grep -qi microsoft /proc/sys/kernel/osrelease; then
    CLIPBOARD="win32yank.exe -i"
  else
    CLIPBOARD="echo > /dev/null"
  fi 

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
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  cat ~/.ssh/id_ed25519.pub | $CLIPBOARD
  echo ""
  echo ""
  echo "ssh key copied to clipboard. Go to github.com/settings/keys to paste it"
  echo "If you do not have a clipboard, you can find the public key file at ~/.ssh/id_ed25519.pub"
  echo ""
  echo ""
'

# daemons and groups
if ! grep -qi microsoft /proc/sys/kernel/osrelease; then
  runuser -l postgres -c 'initdb -D /var/lib/postgres/data'
  runuser -l "$USERNAME" -c '
    systemctl enable iwd
    groupadd impala
    usermod -aG impala $USER
    chown $(which impala) root:impala
    chmod 4750 $(which impala)
    systemctl enable bluetooth
    groupadd nix-users
    usermod -aG nix-users $USER
    systemctl enable nix-daemon
    systemctl enable chronyd
    systemctl --user enable hyprpolkitagent
    systemctl enable postgresql
  '
fi

#deletes temporary passwordless sudo access
rm /etc/sudoers.d/temp_user_010101
echo "------------------------"
echo ""
echo "Set up a password for your linux user account ($USERNAME)"
passwd "$USERNAME"
echo ""
echo "------------------------"
runuser -l "$USERNAME" -c 'chsh -s /bin/zsh'
if grep -qi microsoft /proc/sys/kernel/osrelease; then
  echo "Welcome."
else
  git clone https://www.github.com/bernelius/misc /tmp/misc
  cd /tmp/misc
  mkdir -p /home/"$USERNAME"/docs/img/wallpapers
  cp /tmp/misc/wallpapers/* /home/"$USERNAME"/docs/img/wallpapers/
  rm -rf /tmp/misc

  read -rp "Done. Press enter to reboot." ANSWER
  if [[ -z "$ANSWER" ]]; then
    reboot
  fi
fi

