#!/usr/bin/env bash

set -e

if command -v apt >/dev/null 2>&1; then
    echo "installing nala"
    sudo apt update &&
        sudo apt install -y nala curl &&
        sudo nala update &&
        sudo nala upgrade -y
fi

if ! command -v nixos-rebuild >/dev/null 2>&1; then
    echo "installing nix package manager"
    curl -fsSL https://nixos.org/nix/install | bash /dev/stdin --no-daemon &&
        mkdir -p "$HOME/.config/nix" &&
        curl https://raw.githubusercontent.com/cethien/setup/lx/resources/nix.conf >>"$HOME/.config/nix/nix.conf"
fi

CONFIGURATION="$(whoami)@$(hostname)"

if [ ! -z "$WSL_DISTRO_NAME" ]; then
    CONFIGURATION="$(whoami)@wsl"
fi

echo "installing home-manager profile"
. "$HOME/.nix-profile/etc/profile.d/nix.sh" &&
    nix run nixpkgs#home-manager -- switch --flake github:cethien/dotfiles#"$CONFIGURATION" -b hm-bak-$(date +%Y%m%d-%H%M%S) --refresh

if [ ! -z "$WSL_DISTRO_NAME" ]; then
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USER" >/dev/null
    echo "rebooting system"
    sudo reboot
fi
