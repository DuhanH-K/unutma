package app.unutma.unutma.reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.work.*
import app.unutma.unutma.storage.CardEntity
import java.util.concurrent.TimeUnit

class ReminderScheduler(context:Context) {
    private val appContext=context.applicationContext
    private val work=WorkManager.getInstance(appContext)
    private val alarms=appContext.getSystemService(AlarmManager::class.java)
    fun cancel(card:CardEntity) {
        work.cancelAllWorkByTag("card_${card.id}").result.get()
        val slotIds=card.reminderOffsets.split(',').mapNotNull { it.toLongOrNull()?.toString() }+"snooze"
        slotIds.distinct().forEach { alarms.cancel(alarmIntent(card.id,it)) }
    }
    fun cancelAll() { work.cancelAllWorkByTag("unutma_reminder").result.get() }
    fun schedule(card:CardEntity,now:Long) {
        val slots=ReminderPlan.calculate(card.status,card.dueAt,card.reminderOffsets.split(',').mapNotNull { it.toLongOrNull() },card.snoozedUntil,now)
        slots.forEach { slot ->
            val request=OneTimeWorkRequestBuilder<ReminderWorker>()
                .setInputData(workDataOf("id" to card.id,"revision" to card.revision,"slot" to slot.id,"at" to slot.at))
                .setInitialDelay(slot.at-now,TimeUnit.MILLISECONDS)
                .addTag("unutma_reminder").addTag("card_${card.id}").build()
            work.enqueueUniqueWork("reminder_${card.id}_${card.revision}_${slot.id}",ExistingWorkPolicy.KEEP,request).result.get()
            // AlarmManager provides prompt local delivery on OEMs that heavily
            // defer WorkManager jobs. WorkManager remains a durable backup.
            runCatching {
                val pending=alarmIntent(card.id,slot.id,card.revision,slot.at)
                if(Build.VERSION.SDK_INT<Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()) {
                    alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,slot.at,pending)
                } else {
                    alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,slot.at,pending)
                }
            }
        }
    }
    private fun alarmIntent(id:String,slot:String,revision:Long=0,at:Long=0):PendingIntent {
        val intent=Intent(appContext,ReminderAlarmReceiver::class.java).apply {
            data=Uri.parse("unutma-internal://reminder/$id/$slot")
            putExtra("id",id);putExtra("revision",revision);putExtra("slot",slot);putExtra("at",at)
        }
        return PendingIntent.getBroadcast(appContext,0,intent,PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }
}
