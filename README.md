# Setup scripts

## Windows

## requirements

- powershell
- a config json

## usage

```pwsh

iwr "https://raw.githubusercontent.com/cethien/setup/main/setup.ps1" | iex  -Command "-ConfigFile https://raw.githubusercontent.com/cethien/setup/main/win.json'"

```

## Linux

### Requirements

- bash

### Usage

```bash
 sh <(curl -fsSL -H 'Cache-Control: no-cache' "https://raw.githubusercontent.com/cethien/setup/main/setup.sh")
```
