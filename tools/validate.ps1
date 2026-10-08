$ErrorActionPreference = 'Stop'
function Invoke-Checked {
    param([scriptblock]$Command)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "Validation command failed: $Command" }
}
Invoke-Checked { flutter pub get }
Invoke-Checked { dart format . }
Invoke-Checked { flutter analyze }
Invoke-Checked { flutter test }
Invoke-Checked { python tools/validate_store_assets.py }
Invoke-Checked { flutter build apk --debug }
if (-not $env:JAVA_HOME) {
    $studioJdk = Join-Path $env:ProgramFiles 'Android\Android Studio\jbr'
    if (Test-Path -LiteralPath $studioJdk) { $env:JAVA_HOME = $studioJdk }
}
Invoke-Checked { .\android\gradlew.bat -p android :app:testDebugUnitTest --console=plain }
# Release bundle is unsigned unless all UNUTMA signing variables are configured.
Invoke-Checked { flutter build appbundle --release }
