#!/usr/bin/env bash

LX_ENV=any

# check if WSL
if [ -n "$WSL_DISTRO_NAME" ]; then
    LX_ENV=wsl
fi

# check if NixOS
if [ -e /etc/nixos ]; then
    LX_ENV=nixos
fi

echo "installing setup for $LX_ENV"

# for non nixOS
if [ "$LX_ENV" = "any" ]; then
    # install nala for for distros with apt and update
    if command -v apt >/dev/null 2>&1; then
        echo "installing nala"
        sudo apt update &&
            sudo apt install -y nala curl &&
            sudo nala update &&
            sudo nala upgrade -y
    fi

    # install nix
    echo "installing nix"
    curl -fsSL https://nixos.org/nix/install | bash /dev/stdin --no-daemon &&
        mkdir -p $HOME/.config/nix &&
        curl https://raw.githubusercontent.com/cethien/setup/lx/resources/nix.conf >>$HOME/.config/nix/nix.conf &&
        source "$HOME"/.nix-profile/etc/profile.d/nix.sh
fi

# if nixos, pull nixos repo and rebuild
if [ "$LX_ENV" = "nixos" ]; then
    echo "setting up nixos"
    NIXOS_SCRIPT='
    git clone https://github.com/cethien/nixos.git $HOME/nixos &&
        sudo nixos-rebuild switch --flake $HOME/nixos/#pc-cethien
    '
    nix-shell -p git --run "$NIXOS_SCRIPT"
fi

RUN_SCRIPT='
git init -b lx &&
    git remote add origin https://github.com/cethien/dotfiles.git &&
    git fetch origin lx &&
    git reset --hard origin/lx &&
    git pull --set-upstream origin lx &&
    curl https://raw.githubusercontent.com/cethien/setup/lx/resources/config.template.json >>$HOME/.config/home-manager/config.json &&
    nano $HOME/.config/home-manager/config.json &&
    home-manager switch -b hm.bak
'

nix-shell -p git home-manager nano curl --run "$RUN_SCRIPT"

# for wsl,
if [ "$LX_ENV" = "wsl" ]; then
    # add ssh-passthrough script

    echo "adding ssh-passthrough script"
    curl -fsSL https://raw.githubusercontent.com/cethien/setup/lx/resources/ssh-agent-pipe.sh | sudo tee /usr/local/bin/ssh-agent-pipe >/dev/null &&
        sudo chmod +x /usr/local/bin/ssh-agent-pipe

    # remove sudo password prompt
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USER" >/dev/null

    # reboot
    sudo reboot
fi
