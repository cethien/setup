# Setup scripts

## Windows

## requirements

- powershell
- configuration file `$HOME/.win-setup/config.json`

## usage

```pwsh

iwr "https://raw.githubusercontent.com/cethien/setup/main/setup.ps1" | iex

```

## Linux

### Requirements

- bash

### Usage

```bash
 sh <(curl -fsSL -H 'Cache-Control: no-cache' "https://raw.githubusercontent.com/cethien/setup/main/setup.sh")
```
