#Requires -Version 5.1

param (
    [Parameter(HelpMessage = "profiles")]
    [string[]]$Profiles    
)

# check if config.json exists
$configFile = "$HOME/.win-setup/config.json"
if (-not (Test-Path $configFile)) {
    # create configFile with property called "$schema" and echo "hello world" action
    $config = @{
        "`$schema" = "https://raw.githubusercontent.com/cethien/win-setup/main/config.schema.json"
        actions    = @(
            @{
                script = "echo `"Hello World! please edit $HOME\.win-setup\config.json`""
            }
        )
    } | ConvertTo-Json -Depth 10 | Set-Content $configFile
}

$config = Get-Content "$HOME/.win-setup/config.json" | ConvertFrom-Json

$config.actions | ForEach-Object {
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