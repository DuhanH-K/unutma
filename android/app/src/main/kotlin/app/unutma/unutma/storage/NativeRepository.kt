package app.unutma.unutma.storage

import android.content.Context
import android.app.NotificationManager
import androidx.room.withTransaction
import app.unutma.unutma.R
import app.unutma.unutma.bridge.CardDto
import app.unutma.unutma.parser.*
import app.unutma.unutma.security.PreviewCipher
import app.unutma.unutma.reminder.*
import app.unutma.unutma.notification.CapturePromptNotifier
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.UUID
import java.time.ZoneId
import java.util.Locale

class NativeRepository private constructor(private val context:Context) {
    val db=UnutmaDatabase.get(context)
    val dao=db.cards()
    val time=TimeProvider()
    val mutex=Mutex()
    private val cipher=PreviewCipher()
    private val scheduler=ReminderScheduler(context)
    private val prefs=context.getSharedPreferences("preferences",Context.MODE_PRIVATE)
    private data class IngestOutcome(val id:String,val inserted:Boolean)
    suspend fun ingest(raw:RawNotification,label:String):Boolean = mutex.withLock {
        ingestLocked(raw,label,honorIgnored=true,showPrompt=true)?.inserted==true
    }
    suspend fun importSharedText(text:String):String? = mutex.withLock {
        val clean=text.replace("\u0000","").trim().take(4096)
        require(clean.isNotBlank())
        val now=time.now()
        val raw=RawNotification(
            "app.unutma.share",
            "share:${DuplicateDetector.hash(clean)}",
            "",
            clean,
            now,
            Locale.getDefault(),
            ZoneId.systemDefault(),
            true,
        )
        val localized=ReminderWorker.localized(context)
        ingestLocked(raw,localized.getString(R.string.shared_content),honorIgnored=false,showPrompt=false)?.id
    }
    private suspend fun ingestLocked(raw:RawNotification,label:String,honorIgnored:Boolean,showPrompt:Boolean):IngestOutcome? {
        if(raw.postedAt<=prefs.getLong("deletedAt",0) || (honorIgnored && dao.source(raw.source)?.ignored==true)) return null
        val parsed=RuleEngine().parse(raw) ?: return null
        val now=time.now()
        val id=UUID.randomUUID().toString()
        // Preview encryption failure drops the optional preview; plaintext is never persisted.
        // Include the notification title when it identifies the sender (for example WhatsApp).
        val sourceMessage=listOf(raw.title.trim(),raw.text.trim()).filter { it.isNotBlank() }.distinct().joinToString("\n").take(ParserConfig.PREVIEW_LIMIT)
        val preview=sourceMessage.takeIf { it.isNotBlank() }?.let { runCatching { cipher.encrypt(it,id) }.getOrNull() }
        val review=raw.requiresConfirmation || parsed.review || (parsed.date.instant?.let { it<now } ?: true)
        val localized=ReminderWorker.localized(context)
        val note=listOfNotNull(
            parsed.temporalContext?.trim()?.takeIf { it.isNotEmpty() },
            localized.getString(R.string.automatic_message_note)
                .takeIf { raw.requiresConfirmation && raw.source!="app.unutma.share" },
        ).distinct().joinToString(" • ").take(500).ifEmpty { null }
        val card=CardEntity(id,parsed.category.name,parsed.title,label,raw.source,parsed.date.instant,
            parsed.entities.amount,parsed.entities.currency,if(review)"REVIEW" else "ACTIVE",parsed.confidence,now,
            reminderOffsets=(if(prefs.contains("reminderMinutes"))listOf(prefs.getLong("reminderMinutes",1440)) else ReminderPlan.defaults(parsed.category.name)).joinToString(","),
            parserVersion=ParserConfig.VERSION,note=note,fingerprint=parsed.fingerprint,keyHash=parsed.keyHash,encryptedPreview=preview)
        val outcome=db.withTransaction {
            val duplicate=dao.duplicate(parsed.keyHash,parsed.fingerprint,now-ParserConfig.DEDUPE_TTL)
            if(duplicate!=null) IngestOutcome(duplicate.id,false)
            else {
                dao.put(card)
                if(dao.source(raw.source)==null) dao.putSource(SourceEntity(raw.source,label))
                IngestOutcome(card.id,true)
            }
        }
        if(outcome.inserted) {
            scheduler.schedule(card,now)
            if(showPrompt && card.status=="REVIEW") CapturePromptNotifier.show(context,card)
        } else if(showPrompt) {
            dao.get(outcome.id)?.takeIf { it.status=="REVIEW" }
                ?.let { CapturePromptNotifier.showAgainIfMissing(context,it) }
        }
        retention(now)
        return outcome
    }
    suspend fun all():List<CardDto> = mutex.withLock { retention(time.now()); dao.all().map { it.dto() } }
    suspend fun save(dto:CardDto):CardDto = mutex.withLock {
        require(dto.title.length<=120 && dto.note.orEmpty().length<=500 && dto.amount.orEmpty().length<=24)
        require(dto.currency==null || dto.currency in listOf("TRY","USD","EUR","GBP"))
        require(dto.amount==null || Regex("[0-9]+([.,][0-9]{1,2})?").matches(dto.amount))
        val category=Category.valueOf(dto.category)
        require(dto.reminderOffsets.size<=5 && dto.reminderOffsets.all { it in 0..525600 })
        val old=if(dto.id.isBlank()) null else dao.get(dto.id) ?: error("missing")
        if(old!=null) { require(old.revision==dto.revision); require(old.status in listOf("ACTIVE","REVIEW","SNOOZED")) }
        require(dto.dueAt!=null)
        val now=time.now()
        val id=old?.id ?: UUID.randomUUID().toString()
        val card=CardEntity(id,category.name,dto.title.trim(),old?.sourceLabel ?: "",old?.sourcePackage ?: "",dto.dueAt,dto.amount,dto.currency,
            if(old?.status=="REVIEW")"REVIEW" else "ACTIVE",old?.confidence ?: 1.0,old?.createdAt ?: now,
            reminderOffsets=dto.reminderOffsets.distinct().joinToString(","),parserVersion=old?.parserVersion ?: ParserConfig.VERSION,
            note=dto.note?.trim(),revision=(old?.revision ?: 0)+1,fingerprint=old?.fingerprint ?: DuplicateDetector.hash(id),keyHash=old?.keyHash ?: DuplicateDetector.hash(id),encryptedPreview=old?.encryptedPreview)
        dao.put(card)
        old?.let { scheduler.cancel(it) }
        scheduler.schedule(card,now)
        card.dto()
    }
    suspend fun transition(id:String,action:String,revision:Long) = mutex.withLock {
        val card=dao.get(id) ?: return@withLock
        if(card.revision!=revision) return@withLock
        val now=time.now()
        val next=when(action) {
            "confirm" -> { require(card.status=="REVIEW" && card.dueAt!=null); card.copy(status="ACTIVE") }
            "ignore" -> { require(card.status=="REVIEW"); card.copy(status="ARCHIVED",completedAt=now,encryptedPreview=null) }
            "done" -> { if(card.status !in listOf("ACTIVE","SNOOZED")) return@withLock; card.copy(status="DONE",completedAt=now,encryptedPreview=null) }
            "archive" -> { require(card.status in listOf("ACTIVE","SNOOZED")); card.copy(status="ARCHIVED",completedAt=now,encryptedPreview=null) }
            "snooze" -> { require(card.status in listOf("ACTIVE","SNOOZED")); card.copy(status="SNOOZED",snoozedUntil=now+ReminderPlan.SNOOZE_MILLIS) }
            else -> error("invalid_action")
        }.copy(revision=card.revision+1)
        dao.put(next)
        context.getSystemService(NotificationManager::class.java).cancel(id.hashCode())
        CapturePromptNotifier.cancel(context,id)
        scheduler.cancel(card)
        scheduler.schedule(next,now)
    }
    suspend fun clearSourceMessage(id:String)=mutex.withLock { dao.clearPreview(id) }
    suspend fun setIgnored(pkg:String,ignored:Boolean)=mutex.withLock {
        require(pkg.length in 1..255)
        val old=dao.source(pkg) ?: error("missing_source")
        dao.putSource(old.copy(ignored=ignored))
    }
    suspend fun deleteAll()=mutex.withLock {
        // Blocks in-flight ingestion and rejects already-posted payloads queued before deletion.
        val onboarded=prefs.getBoolean("onboarded",false)
        prefs.edit().clear().putBoolean("onboarded",onboarded).putLong("deletedAt",time.now()).commit()
        dao.all().forEach { scheduler.cancel(it) }
        scheduler.cancelAll()
        context.getSystemService(NotificationManager::class.java).cancelAll()
        db.openHelper.writableDatabase.query("PRAGMA secure_delete=ON").use { it.moveToFirst() }
        db.withTransaction { dao.clearReceipts(); dao.clearCards(); dao.clearSources() }
        db.openHelper.writableDatabase.query("PRAGMA wal_checkpoint(TRUNCATE)").use { it.moveToFirst() }
        db.openHelper.writableDatabase.execSQL("VACUUM")
        cipher.deleteKey()
    }
    suspend fun reconcile()=mutex.withLock {
        val now=time.now(); retention(now)
        dao.all().forEach { card ->
            if(card.status in listOf("ACTIVE","SNOOZED")) {
                // A future slot cannot legitimately have been delivered. Repair any receipt
                // left by a clock change or an externally forced WorkManager diagnostic run.
                ReminderPlan.calculate(card.status,card.dueAt,card.reminderOffsets.split(',').mapNotNull { it.toLongOrNull() },card.snoozedUntil,now)
                    .filter { it.at>now }
                    .forEach { dao.forgetDelivery(card.id,card.revision,it.id) }
                scheduler.schedule(card,now)
            } else scheduler.cancel(card)
        }
    }
    private suspend fun retention(now:Long) { dao.purgeHistory(now-ParserConfig.HISTORY_RETENTION); dao.purgeReceipts() }
    private fun CardEntity.dto():CardDto {
        val sourceMessage=encryptedPreview?.let { encrypted ->
            runCatching { cipher.decrypt(encrypted,id) }.getOrNull()
        }
        return CardDto(id,category,title,sourceLabel,sourcePackage,dueAt,amount,currency,status,confidence,createdAt,completedAt,reminderOffsets.split(',').mapNotNull { it.toLongOrNull() },snoozedUntil,parserVersion.toLong(),note,sourceMessage,revision)
    }
    companion object {
        @Volatile private var instance:NativeRepository?=null
        fun get(context:Context)=instance ?: synchronized(this) { instance ?: NativeRepository(context.applicationContext).also { instance=it } }
    }
}
