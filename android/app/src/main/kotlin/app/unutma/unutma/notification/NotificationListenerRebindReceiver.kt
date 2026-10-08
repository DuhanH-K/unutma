package app.unutma.unutma.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.AlarmManager
import android.util.Log
import app.unutma.unutma.BuildConfig
import app.unutma.unutma.storage.NativeRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/** Repairs OEM notification-listener bindings after an update or restart. */
class NotificationListenerRebindReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action !in supportedActions) return
        val pendingResult = goAsync()
        val appContext = context.applicationContext
        CoroutineScope(SupervisorJob() + Dispatchers.Default).launch {
            try {
                NotificationListenerBindingRepair.schedule(appContext)
                NotificationListenerBindingRepair.repair(
                    appContext,
                    forceComponentRefresh = action == Intent.ACTION_MY_PACKAGE_REPLACED,
                )
                if (BuildConfig.DEBUG) Log.d("UnutmaCapture", "rebind_requested")
                runCatching { NativeRepository.get(appContext).reconcile() }
            } finally {
                pendingResult.finish()
            }
        }
    }

    private companion object {
        val supportedActions = setOf(
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_USER_UNLOCKED,
            AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED,
        )
    }
}
