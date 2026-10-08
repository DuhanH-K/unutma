package app.unutma.unutma

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import app.unutma.unutma.storage.NativeRepository
import kotlinx.coroutines.*
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith

/** Explicit device scenario: tools/device-test.ps1 posts the notification first. */
@RunWith(AndroidJUnit4::class)
class BackgroundCaptureTest {
    @Test fun systemPostedNotificationPersistedWithoutFlutter()=runBlocking(Dispatchers.IO) {
        org.junit.Assume.assumeTrue(androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("backgroundScenario")=="true")
        val context=ApplicationProvider.getApplicationContext<Context>()
        val cards=NativeRepository.get(context).dao.all()
        assertTrue(cards.any {it.sourcePackage=="com.android.shell"&&it.category=="PAYMENT_DUE"&&it.status=="ACTIVE"})
    }
}
