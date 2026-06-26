[CmdletBinding()]
param(
    [string]$Configuration = "Release",
    [string]$Runtime = "win-x64",
    [string]$ISCCPath
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$project = Join-Path $repoRoot "windows\CodexVisual.Windows\CodexVisual.Windows.csproj"
$iss = Join-Path $repoRoot "windows\installer\CodexVisual.Windows.iss"

& (Join-Path $PSScriptRoot "build_windows.ps1") -Configuration $Configuration -Runtime $Runtime
if ($LASTEXITCODE -ne 0)
{
    exit $LASTEXITCODE
}

if (-not $ISCCPath)
{
    $candidate = Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"
    if (Test-Path $candidate)
    {
        $ISCCPath = $candidate
    }
}

if (-not $ISCCPath -or -not (Test-Path $ISCCPath))
{
    throw "Inno Setup 6 ISCC.exe was not found. Install Inno Setup or pass -ISCCPath."
}

[xml]$projectXml = Get-Content -LiteralPath $project
$version = $projectXml.Project.PropertyGroup.Version

& $ISCCPath "/DAppVersion=$version" $iss
if ($LASTEXITCODE -ne 0)
{
    exit $LASTEXITCODE
}

Write-Host "Windows installer written to $(Join-Path $repoRoot 'build\windows\installer')"
