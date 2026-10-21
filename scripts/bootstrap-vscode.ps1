[CmdletBinding()]
param(
    [ValidatePattern('^[a-z_][a-z0-9_-]*$')]
    [string]$LinuxUser = 'dandyrow',
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$Distro = 'NixOS',
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'Programs\dotfiles-vscode'),
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-VerifiedDownload {
    param([string]$Url, [string]$Destination, [string]$Sha256)
    Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -TimeoutSec 600
    $actual = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
    if ($actual -ne $Sha256) {
        throw "SHA256 mismatch for $Url. Expected $Sha256; received $actual."
    }
}

$repo = Split-Path -Parent $PSScriptRoot
$lock = Get-Content -LiteralPath (Join-Path $repo 'vscode/windows-lock.json') -Raw | ConvertFrom-Json
$linuxHome = "/home/$LinuxUser"
$versionRoot = Join-Path $InstallRoot $lock.vscode.commit
$code = Join-Path $versionRoot 'bin\code.cmd'
$userData = Join-Path $env:APPDATA 'dotfiles-vscode'
$extensions = Join-Path $InstallRoot 'extensions'
$temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
$null = New-Item -ItemType Directory -Path $temp

try {
    $marker = Join-Path $versionRoot '.dotfiles-sha256'
    $installed = (Test-Path -LiteralPath $code) -and
        (Test-Path -LiteralPath $marker) -and
        ((Get-Content -LiteralPath $marker -Raw).Trim() -eq $lock.vscode.sha256)
    if (-not $installed) {
        if (Test-Path -LiteralPath $versionRoot) {
            throw "Incomplete or unexpected installation at $versionRoot. Inspect it before retrying."
        }
        $archive = Join-Path $temp 'vscode.zip'
        Get-VerifiedDownload $lock.vscode.url $archive $lock.vscode.sha256
        $null = New-Item -ItemType Directory -Path $versionRoot
        Expand-Archive -LiteralPath $archive -DestinationPath $versionRoot
        Set-Content -LiteralPath $marker -Value $lock.vscode.sha256 -Encoding ASCII
    }

    $userSettings = Join-Path $userData 'User'
    $null = New-Item -ItemType Directory -Force -Path $userSettings, $extensions
    $settings = (Get-Content -LiteralPath (Join-Path $repo 'vscode/windows-settings.json') -Raw).
        Replace('__WSL_HOME__', $linuxHome)
    $settingsPath = Join-Path $userSettings 'settings.json'
    [IO.File]::WriteAllText($settingsPath, $settings, (New-Object Text.UTF8Encoding $false))

    $codeArgs = @('--user-data-dir', $userData, '--extensions-dir', $extensions)
    $installedExtensions = @(& $code @codeArgs --list-extensions --show-versions)
    if ($LASTEXITCODE -ne 0) {
        throw "VS Code extension listing failed with exit code $LASTEXITCODE."
    }
    foreach ($extension in $lock.extensions) {
        if ($installedExtensions -contains "$($extension.id)@$($extension.version)") {
            continue
        }
        $vsix = Join-Path $temp "$($extension.id).vsix"
        Get-VerifiedDownload $extension.url $vsix $extension.sha256
        & $code @codeArgs --install-extension $vsix --force
        if ($LASTEXITCODE -ne 0) {
            throw "Installation of $($extension.id) failed with exit code $LASTEXITCODE."
        }
    }
    $installedExtensions = @(& $code @codeArgs --list-extensions --show-versions)
    if ($LASTEXITCODE -ne 0) {
        throw "VS Code extension verification failed with exit code $LASTEXITCODE."
    }
    foreach ($extension in $lock.extensions) {
        if ($installedExtensions -notcontains "$($extension.id)@$($extension.version)") {
            throw "Expected extension $($extension.id)@$($extension.version) is not installed."
        }
    }

    $launcher = Join-Path $InstallRoot 'code-wsl.cmd'
    $command = "`"$code`" --user-data-dir `"$userData`" --extensions-dir `"$extensions`""
    $content = "@echo off`r`ncall $command --remote `"wsl+$Distro`" %*`r`n"
    [IO.File]::WriteAllText($launcher, $content, (New-Object Text.UTF8Encoding $false))
    Write-Host "VS Code $($lock.vscode.version) is ready. Use $launcher to open this managed editor."
    Write-Host "Settings are managed at $settingsPath. Existing VS Code profiles were not changed."
    if ($Launch) {
        & $code @codeArgs --folder-uri "vscode-remote://wsl+$Distro$linuxHome"
        if ($LASTEXITCODE -ne 0) {
            throw "VS Code launch failed with exit code $LASTEXITCODE."
        }
    }
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}
