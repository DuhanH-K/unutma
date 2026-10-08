package app.unutma.unutma

import app.unutma.unutma.parser.Category
import app.unutma.unutma.parser.ConversationSummaryDetector
import app.unutma.unutma.parser.NotificationTextComposer
import app.unutma.unutma.parser.RawNotification
import app.unutma.unutma.parser.RuleEngine
import app.unutma.unutma.parser.TaskIntent
import app.unutma.unutma.parser.TurkishCharFold
import app.unutma.unutma.parser.TurkishNormalizer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.Locale

class TurkishIntentEngineTest {
    private val zone = ZoneId.of("Europe/Istanbul")
    private val posted = ZonedDateTime.of(2026, 9, 2, 8, 0, 0, 0, zone)
        .toInstant()
        .toEpochMilli()

    private fun message(body: String, title: String = "Anne") = RuleEngine().parse(
        RawNotification(
            source = "com.whatsapp",
            key = "conversation-key",
            title = title,
            text = body,
            postedAt = posted,
            locale = Locale.forLanguageTag("tr-TR"),
            zone = zone,
            requiresConfirmation = true,
        ),
    )

    @Test
    fun v4RequiredNaturalMessageExamplesAreUnderstoodAndReviewed() {
        val fixtures = listOf(
            Triple("Yarın ödemeyi unutma", TaskIntent.PAYMENT_DUE, Category.PAYMENT_DUE),
            Triple("Gelirken ekmek al", TaskIntent.BUY_PICKUP, Category.OTHER),
            Triple("3'te beni ara", TaskIntent.CALL_MESSAGE, Category.OTHER),
            Triple("Çıkmadan kargoyu al", TaskIntent.DELIVERY_PICKUP, Category.PACKAGE_PICKUP),
            Triple("Cuma dosyayı gönder", TaskIntent.DEADLINE, Category.OTHER),
        )

        fixtures.forEach { (text, intent, category) ->
            val candidate = message(text)
            assertNotNull(text, candidate)
            assertEquals(text, intent, candidate?.intent)
            assertEquals(text, category, candidate?.category)
            assertTrue(text, candidate?.review == true)
            assertTrue(text, candidate?.title?.isNotBlank() == true)
        }
    }

    @Test
    fun actionAndObjectExtractionKeepUsefulNaturalTitles() {
        val bread = message("Gelirken ekmek almayı unutma")!!
        assertEquals("al", bread.actionVerb)
        assertEquals("ekmek", bread.actionObject)
        assertEquals("Ekmek al", bread.title)
        assertEquals("gelirken", bread.temporalContext)
        assertNull(bread.date.instant)

        val file = message("Yarın Ahmet'e dosyayı gönder")!!
        assertEquals("gönder", file.actionVerb)
        assertTrue(file.title.contains("dosyayı"))
        assertTrue(file.title.contains("Ahmet'e", ignoreCase = true))
    }

    @Test
    fun exactBrotherWhatsAppPaymentCreatesAnEditableReviewCandidate() {
        val candidate = message(
            "Abi yarın doğalgaz faturasını ödemeyi unutma 500 TL.",
            title = "Erkek kardeşim",
        )!!

        assertEquals(TaskIntent.PAYMENT_DUE, candidate.intent)
        assertEquals(Category.BILL, candidate.category)
        assertEquals("500", candidate.entities.amount)
        assertEquals("TRY", candidate.entities.currency)
        assertEquals("öde", candidate.actionVerb)
        assertTrue(candidate.title.contains("doğalgaz", ignoreCase = true))
        assertNotNull(candidate.date.instant)
        assertTrue(candidate.review)
    }

    @Test
    fun exactInformalBrotherPaymentPreviewCreatesAReviewCandidate() {
        val candidate = message(
            "Abicim yarın doğalgaz ödemesi var 500 TL unutma",
            title = "Kız kardeşim",
        )!!

        assertEquals(TaskIntent.PAYMENT_DUE, candidate.intent)
        assertEquals(Category.PAYMENT_DUE, candidate.category)
        assertEquals("500", candidate.entities.amount)
        assertEquals("TRY", candidate.entities.currency)
        assertTrue(candidate.title.contains("doğalgaz", ignoreCase = true))
        assertNotNull(candidate.date.instant)
        assertTrue(candidate.review)
    }

    @Test
    fun clockOnlyMessagesUseNextOccurrenceButRemainAmbiguous() {
        val call = message("3'te beni ara")!!
        val local = Instant.ofEpochMilli(call.date.instant!!).atZone(zone)
        assertEquals(15, local.hour)
        assertEquals(2, local.dayOfMonth)
        assertTrue(call.date.ambiguous)
        assertTrue(call.review)
    }

    @Test
    fun sourceAwareComposerDoesNotTreatSenderAsMessageBody() {
        val raw = RawNotification(
            "com.whatsapp",
            "key",
            "Unutma Beni",
            "Yarın faturayı öde",
            posted,
            Locale.forLanguageTag("tr-TR"),
            zone,
            true,
        )
        val composed = NotificationTextComposer.compose(raw)
        assertEquals("Unutma Beni", composed.sender)
        assertEquals("Yarın faturayı öde", composed.originalText)
        assertEquals(TaskIntent.PAYMENT_DUE, RuleEngine().parse(raw)?.intent)
    }

    @Test
    fun summariesSecurityCompletedAndMarketingAreIgnored() {
        listOf(
            "3 yeni mesaj",
            "5 okunmamış mesaj",
            "Aile grubunda yeni mesajlar",
            "2 kişi mesaj gönderdi",
            "Doğrulama kodunuz 123456",
            "Şifreniz 9281",
            "Tek kullanımlık kod",
            "Ödemeniz alındı",
            "Faturanız ödenmiştir",
            "Başvurunuz tamamlandı",
            "Bu fırsatı unutma!",
            "Bugüne özel fırsatı kaçırmayın",
            "Ücretsiz kargo fırsatını kaçırma",
            "Unutma Beni",
            "Unutamadım",
            "Unutulmaz bir gece",
        ).forEach { assertNull(it, message(it)) }
        assertTrue(ConversationSummaryDetector.matches("3 yeni mesaj"))
    }

    @Test
    fun normalizationPreservesDisplayTextAndFoldsOnlyMatchingCopy() {
        val normalized = TurkishNormalizer.normalize("  YARIN   ÖDEMEYİ  UNUTMA  ")
        assertEquals("yarın ödemeyi unutma", normalized)
        assertEquals("yarin odemeyi unutma", TurkishCharFold.fold(normalized))
        assertFalse(normalized.contains("yarin"))
    }

    @Test
    fun obligationPoliteContextAndNoisyFormsAreHandled() {
        listOf(
            "Yarın ödemeyi yapman lazım",
            "Cuma formu teslim etmen gerekiyor",
            "Bugün faturayı ödemelisin",
            "Yarın randevuya gitmen gerekiyor",
            "Bu hafta başvuruyu bitirmen lazım",
            "Yarın beni arar mısın?",
            "Gelirken süt alır mısın?",
            "Akşam belgeyi yollar mısın?",
            "Cuma başvuruyu tamamlar mısın?",
            "Eve gelirken kargoyu alabilir misin?",
            "yarin odemeyi unutma",
            "yarın 3te ara",
            "aksam beni ara",
            "gelrken sut al",
            "CUMA DOSYAYI YOLLA",
            "yarın 14.30 da gel",
            "gelirken ekmek al 👍",
            "yarın öde pls",
            "yarın kargoyu al!!!",
        ).forEach { assertNotNull(it, message(it)) }
    }
}
