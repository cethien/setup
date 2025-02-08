#Requires -Version 5.1

param (
    [Parameter(Position = 0, HelpMessage = "Profiles to run actions for. Use 'all' to run all actions.")]
    [string[]]$Profiles,

    [Parameter(HelpMessage = "Show profiles in output.")]
    [switch]$PrintProfiles = $false,

    [Parameter(HelpMessage = "Path to a config JSON")]
    [string]$ConfigFile
)

# check if winget is installed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found. winget is required to run this script."
    exit 1
}

# Load config JSON from file or URL
$config = $null

# Check if ConfigFile is a valid URL or a local file path
if ($ConfigFile) {
    if ($ConfigFile -match '^https?://') {
        # If it's a URL, fetch the config from the URL
        try {
            $config = Invoke-RestMethod -Uri $ConfigFile
        } catch {
            Write-Error "Failed to fetch config file from $ConfigFile"
            exit 1
        }
    } elseif (Test-Path $ConfigFile) {
        # If it's a local file path, read the config from the file
        $config = Get-Content $ConfigFile | ConvertFrom-Json
    } else {
        Write-Error "Config file not found at $ConfigFile"
        exit 1
    }
}

if (-not $config) {
    Write-Error "Config file could not be loaded."
    exit 1
}

$actions = $config.actions

if ($PrintProfiles) {
    $profiles = $actions | Where-Object { $_.profiles } | ForEach-Object { $_.profiles } | Sort-Object -Unique
    Write-Host "Profiles:"
    $profiles | ForEach-Object { Write-Host " - $_" }
    exit
}

# Filter actions based on profiles
if ($Profiles.Count -eq 0) {
    $actions = $actions | Where-Object { -not $_.profiles }
}
elseif ($Profiles[0] -eq "all") {
    # Do not filter if "all" is passed
} else {
    $actions = $actions | Where-Object { $_.profiles -in $Profiles -or -not $_.profiles }
}

# Execute actions
foreach ($action in $actions) {
    # Prepare script
    if ($action.prepare_script) {
        Write-Host "  Running prepare script..."
        $action.prepare_script -join "`n" | Invoke-Expression 
    }

    # Main script
    if ($action.script) { 
        Write-Host "  Running main script..."
        $action.script -join "`n" | Invoke-Expression 
    }

    # Install winget packages
    if ($action.winget_packages) {
        foreach ($pkg in $action.winget_packages) {
            Write-Host "  Installing winget package: $($pkg.id)"
            $cmd = "winget install --accept-source-agreements --accept-package-agreements --source winget --Id $($pkg.id) $($pkg.install_flags -join ' ')"
            $cmd | Invoke-Expression

            if ($pkg.exclude_from_updatefile -ne $true) {
                Write-Host "    Adding $($pkg.id) to winget update file."
                Add-Content "$env:USERPROFILE\.wingetupdate" "$($pkg.id)`n"
            }
        }
    }

    # Install PowerShell modules
    if ($action.pwsh_modules) {
        foreach ($module in $action.pwsh_modules) {
            Write-Host "  Installing PowerShell module: $module"
            Install-Module $module -Force -Scope CurrentUser
        }
    }

    # Post-install script
    if ($action.post_install_script) {
        Write-Host "  Running post-install script..."
        $action.post_install_script -join "`n" | Invoke-Expression 
    }
}