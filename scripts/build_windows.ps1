[CmdletBinding()]
param(
    [string]$Configuration = "Release",
    [string]$Runtime = "win-x64",
    [switch]$FrameworkDependent
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$project = Join-Path $repoRoot "windows\CodexVisual.Windows\CodexVisual.Windows.csproj"
$output = Join-Path $repoRoot "build\windows\CodexVisual.Windows"

$sdks = & dotnet --list-sdks 2>$null
if (-not $sdks -or -not ($sdks -match "^8\."))
{
    throw ".NET 8 SDK is required. Install it from https://dotnet.microsoft.com/download/dotnet/8.0 and rerun this script."
}

$publishArgs = @(
    "publish",
    $project,
    "-c", $Configuration,
    "-r", $Runtime,
    "-o", $output
)

if ($FrameworkDependent)
{
    $publishArgs += "--self-contained"
    $publishArgs += "false"
}
else
{
    $publishArgs += "--self-contained"
    $publishArgs += "true"
    $publishArgs += "/p:PublishSingleFile=true"
    $publishArgs += "/p:IncludeNativeLibrariesForSelfExtract=true"
}

& dotnet @publishArgs
if ($LASTEXITCODE -ne 0)
{
    exit $LASTEXITCODE
}

Write-Host "Windows app published to $output"
