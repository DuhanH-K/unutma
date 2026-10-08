package app.unutma.unutma

import android.content.Context
import android.Manifest
import android.content.pm.PackageManager
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.workDataOf
import app.unutma.unutma.storage.NativeRepository
import app.unutma.unutma.parser.RawNotification
import app.unutma.unutma.reminder.ReminderWorker
import kotlinx.coroutines.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.time.ZoneId
import java.util.Locale

@RunWith(AndroidJUnit4::class)
class ReminderPermissionTest {
    @Test fun deniedPermissionLeavesCardAndDoesNotPost()=runBlocking(Dispatchers.IO) {
        val context=ApplicationProvider.getApplicationContext<Context>()
        Assume.assumeTrue(context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_DENIED)
        val repo=NativeRepository.get(context);repo.deleteAll()
        repo.ingest(RawNotification("fixture.denied","denied-key","","Payment due tomorrow",repo.time.now()+1,Locale.US,ZoneId.systemDefault()),"Test")
        val card=repo.dao.all().single()
        val worker=TestListenableWorkerBuilder<ReminderWorker>(context).setInputData(workDataOf("id" to card.id,"revision" to card.revision,"slot" to "denied","at" to repo.time.now())).build()
        worker.doWork()
        assertEquals(0,repo.dao.delivered(card.id,card.revision,"denied"));assertEquals("ACTIVE",repo.dao.get(card.id)?.status)
        repo.deleteAll()
    }
}
