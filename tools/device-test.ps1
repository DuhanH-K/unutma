param([string]$Serial = 'emulator-5554')
$ErrorActionPreference = 'Stop'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$pkg = 'app.unutma.mobile'
& $adb -s $Serial install --no-streaming -r build\app\outputs\apk\debug\app-debug.apk
if ($LASTEXITCODE -ne 0) { throw 'App installation failed' }
& $adb -s $Serial install --no-streaming -r build\app\outputs\apk\androidTest\debug\app-debug-androidTest.apk
if ($LASTEXITCODE -ne 0) { throw 'Test installation failed' }
$result = & $adb -s $Serial shell am instrument -w -e class app.unutma.unutma.NativeIntegrationTest "$pkg.test/androidx.test.runner.AndroidJUnitRunner"
$result
if (($result -join "`n") -notmatch 'OK \(\d+ tests?\)') { throw 'Native instrumented tests failed' }
& $adb -s $Serial shell pm revoke $pkg android.permission.POST_NOTIFICATIONS
$denied = & $adb -s $Serial shell am instrument -w -e class app.unutma.unutma.ReminderPermissionTest "$pkg.test/androidx.test.runner.AndroidJUnitRunner"
$denied
if (($denied -join "`n") -notmatch 'OK \(1 test\)') { throw 'Denied permission test failed' }
$listenerComponent = "$pkg/app.unutma.unutma.notification.UnutmaNotificationListenerService"
# Instrumentation force-stops the target package when a run ends. Toggle access so
# NotificationManager creates a fresh listener process instead of retaining a stale binding.
& $adb -s $Serial shell cmd notification disallow_listener $listenerComponent
Start-Sleep -Milliseconds 500
& $adb -s $Serial shell cmd notification allow_listener $listenerComponent
# Listener binding is asynchronous after a fresh install. Give Android a bounded
# window to connect it before posting the notification used by the black-box test.
$listenerReady = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    $notificationState = & $adb -s $Serial shell dumpsys notification
    if (($notificationState -join "`n") -match "Live notification listeners[\s\S]*$pkg/app\.unutma\.unutma\.notification\.UnutmaNotificationListenerService") {
        $listenerReady = $true
        break
    }
    Start-Sleep -Milliseconds 500
}
if (-not $listenerReady) { throw 'Notification listener did not connect' }
# dumpsys can expose the binding in the live collection just before the service's
# onListenerConnected callback. This bounded grace period closes that platform race.
Start-Sleep -Seconds 2
$qaDue=(Get-Date).AddDays(7).ToString('dd.MM.yyyy')
& $adb -s $Serial shell "cmd notification post -t 'UNUTMA QA' unutma_qa 'Payment due $qaDue'"
# Notification delivery is asynchronous. Bounded wait; no Flutter activity is launched.
Start-Sleep -Seconds 3
$capture = & $adb -s $Serial shell am instrument -w -e backgroundScenario true -e class app.unutma.unutma.BackgroundCaptureTest "$pkg.test/androidx.test.runner.AndroidJUnitRunner"
$capture
if (($capture -join "`n") -notmatch 'OK \(1 test\)') { throw 'Background notification capture failed' }
