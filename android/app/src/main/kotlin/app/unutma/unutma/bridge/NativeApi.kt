package app.unutma.unutma.bridge

import android.Manifest
import android.app.Activity
import android.content.*
import android.os.Build
import android.provider.Settings
import android.app.NotificationManager
import android.app.AlarmManager
import android.net.Uri
import androidx.core.app.NotificationManagerCompat
import app.unutma.unutma.notification.NotificationListenerHealth
import app.unutma.unutma.notification.NotificationListenerBindingRepair
import app.unutma.unutma.notification.UnutmaNotificationListenerService
import app.unutma.unutma.reminder.ReminderDelivery
import app.unutma.unutma.storage.NativeRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class NativeApi(private val activity:Activity,private val opened:()->String?,private val shared:()->String?):UnutmaApi {
    private val prefs=activity.getSharedPreferences("preferences",Context.MODE_PRIVATE)
    private suspend fun <T> io(block:suspend (NativeRepository)->T):T = withContext(Dispatchers.IO) {
        try { block(NativeRepository.get(activity)) }
        catch (_: IllegalArgumentException) { throw FlutterError("invalid_input","Invalid input") }
        catch (_: Exception) { throw FlutterError("storage_failure","Local operation failed") }
    }
    override suspend fun getCards()=io { it.all() }
    override suspend fun saveCard(card:CardDto)=io { it.save(card) }
    override suspend fun transition(id:String,action:String,revision:Long)=io { it.transition(id,action,revision) }
    override suspend fun clearSourceMessage(id:String)=io { it.clearSourceMessage(id) }
    override suspend fun deleteAllData()=io { it.deleteAll() }
    override suspend fun getSources()=io { it.dao.sources().map { s->SourceDto(s.packageName,s.label,s.ignored) } }
    override suspend fun setSourceIgnored(packageName:String,ignored:Boolean)=io { it.setIgnored(packageName,ignored) }
    override suspend fun reconcile()=io { it.reconcile() }
    override suspend fun getAccess():AccessDto {
        val manager=activity.getSystemService(NotificationManager::class.java)
        val granted=NotificationListenerBindingRepair.hasAccess(activity)
        if(granted && !NotificationListenerHealth.isConnected()) {
            NotificationListenerBindingRepair.repair(activity)
        }
        // Android can grant access before binding the listener process. The
        // permission UI must reflect the durable system grant, while the
        // best-effort rebind above repairs a delayed/detached service.
        return AccessDto(granted,remindersEnabled(manager))
    }
    override fun openNotificationAccess() {
        val component=ComponentName(activity,UnutmaNotificationListenerService::class.java)
        val intent=if(Build.VERSION.SDK_INT>=30) Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,component.flattenToString()) else Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        if(Build.VERSION.SDK_INT>=33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED) {
            // MainActivity asks after the user returns from notification-access
            // settings. Requesting while this Activity is losing focus is ignored
            // by several Android/OEM versions.
            prefs.edit().putBoolean("requestNotificationsAfterAccess",true).apply()
        }
        try { activity.startActivity(intent) } catch (_: ActivityNotFoundException) { activity.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)) }
    }
    override fun requestReminderPermission() {
        if(Build.VERSION.SDK_INT>=33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED) {
            activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),43)
        } else if(Build.VERSION.SDK_INT>=Build.VERSION_CODES.S &&
            !activity.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()) {
            val intent=Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                .setData(Uri.parse("package:${activity.packageName}"))
            try { activity.startActivity(intent) }
            catch (_:ActivityNotFoundException) {
                activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    .setData(Uri.parse("package:${activity.packageName}")))
            }
        } else if(!remindersEnabled(activity.getSystemService(NotificationManager::class.java))) {
            activity.startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE,activity.packageName))
        }
    }
    private fun remindersEnabled(manager:NotificationManager):Boolean {
        val notificationsEnabled=NotificationManagerCompat.from(activity).areNotificationsEnabled() &&
            manager.getNotificationChannel(ReminderDelivery.CHANNEL_ID)?.importance!=NotificationManager.IMPORTANCE_NONE
        val exactAlarmEnabled=Build.VERSION.SDK_INT<Build.VERSION_CODES.S ||
            activity.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()
        return notificationsEnabled && exactAlarmEnabled
    }
    override fun getPreferences()=PreferencesDto(prefs.getBoolean("onboarded",false),prefs.getString("language","").orEmpty(),prefs.getString("theme","system") ?: "system",prefs.getLong("reminderMinutes",1440))
    override fun setPreferences(preferences:PreferencesDto) {
        require(preferences.language in listOf("","tr","en") && preferences.theme in listOf("system","light","dark") && preferences.reminderMinutes in 0..525600)
        prefs.edit().putBoolean("onboarded",preferences.onboarded).putString("language",preferences.language).putString("theme",preferences.theme).putLong("reminderMinutes",preferences.reminderMinutes).apply()
    }
    override fun takeOpenedCard()=opened()
    override fun takeSharedText()=shared()
    override suspend fun importSharedText(text:String)=io { it.importSharedText(text) }
}
