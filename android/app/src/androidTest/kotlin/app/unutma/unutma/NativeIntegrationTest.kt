package app.unutma.unutma

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.unutma.unutma.storage.*
import app.unutma.unutma.security.PreviewCipher
import app.unutma.unutma.parser.*
import kotlinx.coroutines.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.time.ZoneId
import java.util.Locale
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.workDataOf
import app.unutma.unutma.reminder.ReminderWorker
import androidx.test.platform.app.InstrumentationRegistry
import android.app.NotificationManager
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.NotificationManagerCompat
import androidx.room.testing.MigrationTestHelper

@RunWith(AndroidJUnit4::class)
class NativeIntegrationTest {
    @get:Rule val migration=MigrationTestHelper(InstrumentationRegistry.getInstrumentation(),UnutmaDatabase::class.java)
    private val context=ApplicationProvider.getApplicationContext<Context>()
    private val repo=NativeRepository.get(context)
    @Before fun clean()=runBlocking(Dispatchers.IO) { repo.deleteAll() }
    @Test fun encryptedPreviewRoundTripAndTamper() {
        val cipher=PreviewCipher(); val one=cipher.encrypt("private preview","card");val two=cipher.encrypt("private preview","card")
        assertFalse(one.contentEquals(two));assertEquals("private preview",cipher.decrypt(one,"card"))
        assertThrows(Exception::class.java) {cipher.decrypt(one,"other")}
        one[one.lastIndex]=(one.last().toInt() xor 1).toByte()
        assertThrows(Exception::class.java) {cipher.decrypt(one,"card")}
        cipher.deleteKey()
    }
    @Test fun realPipelinePersistsDedupeTransitionsAndDelete()=runBlocking(Dispatchers.IO) {
        val raw=RawNotification("fixture.native","fixture-key","","Your appointment is tomorrow at 2:30 PM.",repo.time.now()+1,Locale.US,ZoneId.systemDefault())
        repo.ingest(raw,"Integration fixture")
        repo.ingest(raw,"Integration fixture")
        val card=repo.dao.all().single();assertEquals("ACTIVE",card.status);assertNotNull(card.encryptedPreview)
        assertFalse(String(card.encryptedPreview!!).contains("appointment"))
        repo.reconcile()
        repo.transition(card.id,"snooze",card.revision)
        val snoozed=repo.dao.get(card.id)!!;assertEquals("SNOOZED",snoozed.status)
        repo.transition(card.id,"done",card.revision)
        assertEquals("SNOOZED",repo.dao.get(card.id)!!.status)
        repo.transition(card.id,"done",snoozed.revision)
        assertEquals("DONE",repo.dao.get(card.id)!!.status);assertNull(repo.dao.get(card.id)!!.encryptedPreview)
        repo.deleteAll();assertTrue(repo.dao.all().isEmpty());assertTrue(repo.dao.sources().isEmpty())
        repo.ingest(raw,"Integration fixture");assertTrue(repo.dao.all().isEmpty())
    }
    @Test fun mediumCandidateDoesNotBecomeActiveWithoutConfirmation()=runBlocking(Dispatchers.IO) {
        repo.ingest(RawNotification("fixture.native","review-key","","Your appointment is confirmed",repo.time.now()+1,Locale.US,ZoneId.systemDefault()),"Test")
        val card=repo.dao.all().single();assertEquals("REVIEW",card.status)
        assertThrows(IllegalArgumentException::class.java) { runBlocking {repo.transition(card.id,"confirm",card.revision)} }
        Unit
    }
    @Test fun conversationalCandidateWaitsForExplicitConfirmation()=runBlocking(Dispatchers.IO) {
        repo.ingest(RawNotification("com.whatsapp","conversation-key","Erkek kardeşim","Abi yarın doğalgaz faturasını ödemeyi unutma 500 TL.",repo.time.now()+1,Locale.forLanguageTag("tr-TR"),ZoneId.systemDefault(),true),"WhatsApp")
        val card=repo.dao.all().single()
        assertEquals("REVIEW",card.status);assertEquals("500",card.amount);assertEquals("TRY",card.currency)
        assertEquals("Mesaj bildiriminden otomatik oluşturuldu.",card.note)
        assertEquals("Erkek kardeşim\nAbi yarın doğalgaz faturasını ödemeyi unutma 500 TL.",repo.all().single().sourceMessage)
        repo.clearSourceMessage(card.id)
        assertNull(repo.all().single().sourceMessage)
        repo.transition(card.id,"confirm",card.revision)
        assertEquals("ACTIVE",repo.dao.get(card.id)!!.status)
    }
    @Test fun explicitlySharedTextIsLocalReviewAndDeduplicated()=runBlocking(Dispatchers.IO) {
        val text="Abi yarın 750 TL doğalgaz ödemesi var"
        val first=repo.importSharedText(text)
        assertNotNull(first)
        val card=repo.dao.get(first!!)
        assertEquals("REVIEW",card?.status)
        assertEquals("app.unutma.share",card?.sourcePackage)
        assertEquals("750",card?.amount)
        assertEquals(first,repo.importSharedText(text))
        assertEquals(1,repo.dao.all().count { it.sourcePackage=="app.unutma.share" })
    }
    @Test fun exportedSchemaCanCreateAndValidateV1() {
        migration.createDatabase("schema-test",1).close()
        migration.runMigrationsAndValidate("schema-test",1,true).close()
    }
    @Test fun workerDeliversOnceAndRejectsStale()=runBlocking(Dispatchers.IO) {
        val instrumentation=InstrumentationRegistry.getInstrumentation()
        fun shell(command:String) { android.os.ParcelFileDescriptor.AutoCloseInputStream(instrumentation.uiAutomation.executeShellCommand(command)).use { it.readBytes() } }
        shell("pm grant ${context.packageName} android.permission.POST_NOTIFICATIONS")
        // Some production OEM builds deliberately deny GRANT_RUNTIME_PERMISSIONS
        // to adb shell. The dedicated denied-permission test still runs there;
        // exercise positive delivery only where the test runner can grant it.
        Assume.assumeTrue(
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED &&
                NotificationManagerCompat.from(context).areNotificationsEnabled()
        )
        val now=repo.time.now()
        val raw=RawNotification("fixture.worker","worker-key","","Your appointment is tomorrow at 2:30 PM.",now+1,Locale.US,ZoneId.systemDefault())
        repo.ingest(raw,"Test")
        val card=repo.dao.all().single()
        suspend fun fire(revision:Long,slot:String) {
            val worker=TestListenableWorkerBuilder<ReminderWorker>(context).setInputData(workDataOf("id" to card.id,"revision" to revision,"slot" to slot,"at" to now)).build()
            worker.doWork()
        }
        fire(card.revision,"test")
        assertEquals(1,repo.dao.delivered(card.id,card.revision,"test"))
        fire(card.revision,"test")
        assertEquals(1,repo.dao.delivered(card.id,card.revision,"test"))
        fire(card.revision-1,"stale")
        assertEquals(0,repo.dao.delivered(card.id,card.revision-1,"stale"))
        assertTrue(context.getSystemService(NotificationManager::class.java).activeNotifications.any {it.id==card.id.hashCode()})
        repo.transition(card.id,"done",card.revision)
        assertFalse(context.getSystemService(NotificationManager::class.java).activeNotifications.any {it.id==card.id.hashCode()})
        repo.deleteAll()
    }
}
