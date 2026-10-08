param([switch]$ValidateOnly)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Require-EnvironmentValue([string]$Name) {
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Missing required release environment variable: $Name"
    }
    return $value
}

$adsEnabled = Require-EnvironmentValue 'UNUTMA_ADS_ENABLED'
if ($adsEnabled -notin @('true', '1')) {
    throw 'Play advertising build requires UNUTMA_ADS_ENABLED=true'
}

$adMobAppId = Require-EnvironmentValue 'UNUTMA_ADMOB_APP_ID'
$interstitialId = Require-EnvironmentValue 'UNUTMA_ADMOB_INTERSTITIAL_ID'
$bannerId = Require-EnvironmentValue 'UNUTMA_ADMOB_BANNER_ID'
if ($adMobAppId -notmatch '^ca-app-pub-[0-9]{16}~[0-9]{10}$') {
    throw 'UNUTMA_ADMOB_APP_ID is not a valid Android AdMob app ID'
}
if ($interstitialId -notmatch '^ca-app-pub-[0-9]{16}/[0-9]{10}$') {
    throw 'UNUTMA_ADMOB_INTERSTITIAL_ID is not a valid AdMob interstitial unit ID'
}
if ($bannerId -notmatch '^ca-app-pub-[0-9]{16}/[0-9]{10}$') {
    throw 'UNUTMA_ADMOB_BANNER_ID is not a valid AdMob banner unit ID'
}
if (@($adMobAppId, $interstitialId, $bannerId) | Where-Object { $_ -like 'ca-app-pub-3940256099942544*' }) {
    throw 'Google test AdMob IDs cannot be used in a Play release'
}

$keystore = Require-EnvironmentValue 'UNUTMA_KEYSTORE'
$null = Require-EnvironmentValue 'UNUTMA_STORE_PASSWORD'
$null = Require-EnvironmentValue 'UNUTMA_KEY_ALIAS'
$null = Require-EnvironmentValue 'UNUTMA_KEY_PASSWORD'
if (-not (Test-Path -LiteralPath $keystore -PathType Leaf)) {
    throw "UNUTMA_KEYSTORE does not point to a readable file: $keystore"
}

if ($ValidateOnly) {
    Write-Output 'Play release configuration is complete.'
    exit 0
}

flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }

flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { throw 'Play app bundle build failed' }

$bundle = Join-Path $PSScriptRoot '..\build\app\outputs\bundle\release\app-release.aab'
if (-not (Test-Path -LiteralPath $bundle -PathType Leaf)) {
    throw "Expected app bundle was not created: $bundle"
}

$jarsignerCandidates = @()
if ($env:JAVA_HOME) {
    $jarsignerCandidates += Join-Path $env:JAVA_HOME 'bin\jarsigner.exe'
}
$command = Get-Command jarsigner -ErrorAction SilentlyContinue
if ($command) { $jarsignerCandidates += $command.Source }
if ($env:ProgramFiles) {
    $jarsignerCandidates += Join-Path $env:ProgramFiles 'Android\Android Studio\jbr\bin\jarsigner.exe'
}
$jarsigner = $jarsignerCandidates |
    Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
    Select-Object -First 1
if (-not $jarsigner) {
    throw 'jarsigner was not found; set JAVA_HOME to the JDK used by Android Studio'
}

$signatureOutput = @(
    & $jarsigner '-J-Duser.language=en' '-J-Duser.country=US' -verify -verbose -certs $bundle 2>&1
)
if ($LASTEXITCODE -ne 0 -or -not ($signatureOutput -match '^jar verified\.$')) {
    throw 'The generated app bundle is unsigned or did not pass signature verification'
}

$artifact = Get-Item -LiteralPath $bundle
$hash = Get-FileHash -LiteralPath $bundle -Algorithm SHA256
Write-Output "Play AAB: $($artifact.FullName)"
Write-Output "Bytes: $($artifact.Length)"
Write-Output "SHA-256: $($hash.Hash)"
