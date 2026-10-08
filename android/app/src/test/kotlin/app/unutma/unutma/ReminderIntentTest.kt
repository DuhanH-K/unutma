package app.unutma.unutma

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import app.unutma.unutma.reminder.ReminderWorker
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ReminderIntentTest {
    @Test
    fun cardNavigationUsesExtrasWithoutCreatingAFlutterDeepLink() {
        val context=ApplicationProvider.getApplicationContext<Context>()
        val intent=ReminderWorker.cardIntent(context,"card-123")

        assertNull(intent.data)
        assertEquals("card-123",intent.getStringExtra("cardId"))
        assertEquals("${context.packageName}.OPEN_CARD",intent.action)
        assertEquals(MainActivity::class.java.name,intent.component?.className)
    }
}
