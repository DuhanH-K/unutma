package app.unutma.unutma.parser

/**
 * The notification title is often a sender or conversation name. Messaging
 * previews therefore parse the body on its own while preserving the sender as
 * metadata. Non-messaging notifications keep title and body together because
 * institutions commonly split an intent across those fields.
 */
data class NotificationText(
    val sender: String?,
    val originalText: String,
    val normalizedMatchText: String,
    val foldedMatchText: String,
    val tokens: List<String>,
)

object NotificationTextComposer {
    fun compose(raw: RawNotification): NotificationText {
        val title = raw.title.replace("\u0000", "").trim().take(512)
        val body = raw.text.replace("\u0000", "").trim().take(ParserConfig.PREVIEW_LIMIT)
        val original = if (raw.requiresConfirmation && body.isNotBlank()) {
            body
        } else {
            listOf(title, body).filter { it.isNotBlank() }.distinct().joinToString(" ")
        }
        val normalized = TurkishNormalizer.normalize(original)
        val folded = TurkishCharFold.fold(normalized)
        return NotificationText(
            sender = title.takeIf { raw.requiresConfirmation && it.isNotBlank() },
            originalText = original,
            normalizedMatchText = normalized,
            foldedMatchText = folded,
            tokens = Regex("[\\p{L}\\p{N}]+(?:'[\\p{L}]+)?")
                .findAll(normalized)
                .map { it.value }
                .toList(),
        )
    }
}

object ConversationSummaryDetector {
    private val patterns = listOf(
        Regex("^\\s*\\d+\\s+(?:yeni|okunmamis|cevapsiz)\\s+mesaj(?:lar)?\\s*[.!]?$"),
        Regex("^\\s*\\d+\\s+kisi\\s+mesaj\\s+gonderdi\\s*[.!]?$"),
        Regex("^\\s*.+\\s+grubunda\\s+yeni\\s+mesajlar\\s*[.!]?$"),
        Regex("^\\s*(?:new|unread)\\s+messages?\\s*[.!]?$"),
        Regex("^\\s*\\d+\\s+(?:new|unread)\\s+messages?\\s*[.!]?$"),
    )

    fun matches(foldedText: String): Boolean = patterns.any { it.matches(foldedText) }
}

object MarketingSignalDetector {
    private val pattern = Regex(
        "\\b(?:kampanya\\p{L}*|indirim\\p{L}*|firsat\\p{L}*|kacirma|kacirmayin|hemen kesfet|sana ozel|" +
            "ucretsiz (?:teslimat|kargo)|sale|discount|offer|shop now|discover|free shipping)\\b|%\\s*\\d+",
    )

    fun matches(foldedText: String): Boolean = pattern.containsMatchIn(foldedText)
}

object CompletedActionDetector {
    private val pattern = Regex(
        "\\b(?:odenmistir|odendi|odemeniz alindi|odeme\\p{L}* (?:alindi|yapildi|tamamlandi|" +
            "gerceklesti|basarili)|ucret (?:alindi|odendi)|tahsil edildi|borc(?:unuz)? " +
            "(?:bulunmamaktadir|kapandi|kapatildi|sifirlandi)|siparis(?:iniz)? teslim edildi|" +
            "gonderi(?:niz)? teslim edildi|paket(?:iniz)? teslim edildi|basvuru(?:nuz)? tamamlandi|" +
            "islem(?:iniz)? basariyla gerceklesti|belge(?:niz)? gonderildi|iade (?:edildi|yapildi)|" +
            "payment (?:received|successful|completed)|was delivered|cancelled|canceled|iptal edildi)\\b",
    )

    fun matches(foldedText: String): Boolean = pattern.containsMatchIn(foldedText)
}

object SecurityOtpDetector {
    private val codePhrase = Regex(
        "\\b(?:dogrulama|giris|guvenlik|tek kullanimlik|verification|security|login) " +
            "(?:kodu|kodunuz|code)\\b|\\botp\\b|\\bsifreniz\\b",
    )
    private val codeValue = Regex("(?<!\\d)\\d{4,8}(?!\\d)")

    fun matches(foldedText: String): Boolean = codePhrase.containsMatchIn(foldedText) ||
        (Regex("\\b(?:kod|code)\\b").containsMatchIn(foldedText) && codeValue.containsMatchIn(foldedText))
}

object ReminderMarkerDetector {
    private val strong = listOf(
        Regex("\\b(?:sakin ha |sakin |aman )?unutma(?:yin|yiniz|yasın|yasin)?\\b"),
        Regex("\\bunutmadan(?: (?:yap|al|ara|gonder))?\\b"),
        Regex("\\bhatirlat(?:ir misin|ir misiniz|sana)?\\b"),
        Regex("\\baklinda (?:olsun|bulunsun)\\b"),
        Regex("\\bnot (?:et|al)\\b"),
        Regex("\\bsakin atlama\\b|\\bgozunden kacmasin\\b"),
        Regex("\\b(?:yapmayi )?ihmal etme\\b"),
        Regex("\\b(?:mutlaka|kesin|lutfen) yap\\b"),
    )
    private val medium = listOf(
        Regex("\\byapar misin\\b"),
        Regex("\\balir(?:i)?\\s*misin+\\b|\\balabilir\\s*misin+\\b"),
        Regex("\\bgetirir misin\\b"),
        Regex("\\bgoturur musun\\b"),
        Regex("\\barar misin\\b"),
        Regex("\\bmesaj atar misin\\b"),
        Regex("\\b(?:gonderir|yollar) misin\\b"),
        Regex("\\bugrar misin\\b"),
        Regex("\\bkontrol eder misin\\b"),
    )

    fun hasStrong(foldedText: String): Boolean = strong.any { it.containsMatchIn(foldedText) }
    fun hasMedium(foldedText: String): Boolean = medium.any { it.containsMatchIn(foldedText) }
}

object ObligationMarkerDetector {
    private val pattern = Regex(
        "\\b(?:yapman|etmen|gitmen|alman|getirmen|goturmen|gondermen|odemen|yatirman|bitirmen|tamamlaman) " +
            "(?:lazim|gerekiyor)|\\b(?:yapmali|etmeli|gitmeli|almali|gondermeli|odemeli)" +
            "(?:yim|sin|siniz|yiz)?\\b|\\bzorunda(?:yim|sin|siniz|yiz)?\\b",
    )

    fun matches(foldedText: String): Boolean = pattern.containsMatchIn(foldedText)
}

data class ContextualTime(val phrase: String)

object ContextualTemporalExtractor {
    private val phrases = listOf(
        "isten cikinca",
        "isten gelirken",
        "ise giderken",
        "evden cikinca",
        "eve gelirken",
        "eve giderken",
        "yola cikmadan",
        "gelmeden once",
        "gitmeden once",
        "yatmadan once",
        "eve varinca",
        "cikmadan",
        "gelirken",
        "giderken",
        "cikarken",
        "uyanınca",
        "uyaninca",
    )

    fun extract(foldedText: String): ContextualTime? = phrases
        .firstOrNull { Regex("(?<![\\p{L}])${Regex.escape(it)}(?![\\p{L}])").containsMatchIn(foldedText) }
        ?.let(::ContextualTime)
}

/** DateParser owns concrete instants; this component exposes V4's temporal API. */
object TurkishTemporalExtractor {
    fun extract(raw: RawNotification, notificationText: NotificationText): DateEvidence =
        DateParser().parse(
            notificationText.normalizedMatchText,
            raw.postedAt,
            raw.locale,
            raw.zone,
        )
}

data class VerbMatch(
    val intent: TaskIntent,
    val canonical: String,
    val range: IntRange,
    val surface: String,
)

object TurkishVerbLexicon {
    private data class Rule(val intent: TaskIntent, val canonical: String, val pattern: Regex)

    private val rules = listOf(
        Rule(
            TaskIntent.PAYMENT_DUE,
            "öde",
            Regex(
                "\\b(?:odenmesi gerekiyor|ode(?:meyi|memi|yin|yiniz|meliyim|melisin|melisiniz|" +
                    "yecegim|yecegiz|yeceksin)?|yatir(?:mayi|maliyim|malisin|malisiniz)?|" +
                    "havale yap|eft yap|transfer et|borcu kapat)\\b",
            ),
        ),
        Rule(
            TaskIntent.CALL_MESSAGE,
            "mesaj gönder",
            Regex("\\b(?:whatsapp'tan yaz|mesaj at(?:ar misin)?|e-posta gonder|mail at|cevap ver|geri don)\\b"),
        ),
        Rule(
            TaskIntent.DEADLINE,
            "gönder",
            Regex(
                "\\b(?:belgeyi ilet|gonder(?:meyi|meliyim|melisin|melisiniz|ecegim|eceksin|ir misin)?|" +
                    "yolla(?:mayi|r misin)?|teslim et(?:meyi|melisin|meniz|men)?|yukle|" +
                    "basvur(?:uyu tamamla|mayi|man)?|formu doldur|imzala|onayla|" +
                    "bitir(?:men)?|tamamla(?:man|r misin)?)\\b",
            ),
        ),
        Rule(
            TaskIntent.BRING_TAKE,
            "getir",
            Regex(
                "\\b(?:yaninda getir|yanina al|getir(?:meyi|meliyim|melisin|ir misin)?|" +
                    "gotur(?:meyi|meliyim|melisin|ur musun)?|birak)\\b",
            ),
        ),
        Rule(
            TaskIntent.CALL_MESSAGE,
            "ara",
            Regex("\\b(?:telefon et|ara(?:mayi|maliyim|malisin|malisiniz|yacagim|yacaksin|r misin)?)\\b"),
        ),
        Rule(
            TaskIntent.APPOINTMENT,
            "git",
            Regex("\\b(?:(?:randevuya|doktora) git(?:men|meyi|melisin)?|derse gir|sinava git|toplantiya gir|katil)\\b"),
        ),
        Rule(
            TaskIntent.GENERAL_TASK,
            "git",
            Regex("\\b(?:git(?:meyi|meliyim|melisin|men gerekiyor)?|ugra(?:mayi|maliyim|r misin)?|gel)\\b"),
        ),
        Rule(
            TaskIntent.BUY_PICKUP,
            "al",
            Regex(
                "\\b(?:satin al|siparis et|marketten al|eczaneden al|subeden al|teslim al|gidip al|" +
                    "al(?:mayi|maliyim|malisin|malisiniz|acagim|acaksin|ir(?:i)?\\s*misin+|abilir\\s*misin+)?)\\b",
            ),
        ),
        Rule(
            TaskIntent.CALL_MESSAGE,
            "yaz",
            Regex("\\byaz(?:mayi|maliyim|malisin|acagim|acaksin)?\\b"),
        ),
        Rule(
            TaskIntent.MEDICATION_ROUTINE,
            "iç",
            Regex("\\bic(?:meyi|meliyim|melisin|melisiniz)?\\b"),
        ),
        Rule(
            TaskIntent.GENERAL_TASK,
            "kontrol et",
            Regex("\\b(?:kontrol et(?:meyi|melisin|er misin)?|incele|takip et|teyit et|dogrula|sor)\\b"),
        ),
        Rule(
            TaskIntent.GENERAL_TASK,
            "yenile",
            Regex("\\b(?:yenile(?:meyi)?|uzat|iptal et|aboneligi kapat|uyeligi iptal et)\\b"),
        ),
        Rule(
            TaskIntent.GENERAL_TASK,
            "yap",
            Regex("\\b(?:copu at|yap(?:mayi|maliyim|malisin|malisiniz|ar misin)?|tamamla)\\b"),
        ),
    )

    fun find(foldedText: String): VerbMatch? = rules.asSequence()
        .mapNotNull { rule ->
            rule.pattern.find(foldedText)?.let {
                VerbMatch(rule.intent, rule.canonical, it.range, it.value)
            }
        }
        .minByOrNull { it.range.first }
}

object VerbComplementExtractor {
    private val complement = Regex(
        "\\b([a-zçğıöşü]+?)(?:mayi|meyi)\\s+(?:sakin\\s+|aman\\s+)?unutma\\b",
    )

    fun extract(foldedText: String): String? = complement.find(foldedText)?.groupValues?.get(1)
}

object ObjectExtractor {
    private val temporal = Regex(
        "\\b(?:bugun|yarin|obur gun|bu (?:aksam|gece|sabah|oglen)|yarin (?:sabah|oglen|aksam)|" +
            "hafta sonu|onumuzdeki hafta|gelecek hafta|(?:bu |gelecek )?(?:pazartesi|sali|carsamba|" +
            "persembe|cuma|cumartesi|pazar)|(?:eve |ise |isten |evden |yola )?(?:gelirken|giderken|" +
            "cikarken|cikinca|varinca|cikmadan)|(?:gelmeden|gitmeden|yatmadan) once|uyaninca)\\b",
    )
    private val clock = Regex(
        "(?<!\\d)(?:saat\\s*)?\\d{1,2}(?::\\d{2}|\\.\\d{2})?(?:'?(?:te|ta|de|da))?(?!\\d)",
    )
    private val dayOfMonth = Regex("\\b(?:ayin\\s+)?\\d{1,2}'?(?:inde|inda|si|i)\\b")
    private val noise = Regex(
        "\\b(?:(?:[a-z]+\\s+)?(?:abi|abla|askim|kardesim)|anne|annem|baba|babam|bana|bize|lutfen|pls|tm|tamam|" +
            "sakin|aman|mutlaka|kesin|olur mu|tamam mi|aklinda olsun|aklinda bulunsun|not et|not al)\\b",
    )
    private val tail = Regex(
        "\\b(?:unutma(?:yin|yiniz|yasin)?|hatirla|hatirlat(?:ir misin|ir misiniz|sana)?|" +
            "yapman lazim|etmen gerekiyor|ihmal etme)\\b.*$",
    )

    fun extract(normalizedText: String, foldedText: String, verb: VerbMatch): String? {
        val before = normalizedText.take(verb.range.first.coerceAtMost(normalizedText.length))
        val afterStart = (verb.range.last + 1).coerceAtMost(normalizedText.length)
        val after = normalizedText.substring(afterStart)
        val preferred = clean(before)
        val fallback = clean(after)
        return (preferred.ifBlank { fallback })
            .takeIf { it.length >= 2 && Regex("[\\p{L}]").containsMatchIn(it) }
            ?.take(72)
    }

    private fun clean(value: String): String {
        val folded = TurkishCharFold.fold(value)
        if (folded.length != value.length) return cleanFolded(folded)
        val remove = BooleanArray(value.length)
        val relative = Regex("(?<!\\d)\\d{1,3}\\s*(?:dakika|saat|gun|hafta)\\s*(?:sonra|icinde)")
        listOf(temporal, clock, dayOfMonth, noise, tail, relative).forEach { pattern ->
            pattern.findAll(folded).forEach { match ->
                for (index in match.range) if (index in remove.indices) remove[index] = true
            }
        }
        val kept = buildString(value.length) {
            value.forEachIndexed { index, char -> append(if (remove[index]) ' ' else char) }
        }
        return kept.replace(Regex("[^\\p{L}\\p{N}' +.-]+"), " ")
            .replace(Regex("\\s+"), " ")
            .trim(' ', ',', '.', '!', '?')
    }

    private fun cleanFolded(value: String): String {
        var result = temporal.replace(value, " ")
        result = clock.replace(result, " ")
        result = dayOfMonth.replace(result, " ")
        result = noise.replace(result, " ")
        result = tail.replace(result, " ")
        return result.replace(Regex("[^a-z0-9' +.-]+"), " ")
            .replace(Regex("\\s+"), " ")
            .trim(' ', ',', '.', '!', '?')
    }
}

object PaymentObjectExtractor {
    private val obligation = Regex(
        "\\b([\\p{L}\\p{N}][\\p{L}\\p{N}+.'-]*(?:\\s+[\\p{L}\\p{N}+.'-]+){0,3})\\s+" +
            "(?:ödemesi|odemesi|faturası|faturasi|borcu|ücreti|ucreti|aidatı|aidati|taksidi|ekstresi)\\b",
        RegexOption.IGNORE_CASE,
    )
    private val leadingNoise = Regex(
        "^(?:(?:abi(?:cim)?|abla(?:cım|cim)?|aşkım|askim|anne(?:m)?|baba(?:m)?|kardeşim|kardesim|" +
            "lütfen|lutfen|bugün|bugun|yarın|yarin|bu akşam|bu aksam)\\s+)+",
        RegexOption.IGNORE_CASE,
    )

    fun extract(normalizedText: String): String? {
        val subject = obligation.find(normalizedText)?.groupValues?.get(1)
            ?.let { leadingNoise.replace(it, "") }
            ?.trim()
            .orEmpty()
        return subject.takeIf { it.length >= 2 }?.take(72)
    }
}

object ReminderObjectExtractor {
    private val marker = Regex(
        "\\b(?:unutma(?:yin|yiniz|yasin)?|hatirla|aklinda olsun|not et|not al)\\b.*$",
    )
    private val temporal = Regex(
        "\\b(?:bugun|yarin|obur gun|bu (?:aksam|gece|sabah|oglen)|" +
            "(?:bu |gelecek )?(?:pazartesi|sali|carsamba|persembe|cuma|cumartesi|pazar)|" +
            "hafta sonu|onumuzdeki hafta|gelecek hafta)\\b",
    )
    private val address = Regex(
        "\\b(?:abi(?:cim)?|abla(?:cim)?|askim|anne(?:m)?|baba(?:m)?|kardesim|lutfen|sakin|aman)\\b",
    )

    fun extract(normalizedText:String):String? {
        val folded=TurkishCharFold.fold(normalizedText)
        val visible=normalizedText.toCharArray()
        listOf(marker,temporal,address).forEach { pattern ->
            pattern.findAll(folded).forEach { match -> match.range.forEach { visible[it]=' ' } }
        }
        val value=String(visible).replace(Regex("[^\\p{L}\\p{N}' +.-]+")," ")
            .replace(Regex("\\s+")," ").trim(' ','.',',','!','?')
        return value.takeIf { it.length in 2..72 && Regex("\\p{L}").containsMatchIn(it) }
    }
}

data class TurkishIntentResult(
    val intent: TaskIntent,
    val category: Category,
    val title: String,
    val actionVerb: String?,
    val actionObject: String?,
    val temporalContext: String?,
    val confidence: Double,
    val review: Boolean,
)

object TurkishIntentEngine {
    private val nonTaskMemory = Regex(
        "\\b(?:unutma beni|beni unutma|bizi unutma|seni hic unutmadim|beni unutmus|" +
            "unutamadim|unutulmaz(?: bir gece| firsatlar)?)\\b",
    )
    private val appointmentSubject = Regex("\\b(?:randevu|doktor|disci|muayene|toplanti|gorusme|mulakat)\\p{L}*\\b")
    private val pickupSubject = Regex("\\b(?:kargo|kargoyu|paket|paketi|gonderi|sube|subeden)\\b")
    private val travelSubject = Regex("\\b(?:ucus|bilet|otobus|tren|sefer)\\p{L}*\\b|\\b(?:check-in|boarding)\\b")
    private val paymentSubject = Regex("\\b(?:fatura|odeme|kira|aidat|taksit|borc|ekstre|ucret|cek|senet)\\p{L}*\\b")

    fun analyze(
        text: NotificationText,
        date: DateEvidence,
        entities: Entities,
        messagePreview: Boolean,
    ): TurkishIntentResult? {
        val folded = text.foldedMatchText
        if (folded.isBlank()) return null
        if (ConversationSummaryDetector.matches(folded)) return null
        if (SecurityOtpDetector.matches(folded)) return null
        if (MarketingSignalDetector.matches(folded)) return null
        if (CompletedActionDetector.matches(folded)) return null
        if (nonTaskMemory.containsMatchIn(folded)) return null

        val strong = ReminderMarkerDetector.hasStrong(folded)
        val medium = ReminderMarkerDetector.hasMedium(folded)
        val obligation = ObligationMarkerDetector.matches(folded)
        val context = ContextualTemporalExtractor.extract(folded)
        val verb = TurkishVerbLexicon.find(folded)
        val complement = VerbComplementExtractor.extract(folded)
        var actionObject = verb?.let { ObjectExtractor.extract(text.normalizedMatchText, folded, it) }
        if (actionObject.isNullOrBlank() && complement != null) actionObject = defaultObject(complement)
        if (actionObject.isNullOrBlank() && paymentSubject.containsMatchIn(folded)) {
            actionObject = PaymentObjectExtractor.extract(text.normalizedMatchText)
        }
        if (actionObject.isNullOrBlank() && strong) {
            actionObject = ReminderObjectExtractor.extract(text.normalizedMatchText)
        }

        val hasTemporalEvidence = date.instant != null || date.hasTime || context != null
        val hasConcreteObject = !actionObject.isNullOrBlank() || paymentSubject.containsMatchIn(folded) ||
            appointmentSubject.containsMatchIn(folded) || pickupSubject.containsMatchIn(folded)
        val allowsImplicitObject = verb?.intent in setOf(
            TaskIntent.PAYMENT_DUE,
            TaskIntent.CALL_MESSAGE,
            TaskIntent.DEADLINE,
            TaskIntent.GENERAL_TASK,
        )
        val actionable = verb != null && (strong || medium || obligation || hasTemporalEvidence) &&
            (hasConcreteObject || strong || obligation || (hasTemporalEvidence && allowsImplicitObject))
        val markerOnly = strong && hasConcreteObject
        if (!actionable && !markerOnly) return null

        var intent = verb?.intent ?: TaskIntent.REMINDER_REQUEST
        if (paymentSubject.containsMatchIn(folded) && (strong || verb?.intent == TaskIntent.PAYMENT_DUE || PaymentVocabulary.isDue(folded, date.instant != null, entities.amount != null))) {
            intent = TaskIntent.PAYMENT_DUE
        } else if (appointmentSubject.containsMatchIn(folded) &&
            (verb == null || verb.intent == TaskIntent.APPOINTMENT || verb.canonical == "git")) {
            intent = TaskIntent.APPOINTMENT
        } else if (pickupSubject.containsMatchIn(folded) && verb?.intent == TaskIntent.BUY_PICKUP) {
            intent = TaskIntent.DELIVERY_PICKUP
        } else if (travelSubject.containsMatchIn(folded) &&
            (verb == null || verb.intent == TaskIntent.GENERAL_TASK || verb.intent == TaskIntent.APPOINTMENT)) {
            intent = TaskIntent.TRAVEL
        }

        val category = categoryFor(intent)
        val confidence = confidence(
            strong = strong,
            medium = medium,
            obligation = obligation,
            verb = verb != null,
            concreteObject = hasConcreteObject,
            date = date,
            contextual = context != null,
            messagePreview = messagePreview,
        )
        if (confidence < ParserConfig.MESSAGE_REVIEW) return null
        val canonicalVerb = verb?.canonical ?: if (intent == TaskIntent.PAYMENT_DUE) "öde" else "hatırla"
        return TurkishIntentResult(
            intent = intent,
            category = category,
            title = titleFor(intent, actionObject, canonicalVerb),
            actionVerb = canonicalVerb,
            actionObject = actionObject,
            temporalContext = context?.phrase,
            confidence = confidence,
            review = messagePreview || confidence < ParserConfig.HIGH || date.ambiguous || date.invalid || date.instant == null,
        )
    }

    private fun confidence(
        strong: Boolean,
        medium: Boolean,
        obligation: Boolean,
        verb: Boolean,
        concreteObject: Boolean,
        date: DateEvidence,
        contextual: Boolean,
        messagePreview: Boolean,
    ): Double {
        var value = 0.18
        if (strong) value += 0.38
        if (medium) value += 0.20
        if (obligation) value += 0.30
        if (verb) value += 0.22
        if (concreteObject) value += 0.12
        if (date.instant != null && !date.invalid) value += 0.16
        if (date.hasTime) value += 0.06
        if (verb && date.instant != null && !date.invalid) value += 0.08
        if (contextual) value += 0.13
        if (date.ambiguous) value -= 0.12
        if (date.invalid) value -= 0.35
        // A message preview is always reviewed, but source type does not reduce
        // semantic confidence. It only changes the persistence state.
        if (messagePreview && value > 0.99) value = 0.99
        return value.coerceIn(0.0, 1.0)
    }

    private fun categoryFor(intent: TaskIntent): Category = when (intent) {
        TaskIntent.PAYMENT_DUE -> Category.PAYMENT_DUE
        TaskIntent.APPOINTMENT -> Category.APPOINTMENT
        TaskIntent.RESERVATION -> Category.RESERVATION
        TaskIntent.DELIVERY_PICKUP -> Category.PACKAGE_PICKUP
        TaskIntent.DEADLINE -> Category.OTHER
        TaskIntent.TRAVEL -> Category.TRAVEL
        else -> Category.OTHER
    }

    private fun titleFor(intent: TaskIntent, actionObject: String?, verb: String): String {
        val subject = actionObject?.trim().orEmpty()
        val fallback = when (intent) {
            TaskIntent.PAYMENT_DUE -> "Ödemeyi yap"
            TaskIntent.BUY_PICKUP -> "Alınacak şey"
            TaskIntent.BRING_TAKE -> "Getirilecek şey"
            TaskIntent.CALL_MESSAGE -> if (verb == "ara") "Arama yap" else "Mesaj gönder"
            TaskIntent.APPOINTMENT -> "Randevuya git"
            TaskIntent.DELIVERY_PICKUP -> "Kargoyu al"
            TaskIntent.DEADLINE -> "Görevi tamamla"
            TaskIntent.TRAVEL -> "Yolculuğu kontrol et"
            TaskIntent.MEDICATION_ROUTINE -> "İlaç hatırlatması"
            else -> "Görevi hatırla"
        }
        if (subject.isBlank()) return fallback
        val title = "$subject $verb".replace(Regex("\\s+"), " ").trim()
        return title.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }.take(120)
    }

    private fun defaultObject(complement: String): String? = when {
        complement.startsWith("ode") -> "ödeme"
        complement.startsWith("ara") -> "arama"
        complement.startsWith("gonder") -> "gönderilecek şey"
        complement.startsWith("getir") -> "getirilecek şey"
        complement.startsWith("gotur") -> "götürülecek şey"
        complement.startsWith("git") -> "gidilecek yer"
        complement.startsWith("al") -> "alınacak şey"
        else -> null
    }
}
