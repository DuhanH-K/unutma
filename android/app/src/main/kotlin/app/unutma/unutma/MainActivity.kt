package app.unutma.unutma

import android.Manifest
import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import app.unutma.unutma.bridge.NativeApi
import app.unutma.unutma.bridge.UnutmaApi
import app.unutma.unutma.bridge.UnutmaEvents
import app.unutma.unutma.notification.NotificationListenerBindingRepair
import app.unutma.unutma.reminder.ReminderPreview
import app.unutma.unutma.storage.NativeRepository
import kotlinx.coroutines.*

class MainActivity:FlutterActivity() {
    private companion object {
        const val AD_CONFIG_CHANNEL = "app.unutma/ads-config"
        val CARD_ID_PATTERN=Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")
    }
    private var observer:Job?=null
    private var openedCard:String?=null
    private var sharedText:String?=null
    private var events:UnutmaEvents?=null
    private var screenshotWakeLock:PowerManager.WakeLock?=null
    private val listenerRepairScope=CoroutineScope(SupervisorJob()+Dispatchers.Default)
    override fun onCreate(savedInstanceState:Bundle?) {
        if(BuildConfig.DEBUG && intent?.getBooleanExtra("screenshotMode",false)==true) {
            @Suppress("DEPRECATION")
            val wakeFlags=PowerManager.FULL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE
            screenshotWakeLock=getSystemService(PowerManager::class.java)
                .newWakeLock(wakeFlags,"unutma:screenshot-mode")
                .apply { acquire(120_000) }
            window.addFlags(
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            )
        }
        super.onCreate(savedInstanceState)
        if(BuildConfig.DEBUG && intent?.getBooleanExtra("screenshotMode",false)==true &&
            Build.VERSION.SDK_INT>=Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }
    private fun requestNotificationListenerRebind() {
        NotificationListenerBindingRepair.schedule(applicationContext)
        listenerRepairScope.launch {
            NotificationListenerBindingRepair.repair(applicationContext)
        }
    }
    private fun consumeIntent(source:Intent?):Boolean {
        source ?: return false
        var hasNavigationTarget=false
        if(source.action=="${packageName}.PREVIEW_REMINDER") {
            ReminderPreview.show(applicationContext)
            source.action=null
        }
        if(BuildConfig.DEBUG) {
            runCatching { source.getStringExtra("debugRoute") }.getOrNull()
                ?.takeIf { it.startsWith("/") && it.length<=120 }
                ?.let {
                    openedCard="route:$it"
                    hasNavigationTarget=true
                }
        }
        runCatching { source.getStringExtra("cardId") }.getOrNull()
            ?.takeIf { BuildConfig.DEBUG || CARD_ID_PATTERN.matches(it) }
            ?.let {
                openedCard=if(runCatching { source.getBooleanExtra("editCard",false) }.getOrDefault(false)) {
                    "route:/edit/$it"
                } else {
                    it
                }
                hasNavigationTarget=true
            }
        val incoming=when(source.action) {
            Intent.ACTION_SEND -> safeExtra(source,Intent.EXTRA_TEXT)
            Intent.ACTION_PROCESS_TEXT -> safeExtra(source,Intent.EXTRA_PROCESS_TEXT)
            else -> null
        }
        val subject=safeExtra(source,Intent.EXTRA_SUBJECT)
        val received=incoming!=null || subject!=null
        if(received) {
            sharedText=listOfNotNull(subject,incoming).distinct().joinToString("\n").take(4096)
            source.action=null
            source.replaceExtras(android.os.Bundle.EMPTY)
        }
        // Compatibility for reminders posted by builds before the explicit-intent fix.
        if(source.data?.scheme=="unutma-internal") source.data=null
        return received || hasNavigationTarget
    }
    private fun safeExtra(source:Intent,key:String):String?=
        runCatching { bounded(source.getCharSequenceExtra(key)) }.getOrNull()
    private fun bounded(value:CharSequence?):String?=value?.let {
        it.subSequence(0,minOf(it.length,4096)).toString().replace("\u0000","").trim().ifEmpty { null }
    }
    override fun configureFlutterEngine(flutterEngine:FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        requestNotificationListenerRebind()
        consumeIntent(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AD_CONFIG_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getConfig") {
                    result.success(
                        mapOf(
                            "enabled" to BuildConfig.ADS_ENABLED,
                            "interstitialId" to BuildConfig.ADMOB_INTERSTITIAL_ID,
                            "bannerId" to BuildConfig.ADMOB_BANNER_ID,
                            "testAds" to BuildConfig.ADMOB_TEST_ADS,
                        ),
                    )
                } else {
                    result.notImplemented()
                }
            }
        UnutmaApi.setUp(flutterEngine.dartExecutor.binaryMessenger,NativeApi(
            this,
            { openedCard.also { openedCard=null } },
            { sharedText.also { sharedText=null } },
        ))
        events=UnutmaEvents(flutterEngine.dartExecutor.binaryMessenger)
        observer=CoroutineScope(Dispatchers.IO).launch {
            NativeRepository.get(applicationContext).dao.observe().collect {
                withContext(Dispatchers.Main) { runCatching { events?.cardsChanged() } }
            }
        }
    }
    override fun onNewIntent(intent:Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if(consumeIntent(intent)) CoroutineScope(Dispatchers.Main).launch {
            runCatching { events?.sharedTextReceived() }
        }
    }
    override fun onResume() {
        super.onResume()
        // FlutterEngine can stay alive while the Activity is backgrounded, so
        // configureFlutterEngine is not guaranteed to run on every return.
        // Rebind here as well to recover OEM-killed listeners; on connection
        // the service reprocesses still-visible WhatsApp/SMS previews.
        requestNotificationListenerRebind()
        if(Build.VERSION.SDK_INT>=33) {
            val prefs=getSharedPreferences("preferences",MODE_PRIVATE)
            if(prefs.getBoolean("requestNotificationsAfterAccess",false)) {
                prefs.edit().remove("requestNotificationsAfterAccess").apply()
                window.decorView.post {
                    if(checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),43)
                    }
                }
            }
        }
    }
    override fun cleanUpFlutterEngine(flutterEngine:FlutterEngine) {
        observer?.cancel()
        events=null
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AD_CONFIG_CHANNEL)
            .setMethodCallHandler(null)
        UnutmaApi.setUp(flutterEngine.dartExecutor.binaryMessenger,null)
        super.cleanUpFlutterEngine(flutterEngine)
    }
    override fun onDestroy() {
        listenerRepairScope.cancel()
        screenshotWakeLock?.takeIf { it.isHeld }?.release()
        screenshotWakeLock=null
        super.onDestroy()
    }
}
