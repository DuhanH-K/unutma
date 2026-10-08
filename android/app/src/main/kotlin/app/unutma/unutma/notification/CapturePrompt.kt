package app.unutma.unutma.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.unutma.unutma.R
import app.unutma.unutma.reminder.ReminderWorker
import app.unutma.unutma.storage.CardEntity
import app.unutma.unutma.storage.NativeRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

object CapturePromptNotifier {
    private const val CHANNEL_ID="capture_suggestions"
    private const val TAG="capture-suggestion"

    fun show(context:Context,card:CardEntity) {
        val manager=NotificationManagerCompat.from(context)
        if(!manager.areNotificationsEnabled()) return
        val localized=ReminderWorker.localized(context)
        manager.createNotificationChannel(NotificationChannel(
            CHANNEL_ID,
            localized.getString(R.string.suggestions),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply { description=localized.getString(R.string.suggestions_description) })
        if(manager.getNotificationChannel(CHANNEL_ID)?.importance==NotificationManager.IMPORTANCE_NONE) return
        val open=PendingIntent.getActivity(
            context,
            card.id.hashCode(),
            ReminderWorker.cardIntent(context,card.id),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val edit=PendingIntent.getActivity(
            context,
            card.id.hashCode() xor 0x45444954,
            ReminderWorker.cardIntent(context,card.id,edit=true),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder=NotificationCompat.Builder(localized,CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(localized.getString(R.string.app_name))
            .setContentText(localized.getString(R.string.suggestion_body))
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setCategory(NotificationCompat.CATEGORY_RECOMMENDATION)
            .setContentIntent(open)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
        if(card.dueAt!=null) builder.addAction(0,localized.getString(R.string.add),decision(context,card,"confirm"))
        builder.addAction(0,localized.getString(R.string.edit),edit)
        builder.addAction(0,localized.getString(R.string.ignore),decision(context,card,"ignore"))
        try { manager.notify(TAG,card.id.hashCode(),builder.build()) }
        catch (_:SecurityException) { /* Review remains available in the Inbox. */ }
    }

    /** Repeated identical previews must not create a second card, but a user
     *  who dismissed the suggestion still needs a visible recovery path. */
    fun showAgainIfMissing(context:Context,card:CardEntity) {
        val system=context.getSystemService(NotificationManager::class.java)
        val visible=runCatching {
            system.activeNotifications.any { it.tag==TAG && it.id==card.id.hashCode() }
        }.getOrDefault(false)
        if(!visible) show(context,card)
    }

    fun cancel(context:Context,id:String)=NotificationManagerCompat.from(context).cancel(TAG,id.hashCode())

    private fun decision(context:Context,card:CardEntity,action:String):PendingIntent {
        val intent=Intent(context,CaptureDecisionReceiver::class.java).apply {
            data=Uri.parse("unutma-internal://capture/${card.id}/${card.revision}/$action")
            putExtra("id",card.id)
            putExtra("revision",card.revision)
            putExtra("action",action)
        }
        return PendingIntent.getBroadcast(context,0,intent,PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }
}

class CaptureDecisionReceiver:BroadcastReceiver() {
    override fun onReceive(context:Context,intent:Intent) {
        val id=intent.getStringExtra("id") ?: return
        val action=intent.getStringExtra("action") ?: return
        if(action !in listOf("confirm","ignore")) return
        val revision=intent.getLongExtra("revision",0)
        val pending=goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try { NativeRepository.get(context).transition(id,action,revision) }
            catch (_:Exception) { /* The Inbox remains the recoverable path. */ }
            finally { CapturePromptNotifier.cancel(context,id);pending.finish() }
        }
    }
}
