package app.unutma.unutma

import app.unutma.unutma.parser.RawNotification
import app.unutma.unutma.parser.RuleEngine
import app.unutma.unutma.parser.TaskIntent
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.Locale

/**
 * V4's Turkish quality gate. The corpus deliberately combines independent
 * subjects and temporal forms so inflection and token adjacency are exercised
 * without a giant sentence-specific regex.
 */
class TurkishFixtureCorpusTest {
    private data class Fixture(val family: String, val text: String, val intent: TaskIntent?)

    private val zone = ZoneId.of("Europe/Istanbul")
    private val postedAt = ZonedDateTime.of(2026, 9, 2, 8, 0, 0, 0, zone)
        .toInstant()
        .toEpochMilli()

    private fun parse(text: String) = RuleEngine().parse(
        RawNotification(
            source = "com.fixture.messaging",
            key = "fixture-${text.hashCode()}",
            title = "Fixture sender",
            text = text,
            postedAt = postedAt,
            locale = Locale.forLanguageTag("tr-TR"),
            zone = zone,
            requiresConfirmation = true,
        ),
    )

    @Test
    fun atLeast250TurkishFixturesMeetExpectedDecisions() {
        val positives = buildPositiveCorpus()
        val negatives = buildNegativeCorpus()
        val corpus = positives + negatives
        assertTrue("Expected at least 250 fixtures, got ${corpus.size}", corpus.size >= 250)
        assertTrue("Expected broad positive coverage", positives.size >= 200)
        assertTrue("Expected broad negative coverage", negatives.size >= 50)

        positives.forEach { fixture ->
            val candidate = parse(fixture.text)
            assertTrue("${fixture.family}: ${fixture.text}", candidate != null)
            assertEquals("${fixture.family}: ${fixture.text}", fixture.intent, candidate?.intent)
            assertTrue("Message preview must be reviewed: ${fixture.text}", candidate?.review == true)
        }
        negatives.forEach { fixture ->
            assertNull("${fixture.family}: ${fixture.text}", parse(fixture.text))
        }
    }

    private fun buildPositiveCorpus(): List<Fixture> = buildList {
        val dates = listOf("Yarın", "Cuma", "2 gün sonra", "Bu akşam", "Ayın 15'inde")
        val paymentSubjects = listOf(
            "elektrik", "su", "doğalgaz", "internet", "telefon", "kira", "aidat", "taksit",
            "kredi kartı", "senet", "vergi", "okul", "servis", "Spotify", "YouTube Premium", "Netflix",
        )
        for (date in dates) for (subject in paymentSubjects) {
            add(Fixture("payment", "$date $subject ücretini öde", TaskIntent.PAYMENT_DUE))
        }

        val people = listOf("annemi", "babamı", "Ahmet'i", "doktoru", "ustayı", "okulu", "bankayı", "kargo şubesini")
        for (date in dates) for (person in people) {
            add(Fixture("call-message", "$date $person ara", TaskIntent.CALL_MESSAGE))
        }

        val contexts = listOf("Gelirken", "Eve gelirken", "İşten gelirken", "Çıkmadan")
        val shopping = listOf("ekmek", "süt", "kahve", "ilaç", "pil", "deterjan", "mama", "su", "meyve", "bilet", "defter", "ampul")
        for (context in contexts) for (item in shopping) {
            add(Fixture("buy-pickup", "$context $item al", TaskIntent.BUY_PICKUP))
        }

        val carried = listOf("anahtarı", "dosyayı", "şarj aletini", "montu", "kitabı", "ilacı", "bileti", "evrakı")
        for (context in contexts) for (item in carried) {
            add(Fixture("bring-take", "$context $item getir", TaskIntent.BRING_TAKE))
        }

        val submissions = listOf("dosyayı", "raporu", "başvuruyu", "sözleşmeyi", "belgeyi", "sunumu", "ödevi", "dilekçeyi")
        for (date in dates) for (item in submissions) {
            add(Fixture("deadline", "$date $item gönder", TaskIntent.DEADLINE))
        }

        listOf(
            "Yarın ödemeyi yapman lazım" to TaskIntent.PAYMENT_DUE,
            "Cuma formu teslim etmen gerekiyor" to TaskIntent.DEADLINE,
            "Bugün faturayı ödemelisin" to TaskIntent.PAYMENT_DUE,
            "Yarın randevuya gitmen gerekiyor" to TaskIntent.APPOINTMENT,
            "Bu hafta başvuruyu bitirmen lazım" to TaskIntent.DEADLINE,
            "Yarın beni arar mısın" to TaskIntent.CALL_MESSAGE,
            "Gelirken süt alır mısın" to TaskIntent.BUY_PICKUP,
            "Akşam belgeyi yollar mısın" to TaskIntent.DEADLINE,
            "Cuma başvuruyu tamamlar mısın" to TaskIntent.DEADLINE,
            "Eve gelirken kargoyu alabilir misin" to TaskIntent.DELIVERY_PICKUP,
            "yarin odemeyi unutma" to TaskIntent.PAYMENT_DUE,
            "yarın 3te ara" to TaskIntent.CALL_MESSAGE,
            "aksam beni ara" to TaskIntent.CALL_MESSAGE,
            "gelrken sut al" to TaskIntent.BUY_PICKUP,
            "tm yarın gönder" to TaskIntent.DEADLINE,
            "yarın faturayi ode" to TaskIntent.PAYMENT_DUE,
            "CUMA DOSYAYI YOLLA" to TaskIntent.DEADLINE,
            "yarın 14.30 da gel" to TaskIntent.GENERAL_TASK,
            "gelirken ekmek al 👍" to TaskIntent.BUY_PICKUP,
            "yarın öde pls" to TaskIntent.PAYMENT_DUE,
            "yarın kargoyu al!!!" to TaskIntent.DELIVERY_PICKUP,
        ).forEach { (text, intent) -> add(Fixture("obligation-polite-noisy", text, intent)) }
    }

    private fun buildNegativeCorpus(): List<Fixture> = buildList {
        val marketingSubjects = listOf(
            "ayakkabı", "telefon", "mobilya", "market", "uçak bileti", "internet paketi",
            "kredi kartı", "restoran", "kozmetik", "elektronik", "kitap", "oyun",
        )
        for (subject in marketingSubjects) {
            add(Fixture("marketing", "$subject için bugüne özel %50 indirim", null))
            add(Fixture("marketing", "$subject fırsatını kaçırma", null))
        }

        listOf(
            "Ödemeniz alındı", "Faturanız ödenmiştir", "Siparişiniz teslim edildi",
            "Başvurunuz tamamlandı", "İşleminiz başarıyla gerçekleşti", "Belgeniz gönderildi",
            "Doğalgaz faturası ödendi", "Kira ödemesi yapıldı", "Borç kapatıldı",
            "Paketiniz teslim edildi", "Randevunuz iptal edildi", "İade yapıldı",
        ).forEach { completed ->
            add(Fixture("completed", completed, null))
            add(Fixture("completed", "$completed 12 Eylül", null))
        }

        listOf(
            "Doğrulama kodunuz 123456", "Şifreniz 9281", "Tek kullanımlık kod",
            "OTP 445566", "Giriş kodu 8090", "Güvenlik kodunuz 551122",
            "Verification code 302911", "Login code 7281", "Security code 661190",
            "Kod 1234",
        ).forEach { add(Fixture("security-otp", it, null)) }

        listOf(
            "3 yeni mesaj", "5 okunmamış mesaj", "Aile grubunda yeni mesajlar",
            "2 kişi mesaj gönderdi", "7 cevapsız mesaj", "4 new messages",
            "8 unread messages", "new messages", "unread messages", "12 yeni mesaj",
        ).forEach { add(Fixture("conversation-summary", it, null)) }

        listOf(
            "Unutma Beni", "Unutamadım", "Unutulmaz bir gece", "Unutulmaz fırsatlar",
            "Beni unutmuş", "Seni hiç unutmadım", "Beni unutma", "Bizi unutma",
            "Yarın hava sıcak olacak", "Cuma güzel bir gün", "Arama sonuçları yarın güncellenecek",
            "Yarın alarm 08:00'de çalar",
        ).forEach { add(Fixture("non-task", it, null)) }
    }
}
