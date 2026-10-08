package app.unutma.unutma.notification

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.service.notification.NotificationListenerService
import androidx.core.app.NotificationManagerCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.delay
import java.util.concurrent.TimeUnit

/** Repairs OEM listener bindings while preserving the user's durable permission choice. */
object NotificationListenerBindingRepair {
    private const val PREFS = "notification_listener_health"
    private const val LAST_REFRESH = "last_component_refresh"
    private const val REFRESH_COOLDOWN_MS = 10 * 60 * 1000L
    private const val PERIODIC_WORK = "notification-listener-binding-repair"

    fun hasAccess(context: Context): Boolean {
        val component = ComponentName(context, UnutmaNotificationListenerService::class.java)
        return if (Build.VERSION.SDK_INT >= 27) {
            context.getSystemService(NotificationManager::class.java)
                .isNotificationListenerAccessGranted(component)
        } else {
            NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)
        }
    }

    fun schedule(context: Context) {
        val request = PeriodicWorkRequestBuilder<NotificationListenerRepairWorker>(
            15,
            TimeUnit.MINUTES,
        ).build()
        WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
            PERIODIC_WORK,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    suspend fun repair(context: Context, forceComponentRefresh: Boolean = false): Boolean {
        val appContext = context.applicationContext
        if (!hasAccess(appContext)) return false
        if (NotificationListenerHealth.isConnected()) return true

        val component = ComponentName(appContext, UnutmaNotificationListenerService::class.java)
        requestRebind(component)
        if (awaitConnection()) return true

        val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val lastRefresh = prefs.getLong(LAST_REFRESH, 0L)
        if (!forceComponentRefresh && now - lastRefresh < REFRESH_COOLDOWN_MS) return false
        prefs.edit().putLong(LAST_REFRESH, now).apply()

        // requestRebind alone is ignored by some Xiaomi builds when the durable
        // permission remains enabled but the managed-service binding is stale.
        // Cycling this app-owned component makes NotificationManager rebuild the
        // binding without changing or silently granting notification access.
        runCatching {
            appContext.packageManager.setComponentEnabledSetting(
                component,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
            delay(250)
            appContext.packageManager.setComponentEnabledSetting(
                component,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )
        }.onFailure {
            runCatching {
                appContext.packageManager.setComponentEnabledSetting(
                    component,
                    PackageManager.COMPONENT_ENABLED_STATE_DEFAULT,
                    PackageManager.DONT_KILL_APP,
                )
            }
        }
        delay(250)
        if (!hasAccess(appContext)) return false
        requestRebind(component)
        return awaitConnection(15, 200)
    }

    private fun requestRebind(component: ComponentName) {
        runCatching { NotificationListenerService.requestRebind(component) }
    }

    private suspend fun awaitConnection(attempts: Int = 8, delayMs: Long = 150): Boolean {
        repeat(attempts) {
            if (NotificationListenerHealth.isConnected()) return true
            delay(delayMs)
        }
        return NotificationListenerHealth.isConnected()
    }
}

class NotificationListenerRepairWorker(
    context: Context,
    parameters: WorkerParameters,
) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        NotificationListenerBindingRepair.repair(applicationContext)
        return Result.success()
    }
}
