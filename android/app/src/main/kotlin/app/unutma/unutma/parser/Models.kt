package app.unutma.unutma.parser

import java.time.Clock
import java.time.ZoneId
import java.text.Normalizer
import java.util.Locale

enum class Category { BILL, PAYMENT_DUE, PACKAGE_DELIVERY, PACKAGE_PICKUP, APPOINTMENT, RESERVATION, SUBSCRIPTION_RENEWAL, RETURN_WINDOW, TICKET_EVENT, TRAVEL, DEADLINE, OTHER }
enum class CardStatus { ACTIVE, REVIEW, DONE, SNOOZED, ARCHIVED, EXPIRED }
enum class TaskIntent {
    REMINDER_REQUEST,
    PAYMENT_DUE,
    BUY_PICKUP,
    BRING_TAKE,
    CALL_MESSAGE,
    APPOINTMENT,
    RESERVATION,
    DELIVERY_PICKUP,
    DEADLINE,
    TRAVEL,
    MEDICATION_ROUTINE,
    GENERAL_TASK,
    COMPLETED_NO_ACTION,
    MARKETING_IGNORE,
    SECURITY_OTP_IGNORE,
    CONVERSATION_SUMMARY_IGNORE,
    UNKNOWN,
}
data class RawNotification(
    val source: String,
    val key: String,
    val title: String,
    val text: String,
    val postedAt: Long,
    val locale: Locale,
    val zone: ZoneId,
    val requiresConfirmation: Boolean = false,
)
data class DateEvidence(val instant: Long?, val hasTime: Boolean = false, val ambiguous: Boolean = false, val invalid: Boolean = false)
data class Entities(val amount: String? = null, val currency: String? = null, val identifier: String? = null, val location: String? = null)
data class Candidate(
    val category: Category,
    val date: DateEvidence,
    val entities: Entities,
    val confidence: Double,
    val review: Boolean,
    val fingerprint: String,
    val keyHash: String,
    val title: String = "",
    val intent: TaskIntent = TaskIntent.UNKNOWN,
    val actionVerb: String? = null,
    val actionObject: String? = null,
    val temporalContext: String? = null,
)
object ParserConfig {
    const val VERSION = 6
    const val HIGH = .90
    const val REVIEW = .65
    const val MESSAGE_REVIEW = .55
    const val INTENT_WEIGHT = .68
    const val DATE_WEIGHT = .24
    const val AMOUNT_WEIGHT = .03
    const val DEDUPE_TTL = 7 * 24 * 60 * 60 * 1000L
    const val PREVIEW_LIMIT = 4096
    const val HISTORY_RETENTION = 90 * 24 * 60 * 60 * 1000L
}
object TurkishNormalizer {
    private val turkish = Locale.forLanguageTag("tr-TR")

    fun normalize(value: String): String = Normalizer.normalize(value, Normalizer.Form.NFC)
        .replace(Regex("[\\u2018\\u2019\\u02BC\\u0060]"), "'")
        .replace(Regex("\\s*([;!?])\\s*"), "$1 ")
        .replace(Regex("\\s+"), " ")
        .trim()
        .lowercase(turkish)
}

object TurkishCharFold {
    fun fold(value: String): String = value
        .replace('ç', 'c')
        .replace('ğ', 'g')
        .replace('ı', 'i')
        .replace('ö', 'o')
        .replace('ş', 's')
        .replace('ü', 'u')
        .replace('â', 'a')
        .replace('î', 'i')
        .replace('û', 'u')
        .replace(Regex("([\\p{L}])\\1{2,}")) { it.groupValues[1] }
        .replace(Regex("\\bgelrken\\b"), "gelirken")
}

/** Compatibility names used by the existing English/date parser tests. */
object TextNormalizer {
    fun normalize(value: String): String = TurkishNormalizer.normalize(value)
}
object MatchText {
    fun fold(value: String): String = TurkishCharFold.fold(value)
}
class TimeProvider(val clock: Clock = Clock.systemUTC()) { fun now(): Long = clock.millis() }
