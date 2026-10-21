$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$errors = $null
$tokens = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $repo 'scripts/bootstrap-vscode.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) {
    throw ($errors | Out-String)
}
$download = $ast.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Get-VerifiedDownload'
}, $true)
. ([scriptblock]::Create($download.Extent.Text))

$temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
$null = New-Item -ItemType Directory -Path $temp
try {
    $script:fixture = Join-Path $temp 'fixture'
    [IO.File]::WriteAllText($script:fixture, 'verified download fixture')
    function Invoke-WebRequest {
        param($Uri, $OutFile, [switch]$UseBasicParsing, $TimeoutSec)
        Copy-Item -LiteralPath $script:fixture -Destination $OutFile
    }
    $destination = Join-Path $temp 'download'
    $hash = (Get-FileHash -LiteralPath $script:fixture -Algorithm SHA256).Hash
    Get-VerifiedDownload 'https://example.invalid/archive' $destination $hash
    $rejected = $false
    try {
        Get-VerifiedDownload 'https://example.invalid/archive' $destination ('0' * 64)
    }
    catch {
        if ($_.Exception.Message -notlike 'SHA256 mismatch*') {
            throw
        }
        $rejected = $true
    }
    if (-not $rejected) {
        throw 'Corrupted downloads must be rejected.'
    }
    $lock = Get-Content -LiteralPath (Join-Path $repo 'vscode/windows-lock.json') -Raw | ConvertFrom-Json
    foreach ($entry in @($lock.vscode) + @($lock.extensions)) {
        if ($entry.sha256 -notmatch '^[a-f0-9]{64}$' -or $entry.url -notlike 'https://*') {
            throw 'Every Windows artifact must have an HTTPS URL and a SHA256 pin.'
        }
    }
    if ($lock.vscode.url -notlike "*commit:$($lock.vscode.commit)/*") {
        throw 'VS Code download must use the pinned commit.'
    }
    $settings = (Get-Content -LiteralPath (Join-Path $repo 'vscode/windows-settings.json') -Raw).
        Replace('__WSL_HOME__', '/home/example') | ConvertFrom-Json
    if ($settings.'chat.agent.sandbox.fileSystem.userConfiguredPaths'.readwritePaths -notcontains '/home/example/.cache/nix') {
        throw 'Linux home substitution failed.'
    }
    if ($settings.'chat.agent.sandbox.enabled' -ne 'on') {
        throw 'The bootstrap must keep sandboxing enabled.'
    }
    $readonlyPaths = $settings.'chat.agent.sandbox.fileSystem.userConfiguredPaths'.readonlyPaths
    foreach ($path in @('/nix/store', '/etc/profiles', '/run/current-system', '/nix/var/nix/profiles', '/nix/var/nix/daemon-socket')) {
        if ($readonlyPaths -notcontains $path) {
            throw "The sandbox must include read-only Nix access to $path."
        }
    }
    Write-Host 'Bootstrap syntax, download integrity, artifact pins and settings passed.'
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}
