package app.unutma.unutma

import android.content.ComponentName
import android.content.Context
import android.service.notification.NotificationListenerService
import android.os.PowerManager
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import app.unutma.unutma.notification.UnutmaNotificationListenerService
import app.unutma.unutma.storage.CardEntity
import app.unutma.unutma.storage.NativeRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.After
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.time.LocalDate
import java.time.ZoneId

/**
 * Produces truthful store/website screenshots from the real Flutter UI while
 * keeping the user's production data untouched (run with app.unutma.qa).
 */
@RunWith(AndroidJUnit4::class)
class StoreScreenshotCaptureTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = ApplicationProvider.getApplicationContext<Context>()
    private val device = UiDevice.getInstance(instrumentation)
    private val repo = NativeRepository.get(context)
    private lateinit var outputDir: File
    private var wakeLock: PowerManager.WakeLock? = null

    @Before
    fun prepareFixture() = runBlocking {
        withContext(Dispatchers.IO) {
            repo.deleteAll()
            context.getSharedPreferences("preferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("onboarded", true)
                .putString("language", "tr")
                .putString("theme", "dark")
                .putLong("reminderMinutes", 1440)
                .commit()

            val zone = ZoneId.systemDefault()
            val now = System.currentTimeMillis()
            fun at(dayOffset: Long, hour: Int, minute: Int = 0) =
                LocalDate.now(zone).plusDays(dayOffset).atTime(hour, minute)
                    .atZone(zone).toInstant().toEpochMilli()

            val cards = listOf(
                CardEntity(
                    id = "store-gas",
                    category = "BILL",
                    title = "Doğalgaz faturası",
                    sourceLabel = "Mesajlar",
                    sourcePackage = "com.google.android.apps.messaging",
                    dueAt = at(1, 18),
                    amount = "1248.90",
                    currency = "TRY",
                    status = "ACTIVE",
                    confidence = 0.98,
                    createdAt = now - 20_000,
                    reminderOffsets = "1440,60",
                    note = "Son ödeme tarihinden 1 gün önce hatırlat.",
                    fingerprint = "store-gas",
                    keyHash = "store-gas",
                ),
                CardEntity(
                    id = "store-appointment",
                    category = "APPOINTMENT",
                    title = "Diş hekimi randevusu",
                    sourceLabel = "Takvim",
                    sourcePackage = "com.google.android.calendar",
                    dueAt = at(2, 14, 30),
                    amount = null,
                    currency = null,
                    status = "ACTIVE",
                    confidence = 0.97,
                    createdAt = now - 15_000,
                    reminderOffsets = "1440,60",
                    fingerprint = "store-appointment",
                    keyHash = "store-appointment",
                ),
                CardEntity(
                    id = "store-cargo",
                    category = "DELIVERY",
                    title = "Kargo teslimatı",
                    sourceLabel = "Kargo bildirimi",
                    sourcePackage = "com.fixture.cargo",
                    dueAt = at(4, 12),
                    amount = null,
                    currency = null,
                    status = "ACTIVE",
                    confidence = 0.96,
                    createdAt = now - 10_000,
                    reminderOffsets = "1440",
                    fingerprint = "store-cargo",
                    keyHash = "store-cargo",
                ),
                CardEntity(
                    id = "store-review",
                    category = "BILL",
                    title = "İnternet ödemesi",
                    sourceLabel = "WhatsApp",
                    sourcePackage = "com.whatsapp",
                    dueAt = at(3, 20),
                    amount = "500",
                    currency = "TRY",
                    status = "REVIEW",
                    confidence = 0.74,
                    createdAt = now - 5_000,
                    reminderOffsets = "1440",
                    note = "Annem: İnternet ödemesi var.",
                    fingerprint = "store-review",
                    keyHash = "store-review",
                ),
            )
            for (card in cards) repo.dao.put(card)
        }

        outputDir = File(context.getExternalFilesDir(null), "store-screenshots")
        outputDir.mkdirs()
        outputDir.listFiles()?.forEach { it.delete() }

        NotificationListenerService.requestRebind(
            ComponentName(context, UnutmaNotificationListenerService::class.java),
        )
    }

    @Test
    fun captureStoreScreens() {
        @Suppress("DEPRECATION")
        val flags = PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE
        wakeLock = context.getSystemService(PowerManager::class.java)
            .newWakeLock(flags, "unutma:store-screenshots")
            .apply { acquire(90_000) }
        launchAndCapture(null, By.text("Doğalgaz faturası"), "01-dashboard-dark.png")
        launchAndCapture("/card/store-gas", By.text("Hatırlatma"), "02-reminder-detail.png")
        launchAndCapture("/inbox", By.text("İnternet ödemesi"), "03-inbox-review.png")
        launchAndCapture("/settings", By.text("Bildirim erişimi"), "04-settings.png")
        launchAndCapture("/privacy", By.textContains("telefonunda kalır"), "05-privacy.png")
    }

    @After
    fun releaseWakeLock() {
        wakeLock?.takeIf { it.isHeld }?.release()
    }

    private fun launchAndCapture(route: String?, marker: androidx.test.uiautomator.BySelector, name: String) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: error("No launch intent for ${context.packageName}")
        launch.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK)
        launch.putExtra("screenshotMode", true)
        if (route != null) launch.putExtra("debugRoute", route)
        context.startActivity(launch)
        assertTrue("Screen marker did not appear for $route", device.wait(Until.hasObject(marker), 20_000))
        device.waitForIdle()
        Thread.sleep(2_000)
        capture(name)
    }

    private fun capture(name: String) {
        Thread.sleep(750)
        assertTrue(device.takeScreenshot(File(outputDir, name)))
    }
}
