package app.unutma.unutma.reminder

import android.app.*
import android.content.*
import android.content.res.Configuration
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.*
import app.unutma.unutma.MainActivity
import app.unutma.unutma.R
import app.unutma.unutma.storage.*
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.withLock
import java.util.Locale

class ReminderWorker(context:Context,params:WorkerParameters):CoroutineWorker(context,params) {
    override suspend fun doWork():Result = withContext(Dispatchers.IO) {
        try {
            val id=inputData.getString("id") ?: return@withContext Result.failure()
            val revision=inputData.getLong("revision",0)
            val slot=inputData.getString("slot") ?: return@withContext Result.failure()
            val at=inputData.getLong("at",0)
            ReminderDelivery.deliver(applicationContext,id,revision,slot,at)
            Result.success()
        } catch (_: SecurityException) { Result.success() }
        catch (_: Exception) { if(runAttemptCount<3) Result.retry() else Result.failure() }
    }
    companion object {
        fun cardIntent(context:Context,id:String,edit:Boolean=false)=Intent(context,MainActivity::class.java).apply {
            // Flutter must not interpret this internal navigation request as a URL route.
            action="${context.packageName}.${if(edit) "EDIT_CARD" else "OPEN_CARD"}"
            putExtra("cardId",id)
            putExtra("editCard",edit)
            flags=Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        fun localized(context:Context):Context {
            val language=context.getSharedPreferences("preferences",Context.MODE_PRIVATE).getString("language","").orEmpty()
            if(language.isEmpty()) return context
            return context.createConfigurationContext(Configuration(context.resources.configuration).apply { setLocale(Locale.forLanguageTag(language)) })
        }
        fun action(context:Context,id:String,revision:Long,action:String):PendingIntent {
            val intent=Intent(context,ReminderActionReceiver::class.java).apply {
                data=Uri.parse("unutma-internal://action/$id/$revision/$action")
                putExtra("id",id); putExtra("revision",revision); putExtra("action",action)
            }
            return PendingIntent.getBroadcast(context,0,intent,PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
    }
}
object ReminderDelivery {
    const val CHANNEL_ID="reminders_v2"

    suspend fun deliver(context:Context,id:String,revision:Long,slot:String,at:Long) {
        val repo=NativeRepository.get(context)
        repo.mutex.withLock {
            val card=repo.dao.get(id) ?: return@withLock
            if(card.revision!=revision || card.status !in listOf("ACTIVE","SNOOZED")) return@withLock
            val now=repo.time.now()
            // Neither WorkManager nor AlarmManager should ever consume a reminder before its time.
            if(now<at) return@withLock
            if(repo.dao.delivered(id,revision,slot)>0) return@withLock
            if(now-at>ReminderPlan.MAX_LATE_MILLIS) return@withLock
            val manager=NotificationManagerCompat.from(context)
            if(!manager.areNotificationsEnabled()) return@withLock
            val ctx=ReminderWorker.localized(context)
            val channel=NotificationChannel(CHANNEL_ID,ctx.getString(R.string.reminders),NotificationManager.IMPORTANCE_HIGH)
            channel.description=ctx.getString(R.string.reminders_description)
            channel.enableVibration(true)
            channel.setShowBadge(true)
            manager.createNotificationChannel(channel)
            if(manager.getNotificationChannel(CHANNEL_ID)?.importance==NotificationManager.IMPORTANCE_NONE) return@withLock
            val pending=PendingIntent.getActivity(context,id.hashCode(),ReminderWorker.cardIntent(context,id),PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            // Lock screen and notification shade never reveal raw content, amounts or merchant details.
            val body=ctx.getString(R.string.reminder_body)
            val publicVersion=NotificationCompat.Builder(ctx,CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(ctx.getString(R.string.app_name))
                .setContentText(ctx.getString(R.string.reminder_private_body))
                .build()
            val notification=NotificationCompat.Builder(ctx,CHANNEL_ID).setSmallIcon(R.drawable.ic_notification)
                // Match the compact, proven suggestion notification: one brand icon,
                // short title and a body that fits narrow Xiaomi notification cards.
                .setContentTitle(ctx.getString(R.string.app_name)).setContentText(ctx.getString(R.string.reminder_compact_body))
                .setStyle(NotificationCompat.BigTextStyle().bigText(body).setBigContentTitle(ctx.getString(R.string.reminder_title)).setSummaryText(ctx.getString(R.string.reminder_summary)))
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE).setPublicVersion(publicVersion)
                .setCategory(NotificationCompat.CATEGORY_REMINDER).setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL).setContentIntent(pending).setAutoCancel(true)
                .addAction(R.drawable.ic_done,ctx.getString(R.string.done),ReminderWorker.action(context,id,revision,"done"))
                .addAction(R.drawable.ic_snooze,ctx.getString(R.string.snooze),ReminderWorker.action(context,id,revision,"snooze"))
                .build()
            manager.notify(id.hashCode(),notification)
            repo.dao.receipt(ReminderReceipt(id,revision,slot))
            if(card.status=="SNOOZED") repo.dao.put(card.copy(status="ACTIVE",snoozedUntil=null))
        }
    }
}
object ReminderPreview {
    private const val PREVIEW_ID=2099001

    fun show(context:Context) {
        val manager=NotificationManagerCompat.from(context)
        if(!manager.areNotificationsEnabled()) return
        val ctx=ReminderWorker.localized(context)
        manager.createNotificationChannel(NotificationChannel(
            ReminderDelivery.CHANNEL_ID,
            ctx.getString(R.string.reminders),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description=ctx.getString(R.string.reminders_description)
            enableVibration(true)
            setShowBadge(true)
        })
        val open=PendingIntent.getActivity(
            context,
            PREVIEW_ID,
            Intent(context,MainActivity::class.java).apply {
                flags=Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val body=ctx.getString(R.string.reminder_body)
        val notification=NotificationCompat.Builder(ctx,ReminderDelivery.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(ctx.getString(R.string.app_name))
            .setContentText(ctx.getString(R.string.reminder_compact_body))
            .setStyle(NotificationCompat.BigTextStyle()
                .setBigContentTitle(ctx.getString(R.string.reminder_title))
                .bigText(body)
                .setSummaryText(ctx.getString(R.string.reminder_summary)))
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        runCatching { manager.notify(PREVIEW_ID,notification) }
    }
}
class ReminderAlarmReceiver:BroadcastReceiver() {
    override fun onReceive(context:Context,intent:Intent) {
        val id=intent.getStringExtra("id") ?: return
        val slot=intent.getStringExtra("slot") ?: return
        val revision=intent.getLongExtra("revision",0)
        val at=intent.getLongExtra("at",0)
        val pending=goAsync()
        CoroutineScope(SupervisorJob()+Dispatchers.IO).launch {
            try { ReminderDelivery.deliver(context.applicationContext,id,revision,slot,at) }
            catch (_:Exception) { /* WorkManager remains the retrying backup. */ }
            finally { pending.finish() }
        }
    }
}
class ReminderActionReceiver:BroadcastReceiver() {
    override fun onReceive(context:Context,intent:Intent) {
        val id=intent.getStringExtra("id") ?: return
        val action=intent.getStringExtra("action") ?: return
        if(action !in listOf("done","snooze")) return
        val revision=intent.getLongExtra("revision",0)
        val pending=goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try { NativeRepository.get(context).transition(id,action,revision) }
            catch (_: Exception) { /* Retryable from the card UI; never expose source content. */ }
            finally { pending.finish() }
        }
    }
}
