#Requires -Version 5.1

param (
    [Parameter(Position = 0, HelpMessage = "Profiles to run actions for. use 'all' to run all actions.")]
    [string[]]$Profiles,

    [Parameter(HelpMessage = "Show profiles in output.")]
    [switch]$PrintProfiles = $false
)

# check if winget is installed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found. winget is required to run this script."
    exit 1
}

# check if config.json exists
$configFile = "$HOME/.win-setup/config.json"
if (-not (Test-Path $configFile)) {
    # create configFile with property called "$schema" and echo "hello world" action
    $actions = @(
        @{
            script = @(
                "echo `"Hi 👋! please edit me first! i'm at $HOME\.win-setup\config.json`""
            )
        }
    )

    @{
        "`$schema" = "https://raw.githubusercontent.com/cethien/setup/refs/heads/win/schemas/config.schema.json"
        actions    = $actions
    } | ConvertTo-Json -Depth 10 | Set-Content $configFile
}

$actions = Get-Content "$HOME/.win-setup/config.json" | ConvertFrom-Json | Select-Object -Expand actions

if ($PrintProfiles) {
    $profiles = $actions | ForEach-Object { if ($_.profiles -ne $null) { $_.profiles } } | Sort-Object | Get-Unique
    Write-Host "Profiles:"
    $profiles | ForEach-Object { Write-Host " - $_" }
    exit
}

# by default, run only actions with no profiles
if ($Profiles.Count -eq 0) {
    $actions = $actions | Where-Object { $_.profiles -eq $null }
}
elseif ($Profiles.Count -eq 1 -and $Profiles[0] -eq "all") {
    $actions = $actions
}
else {
    $actions = $actions | Where-Object { $_.profiles -eq $null -or $_.profiles -in $Profiles }
}

$actions | ForEach-Object {
    if ($_.prepare_script -ne $null) {
        $_.prepare_script -Join "`n" | Invoke-Expression
    }

    if ($_.script -ne $null) {
        $_.script -Join "`n" | Invoke-Expression
    }

    if ($_.winget_packages -ne $null) {
        $_.winget_packages | ForEach-Object {
            $cmd = "winget install --accept-source-agreements --accept-package-agreements --source winget --Id $($_.id) $($_.install_flags -join " ")"
            $cmd | Invoke-Expression

            if ($_.exclude_from_updatefile -ne $true) {
                Add-Content $env:USERPROFILE/.wingetupdate "$($_.id)`n"
            }
        }
    }

    if ($_.pwsh_modules -ne $null) {
        $_.pwsh_modules | ForEach-Object { Install-Module $_ }
    }

    if ($_.post_install_script -ne $null) {
        $_.post_install_script -Join "`n" | Invoke-Expression
    }
}