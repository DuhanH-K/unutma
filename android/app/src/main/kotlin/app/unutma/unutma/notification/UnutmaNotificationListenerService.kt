package app.unutma.unutma.notification

import android.app.Notification
import android.content.ComponentName
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import app.unutma.unutma.BuildConfig
import app.unutma.unutma.parser.RawNotification
import app.unutma.unutma.storage.NativeRepository
import kotlinx.coroutines.*
import java.time.ZoneId
import java.util.Locale

object NotificationEligibility {
    fun eligible(
        flags:Int,
        category:String?,
        hasProgress:Boolean,
        own:Boolean,
        conversational:Boolean=false,
    ):Boolean {
        val alwaysBlocked=Notification.FLAG_ONGOING_EVENT or Notification.FLAG_FOREGROUND_SERVICE
        val isGroupSummary=flags and Notification.FLAG_GROUP_SUMMARY!=0
        return !own && !hasProgress && flags and alwaysBlocked==0 &&
            (!isGroupSummary || conversational) &&
            category !in listOf(Notification.CATEGORY_TRANSPORT,Notification.CATEGORY_PROGRESS,Notification.CATEGORY_SYSTEM,Notification.CATEGORY_SERVICE)
    }
}
object MessagingNotificationDetector {
    private val knownMessagingPackages = setOf(
        "com.whatsapp",
        "com.whatsapp.w4b",
        "com.google.android.apps.messaging",
        "com.samsung.android.messaging",
        "com.facebook.orca",
        "com.instagram.android",
        "org.telegram.messenger",
        "org.thoughtcrime.securesms",
        "com.discord",
        "jp.naver.line.android",
    )

    fun isConversational(
        sourcePackage: String,
        category: String?,
        hasMessagingStyleMessages: Boolean,
        hasMessagingPerson: Boolean,
    ): Boolean = category == Notification.CATEGORY_MESSAGE ||
        hasMessagingStyleMessages ||
        hasMessagingPerson ||
        sourcePackage in knownMessagingPackages
}
object MessagingGroupSummaryPreview {
    private val directionMarks=Regex("[\u200E\u200F\u202A-\u202E\u2066-\u2069]")
    private val senderAndBody=Regex("^(.{1,120}?):\\s+(.+)$")

    fun split(line:String?):Pair<String,String>? {
        val clean=line?.let { directionMarks.replace(it,"") }?.trim().orEmpty()
        if(clean.isBlank()) return null
        val match=senderAndBody.matchEntire(clean)
        return if(match==null) "" to clean
        else match.groupValues[1].trim().take(120) to match.groupValues[2].trim().take(4096)
    }
}
object NotificationListenerHealth {
    @Volatile private var connected=false
    fun isConnected():Boolean=connected
    internal fun update(value:Boolean) { connected=value }
}
class UnutmaNotificationListenerService:NotificationListenerService() {
    private val scope=CoroutineScope(SupervisorJob()+Dispatchers.IO)
    override fun onNotificationPosted(sbn:StatusBarNotification?) {
        if(sbn==null) return
        if (BuildConfig.DEBUG) Log.d("UnutmaCapture", "notification_received")
        // The boundary includes extras/parcel access: malformed notifications cannot kill the listener.
        val raw=runCatching {
            val n=sbn.notification
            // Some WhatsApp/OEM combinations omit CATEGORY_MESSAGE and
            // MessagingStyle extras even though the visible notification is a
            // message preview. Package recognition keeps those previews on the
            // explicit review path instead of silently creating an active card.
            val conversational=MessagingNotificationDetector.isConversational(
                sbn.packageName,
                n.category,
                n.extras.containsKey(Notification.EXTRA_MESSAGES),
                n.extras.containsKey(Notification.EXTRA_MESSAGING_PERSON),
            )
            // WhatsApp updates only the group-summary notification on some OEM
            // builds. Keep summaries from recognized messaging apps long enough
            // to extract the latest preview. Generic summaries such as
            // "3 yeni mesaj" are still rejected by ConversationSummaryDetector.
            if(!NotificationEligibility.eligible(
                    n.flags,
                    n.category,
                    n.extras.getInt(Notification.EXTRA_PROGRESS_MAX,0)>0,
                    sbn.packageName==packageName,
                    conversational,
                )) return
            val isGroupSummary=n.flags and Notification.FLAG_GROUP_SUMMARY!=0
            val rawTitle=n.extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty().take(512)
            val latestMessage=if(conversational) {
                runCatching {
                    Notification.MessagingStyle.Message
                        .getMessagesFromBundleArray(n.extras.getParcelableArray(Notification.EXTRA_MESSAGES))
                        .lastOrNull()?.text?.toString()
                }.getOrNull()
            } else null
            val latestLine=n.extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.lastOrNull()?.toString()
            // WhatsApp group summaries prefix each preview with "sender: ".
            // Select only the newest line and remove that prefix so the same
            // message delivered as a child notification has the same
            // fingerprint and is stored once.
            val summaryPreview=if(isGroupSummary) MessagingGroupSummaryPreview.split(latestLine) else null
            val title=(summaryPreview?.first?.takeIf { it.isNotBlank() } ?: rawTitle).take(512)
            val text=(latestMessage ?: summaryPreview?.second
                ?: n.extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
                ?: latestLine ?: n.extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()).orEmpty().take(4096)
            if(title.isBlank() && text.isBlank()) return
            RawNotification(sbn.packageName,sbn.key,title,text,sbn.postTime,Locale.getDefault(),ZoneId.systemDefault(),conversational)
        }.getOrNull() ?: return
        scope.launch {
            try {
                val label=runCatching { packageManager.getApplicationLabel(packageManager.getApplicationInfo(raw.source,0)).toString().take(120) }.getOrDefault("")
                val inserted=NativeRepository.get(applicationContext).ingest(raw,label)
                if (BuildConfig.DEBUG) Log.d("UnutmaCapture", if(inserted) "card_inserted" else "notification_rejected")
            } catch (error: Exception) {
                // Debug builds expose only the exception type, never notification content or messages.
                if (BuildConfig.DEBUG) Log.e("UnutmaCapture", error.javaClass.simpleName)
            }
        }
    }
    override fun onListenerConnected() {
        super.onListenerConnected()
        NotificationListenerHealth.update(true)
        if (BuildConfig.DEBUG) Log.d("UnutmaCapture", "listener_connected")
        scope.launch {
            runCatching { NativeRepository.get(applicationContext).reconcile() }
            // Android does not replay posts that occurred while an OEM had the
            // listener unbound. Re-evaluate the currently visible previews;
            // repository fingerprints keep this idempotent.
            runCatching { activeNotifications.orEmpty().sortedBy { it.postTime }.forEach(::onNotificationPosted) }
        }
    }
    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        NotificationListenerHealth.update(false)
        if (BuildConfig.DEBUG) Log.d("UnutmaCapture", "listener_disconnected")
        // The permission may still be enabled even when the system binding disappears.
        runCatching { requestRebind(ComponentName(this,UnutmaNotificationListenerService::class.java)) }
    }
    override fun onDestroy() {
        NotificationListenerHealth.update(false)
        scope.cancel()
        super.onDestroy()
    }
}
