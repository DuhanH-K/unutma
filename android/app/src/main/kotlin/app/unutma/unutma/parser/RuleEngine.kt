package app.unutma.unutma.parser

import java.security.MessageDigest

object NegativeSignals {
    private val nonAction=Regex("\\b(?:(?:beni|bizi|seni) unutma|unutma beni|unutamadim|unutulmaz(?: bir gece| firsatlar)?|beni unutmus|seni hic unutmadim)\\b")
    private val historical=Regex("(?:kargo|gonderi|paket).*(?:\\d+ gun once|ulasmisti|teslim edilmisti)")
    fun reject(text:String):Boolean {
        val folded=MatchText.fold(text)
        return MarketingSignalDetector.matches(folded) || CompletedActionDetector.matches(folded) ||
            SecurityOtpDetector.matches(folded) || ConversationSummaryDetector.matches(folded) ||
            nonAction.containsMatchIn(folded) || historical.containsMatchIn(folded)
    }
}
object PaymentVocabulary {
    // Open-ended obligation grammar: the object before these words may be any
    // product or service (for example "ayakkabi odemesi"), so new merchants do
    // not require a new parser release.
    private val obligation=Regex("\\b(?:odeme(?:si|sini|yi|m|miz)?|fatura\\p{L}*|ucret(?:i|ini)?|bedel(?:i|ini)?|para(?:si|sini)?|borc(?:u|unu|um|umuz)?|taksi[td](?:i|ini)?|ekstre(?:si|sini)?|aidat(?:i|ini)?|kira(?:si|yi)?|prim(?:i|ini)?|harc(?:i|ini)?|ceza(?:si|sini)?|masraf(?:i|ini)?|tahsilat(?:i|ini)?|bakiye(?:si|sini)?|hesap(?:i|ini)?)\\b")
    private val state=Regex("\\b(?:var|kaldi|geldi|gelmis|cikti|yaklasti|bekliyor|gerekiyor|gerekli|lazim|zorundayim|vade(?:si|sini)?|son gun|son tarih|odenmeli|odenecek|yatacak|tahsil edilecek|kesilecek|cekilecek|alinacak|basarisiz|reddedildi|gerceklesmedi|cekilemedi|yetersiz bakiye)\\b")
    private val action=Regex("\\b(?:ode|odemeyi|odememi|odemeliyim|odemelisin|odemelisiniz|odeyecegim|odeyecegiz|odeyeceksin|yatir|yatirmayi|yatirmaliyim|yatirmalisin|havale et|eft yap|transfer et|tahsil et|bozdur)\\b")
    private val instrument=Regex("\\b(?:cek(?:in|i)?|sene[td](?:in|i)?|kredi karti|banka karti|ek hesap|kmh|kredi|mortgage)\\b")

    // Used for terse date+amount messages such as "ayakkabi 1200 TL cuma".
    // A domain/brand by itself is never enough to create a candidate.
    private val domain=Regex("\\b(?:elektrik|su|dog+algaz|internet|fiber|wifi|telefon|gsm|mobil hat|sabit hat|kablo tv|uydu|kira|aidat|site|apartman|yurt|vergi|mtv|emlak vergisi|gelir vergisi|sigorta|kasko|trafik sigortasi|sgk|bag[- ]?kur|taksit|borc|kredi|kart ekstre(?:si)?|hgs|otoyol|kopru|trafik cezasi|harc|pasaport|ehliyet|okul|universite|kurs|dershane|servis|hastane|doktor|disci|eczane|ilac|market|bakkal|restoran|yemek|akaryakit|benzin|motorin|ayakkabi|giyim|kiyafet|mobilya|beyaz esya|elektronik|tamir|bakim|usta|avukat|muhasebe)\\b")
    private val subscription=Regex("\\b(?:spotify|spottify|youtube(?: premium)?|netflix|disney(?:\\+| plus)?|amazon prime|prime video|blutv|hbo max|exxen|gain|mubi|apple music|icloud|google one|microsoft 365|office 365|adobe|playstation plus|ps plus|xbox game pass|tivibu|digiturk|d-smart|superonline|turkcell|vodafone|turk telekom)\\b")
    private val failedCollection=Regex("(?:otomatik )?odeme.*(?:basarisiz|reddedildi|gerceklesmedi)|karttan (?:ucret|tutar|odeme).*cekilemedi|yetersiz bakiye.*(?:odeme|fatura|taksit)")

    fun isBill(text:String):Boolean=Regex("\\bfatura\\p{L}*\\b|\\b(?:bill|invoice).*(?:due|payable)\\b").containsMatchIn(text)

    fun isDue(text:String,hasDate:Boolean,hasAmount:Boolean):Boolean {
        val hasObligation=obligation.containsMatchIn(text)
        val hasState=state.containsMatchIn(text)
        val hasAction=action.containsMatchIn(text)
        val hasInstrument=instrument.containsMatchIn(text)
        val hasDomain=domain.containsMatchIn(text) || subscription.containsMatchIn(text)
        return failedCollection.containsMatchIn(text) || hasAction ||
            (hasObligation && (hasState || hasDate || hasAmount || hasDomain || hasInstrument)) ||
            (hasInstrument && (hasState || hasDate || hasAmount)) ||
            (hasDomain && hasDate && hasAmount)
    }
}
object EntityExtractor {
    fun extract(text:String):Entities {
        val amount=Regex("(₺|\\$|€|£|try|usd|eur|tl)\\s*([0-9]+(?:[.,][0-9]+)*)|([0-9]+(?:[.,][0-9]+)*)\\s*(tl|try|usd|eur|₺|€|£|\\$)").find(text)
        val value=amount?.let { it.groupValues[2].ifEmpty { it.groupValues[3] } }
        val currency=amount?.let { it.groupValues[1].ifEmpty { it.groupValues[4] } }?.let { when(it) { "₺","try","tl"->"TRY"; "$","usd"->"USD"; "€","eur"->"EUR";else->"GBP" } }
        val id=Regex("(?:tracking|order|takip|sipariş|siparis|gönderi|gonderi|rezervasyon|rez)(?: (?:no|numarası|numarasi|number))?[: #]+([a-z0-9-]{4,32})").find(text)?.groupValues?.get(1)
        val location=Regex("(?:location|konum|adres):\\s*([^;\\n]{3,80})").find(text)?.groupValues?.get(1)
        return Entities(value,currency,id,location)
    }
}
object IntentClassifier {
    private val rules=listOf(
        Category.RETURN_WINDOW to Regex("iade (?:suresi|icin son gun)|iade.*(?:son|kadar|bitiyor)|return by|return window|return deadline"),
        Category.PACKAGE_PICKUP to Regex("teslim al(?:iniz|in|maniz|mayi|acaksiniz)?|subeden teslim|subede (?:bekliyor|hazir)|subesine (?:ulasti|ulasmis)|kargoyu al|paketi al|pick up|pickup|ready for (?:collection|pickup)"),
        Category.SUBSCRIPTION_RENEWAL to Regex("aboneli.*yenilen|uyelik.*yenilen|yenileme tarihi|subscription.*renew|renews|renewal"),
        Category.BILL to Regex("fatura.*(?:son odeme|odeme tarihi|vade)|bill.*due|invoice.*due"),
        Category.PAYMENT_DUE to Regex("son odeme tarihi|payment (?:is )?due|odeme tarihi|vade tarihi|(?:odeme|odemesi|odemem|odememiz) (?:var|yapilacak|gerekiyor|lazim)|odenecek|odemeliyim|\\b(?:ode|odemeyi|odememi|yatir|yatirmayi|havale et)(?:\\s+(?:unutma|hatirla))?\\b"),
        Category.APPOINTMENT to Regex("randevu|doktor|disci|muayene|kontrol randevusu|toplanti|gorusme|mulakat|your appointment|appointment (?:is|on|at)"),
        Category.RESERVATION to Regex("rezervasyon|your reservation|reservation (?:confirmed|is|on|at)|booking (?:confirmed|is|on|at)"),
        Category.TRAVEL to Regex("ucus|(?:otobus|tren|ucak|feribot) sefer|sefer(?:i|iniz|imiz| no)|otobus kalk|tren kalk|check-in|boarding|your flight|flight departs"),
        Category.TICKET_EVENT to Regex("bilet|konser|etkinlik|sinema|tiyatro|your ticket|event starts"),
        Category.PACKAGE_DELIVERY to Regex("kargo.*(?:dagitim|teslim|gelecek|geliyor)|paket.*(?:teslim|gelecek|geliyor)|out for delivery|delivery (?:scheduled|expected)|package arrives"),
        Category.DEADLINE to Regex("son basvuru|basvuru.*son tarih|son gun|son tarih|suresi dol|bitis tarihi|taahhut.*(?:bitiyor|sona eriyor)|kadar.*(?:basvur|teslim et)|deadline|expires|expiry")
    )
    private val explicitReminder=Regex("\\b(?:unutma|hatirla|hatirlat|aklinda olsun|not (?:et|al)|kaydet|takvime ekle)\\b")
    private val genericAction=Regex("\\b(?:al|almayi|almaliyim|ara|aramayi|aramaliyim|aramalisin|aramalisiniz|arayacagim|arayacaksin|yaz|yazmayi|yazmaliyim|yazacagim|gonder|gondermeyi|gondermeliyim|gondermelisin|gonderecegim|gotur|goturmeyi|goturmeliyim|getir|getirmeyi|getirmeliyim|yap|yapmayi|yapacagim|yapmaliyim|yapmalisin|git|gitmeyi|gitmeliyim|gidecegim|gel|gelmeyi|gelmeliyim|gelecegim|ugra|ugramayi|ugramaliyim|basvur|basvurmayi|basvurmaliyim|basvurmalisin|basvurmalisiniz|basvurmaniz|teslim et|teslim etmeyi|teslim etmelisin|ilac(?:ini)? ic)\\b")
    fun classify(text:String,hasDate:Boolean=false,hasAmount:Boolean=false):List<Category> {
        val folded=MatchText.fold(text)
        val matches=rules.filter { it.second.containsMatchIn(folded) }.map { it.first }.toMutableList()
        if(Category.BILL !in matches && PaymentVocabulary.isBill(folded)) matches.add(0,Category.BILL)
        if(Category.PAYMENT_DUE !in matches && PaymentVocabulary.isDue(folded,hasDate,hasAmount)) {
            // A concrete dated amount for a billable subject is a payment even
            // when that subject (for example doctor/service) has another use.
            val afterBill=matches.indexOfFirst { it!=Category.BILL }
            matches.add(if(afterBill<0) matches.size else afterBill,Category.PAYMENT_DUE)
        }
        if(matches.isEmpty() && genericAction.containsMatchIn(folded) &&
            (explicitReminder.containsMatchIn(folded) || hasDate)) matches.add(Category.OTHER)
        return matches
    }
}
object DuplicateDetector {
    fun hash(value:String):String=MessageDigest.getInstance("SHA-256").digest(value.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
    fun duplicate(key:String,fingerprint:String,seenKey:String,seenFingerprint:String,seenAt:Long,now:Long):Boolean = now-seenAt in 0..ParserConfig.DEDUPE_TTL && (key==seenKey || fingerprint==seenFingerprint)
}
class RuleEngine(private val dateParser:DateParser=DateParser()) {
    fun parse(raw:RawNotification):Candidate? {
        val notificationText=NotificationTextComposer.compose(raw)
        val text=notificationText.normalizedMatchText
        if(text.isBlank() || NegativeSignals.reject(text)) return null
        val date=dateParser.parse(text,raw.postedAt,raw.locale,raw.zone)
        val entities=EntityExtractor.extract(text)
        val natural=TurkishIntentEngine.analyze(notificationText,date,entities,raw.requiresConfirmation)
        val categories=IntentClassifier.classify(text,date.instant!=null,entities.amount!=null)
        val category=categories.firstOrNull() ?: natural?.category ?: return null
        val features=FeatureExtractor.extract(text,date,entities,if(categories.isEmpty()) listOf(category) else categories)
        val institutionalScore=ConfidenceScorer.score(features,date,raw.postedAt)
        val score=maxOf(institutionalScore,natural?.confidence ?: 0.0)
        val threshold=if(natural!=null) ParserConfig.MESSAGE_REVIEW else ParserConfig.REVIEW
        if(score<threshold) return null
        val fingerprint=DuplicateDetector.hash("${raw.source}|${notificationText.foldedMatchText}|${date.instant}|$category")
        // Messaging apps commonly reuse one StatusBarNotification key for an
        // entire conversation. Include normalized content for conversational
        // notifications so a later, different message is not discarded as a
        // duplicate of an earlier message from the same chat.
        val keyMaterial=if(raw.requiresConfirmation) "${raw.key}|${notificationText.foldedMatchText}" else raw.key
        return Candidate(
            category=category,
            date=date,
            entities=entities,
            confidence=score,
            review=raw.requiresConfirmation || natural?.review==true || score<ParserConfig.HIGH,
            fingerprint=fingerprint,
            keyHash=DuplicateDetector.hash(keyMaterial),
            title=natural?.title.orEmpty(),
            intent=natural?.intent ?: taskIntentFor(category),
            actionVerb=natural?.actionVerb,
            actionObject=natural?.actionObject,
            temporalContext=natural?.temporalContext,
        )
    }

    private fun taskIntentFor(category:Category):TaskIntent=when(category) {
        Category.BILL,Category.PAYMENT_DUE->TaskIntent.PAYMENT_DUE
        Category.PACKAGE_DELIVERY,Category.PACKAGE_PICKUP->TaskIntent.DELIVERY_PICKUP
        Category.APPOINTMENT->TaskIntent.APPOINTMENT
        Category.RESERVATION->TaskIntent.RESERVATION
        Category.SUBSCRIPTION_RENEWAL,Category.RETURN_WINDOW,Category.DEADLINE->TaskIntent.DEADLINE
        Category.TICKET_EVENT,Category.TRAVEL->TaskIntent.TRAVEL
        Category.OTHER->TaskIntent.GENERAL_TASK
    }
}
