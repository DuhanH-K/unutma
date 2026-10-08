package app.unutma.unutma

import app.unutma.unutma.parser.*
import app.unutma.unutma.reminder.ReminderPlan
import app.unutma.unutma.notification.NotificationEligibility
import app.unutma.unutma.notification.MessagingNotificationDetector
import app.unutma.unutma.notification.MessagingGroupSummaryPreview
import org.junit.Assert.*
import org.junit.Test
import java.time.*
import java.util.Locale

class ParserTest {
    private val zone=ZoneId.of("Europe/Istanbul")
    private val posted=ZonedDateTime.of(2026,9,1,8,0,0,0,zone).toInstant().toEpochMilli()
    private fun parse(text:String,locale:Locale=Locale.forLanguageTag("tr-TR"),at:Long=posted)=RuleEngine().parse(RawNotification("test.source","key","",text,at,locale,zone))
    private fun date(text:String,at:Long=posted,locale:Locale=Locale.forLanguageTag("tr-TR"),z:ZoneId=zone)=DateParser().parse(TextNormalizer.normalize(text),at,locale,z)
    private fun local(e:DateEvidence)=e.instant?.let { Instant.ofEpochMilli(it).atZone(zone) }
    @Test fun TurkishRequiredFixtures() {
        assertEquals(Category.PAYMENT_DUE,parse("Son ödeme tarihi 12.09.2026")?.category)
        assertTrue(parse("Son ödeme tarihi 12.09.2026")!!.confidence>=.9)
        assertEquals(12,local(parse("Son ödeme tarihi 12.09.2026")!!.date)?.dayOfMonth)
        assertEquals(Category.APPOINTMENT,parse("Randevunuz 14 Eylül saat 10:30'dadır.")?.category)
        assertEquals(Category.PACKAGE_PICKUP,parse("Kargonuzu 3 iş günü içerisinde şubeden teslim alınız.")?.category)
    }
    @Test fun EnglishRequiredFixtures() {
        assertEquals(Category.SUBSCRIPTION_RENEWAL,parse("Your subscription renews September 17.",Locale.US)?.category)
        val c=parse("Your appointment is tomorrow at 2:30 PM.",Locale.US)!!
        assertEquals(Category.APPOINTMENT,c.category);assertEquals(14,local(c.date)?.hour);assertEquals(2,local(c.date)?.dayOfMonth)
        assertEquals(Category.PACKAGE_PICKUP,parse("Pick up your package within 3 business days.",Locale.US)?.category)
    }
    @Test fun PositiveNegativeAmbiguousForEveryActionableCategory() {
        val fixtures=listOf(
            Category.BILL to "Faturanızın son ödeme tarihi",
            Category.PAYMENT_DUE to "Payment due",
            Category.PACKAGE_DELIVERY to "Delivery expected",
            Category.PACKAGE_PICKUP to "Pick up your package",
            Category.APPOINTMENT to "Your appointment is",
            Category.RESERVATION to "Your reservation",
            Category.SUBSCRIPTION_RENEWAL to "Your subscription renews",
            Category.RETURN_WINDOW to "Return by",
            Category.TICKET_EVENT to "Your ticket",
            Category.TRAVEL to "Your flight",
            Category.DEADLINE to "Application deadline"
        )
        fixtures.forEach { (category,intent)->
            val positive=parse("$intent 12.09.2026",Locale.UK)!!
            assertEquals(intent,category,positive.category); assertFalse(intent,positive.review)
            assertNull(intent,parse("$intent 12.09.2026 discount offer",Locale.UK))
            assertTrue(intent,parse(intent,Locale.UK)!!.review)
        }
        assertNull(parse("Unrelated message on September 12",Locale.US))
    }
    @Test fun MarketingNeverCreatesTasks() {
        listOf("12.09.2026 tarihli kampanyamızı kaçırmayın","Yeni ürünlerimizi keşfedin, ücretsiz teslimat.","Bugüne özel %50 indirim.","Don't miss our September 17 sale.","Randevu fırsatı yarın", "Fatura ödeme kampanyası son ödeme tarihi 12.09.2026", "Free shipping delivery expected tomorrow").forEach { assertNull(it,parse(it)) }
    }
    @Test fun SmsNotificationsNeedAnActionableIntent() {
        fun sms(text:String)=RuleEngine().parse(
            RawNotification("com.google.android.apps.messaging","sms-key","Kız kardeşim",text,posted,Locale.forLanguageTag("tr-TR"),zone)
        )
        assertNull(sms("Merhaba, nasılsın?"))
        assertEquals(Category.PAYMENT_DUE,sms("Son ödeme tarihi 12.09.2026")?.category)
        val naturalPayment=sms("Abi yarın 500 TL doğalgaz ödemesi var")!!
        assertEquals(Category.PAYMENT_DUE,naturalPayment.category)
        assertEquals("500",naturalPayment.entities.amount)
        assertEquals("TRY",naturalPayment.entities.currency)
        assertFalse(naturalPayment.review)
    }
    @Test fun WhatsAppRelativePaymentAndConversationDedupe() {
        fun whatsapp(text:String)=RuleEngine().parse(
            RawNotification("com.whatsapp","same-conversation-key","Aşkım",text,posted,Locale.forLanguageTag("tr-TR"),zone,true)
        )
        val payment=whatsapp("Aşkım 2 gün sonra telefon faturasını unutma ödemeyi")!!
        assertEquals(Category.BILL,payment.category)
        assertEquals(LocalDate.of(2026,9,3),local(payment.date)?.toLocalDate())
        assertNotNull(payment.date.instant)
        assertNotEquals(payment.keyHash,whatsapp("Yarın internet ödemesini unutma")!!.keyHash)
        assertEquals(payment.keyHash,whatsapp("Aşkım 2 gün sonra telefon faturasını unutma ödemeyi")!!.keyHash)
    }
    @Test fun WhatsAppTurkishDayMonthWithoutYearIsNotParsedAsTomorrowClock() {
        val evening=ZonedDateTime.of(2026,9,12,19,0,0,0,zone).toInstant().toEpochMilli()
        val card=RuleEngine().parse(
            RawNotification(
                "com.whatsapp","relationship-chat","Kız kardeşim",
                "Aşkım 500 TL doğalgaz ödemesi var son ödemesi 14.09 unutma",
                evening,Locale.forLanguageTag("tr-TR"),zone,true,
            ),
        )!!
        assertEquals(Category.PAYMENT_DUE,card.category)
        assertEquals(LocalDate.of(2026,9,14),local(card.date)?.toLocalDate())
        assertEquals(9,local(card.date)?.hour)
        assertEquals("500",card.entities.amount)
        assertTrue(card.review)
    }
    @Test fun BroadTurkishPaymentLanguageCreatesReviewCandidates() {
        val fixtures=listOf(
            "İnternet ödemesi var" to Category.PAYMENT_DUE,
            "Annem internet ödemesi var dedi" to Category.PAYMENT_DUE,
            "Ayakkabı ödemesi var" to Category.PAYMENT_DUE,
            "Su faturası" to Category.BILL,
            "Doğalgaz borcu geldi" to Category.PAYMENT_DUE,
            "Spotify ödemesi var" to Category.PAYMENT_DUE,
            "YouTube Premium ücreti yarın" to Category.PAYMENT_DUE,
            "Çekin vadesi 12 Eylül" to Category.PAYMENT_DUE,
            "Senet ödemesi cuma" to Category.PAYMENT_DUE,
            "Kredi kartı ekstresi 5 Eylül 2.500 TL" to Category.PAYMENT_DUE,
            "MTV ikinci taksit 30 Eylül" to Category.PAYMENT_DUE,
            "Okul taksidi 15 Eylül" to Category.PAYMENT_DUE,
            "Market borcunu yarın öde" to Category.PAYMENT_DUE,
            "Ayakkabı 1200 TL cuma" to Category.PAYMENT_DUE,
            "Otomatik ödeme başarısız, yeniden öde" to Category.PAYMENT_DUE,
        )
        fixtures.forEach { (text,category)->
            val candidate=parse(text)
            assertNotNull(text,candidate)
            assertEquals(text,category,candidate?.category)
        }
        assertTrue(parse("İnternet ödemesi var")!!.review)
        assertNull(parse("İnternet bugün çok yavaş"))
        assertNull(parse("Ayakkabı indirimi yarın"))
        assertNull(parse("Spotify listemi dinle"))
        assertNull(parse("YouTube videosunu aç"))
        assertNull(parse("Senet filmini izledim"))
        assertNull(parse("Kredi kartı kampanyası"))
        assertNull(parse("Çek beni unutma"))
    }
    @Test fun PaymentSubjectMatrixSupportsUtilitiesShoppingDebtAndSubscriptions() {
        val subjects=listOf(
            "elektrik", "su", "doğalgaz", "doğgalgaz", "internet", "fiber",
            "telefon", "Turkcell", "Vodafone", "Türk Telekom", "Superonline",
            "Digiturk", "Tivibu", "D-Smart", "kira", "aidat", "site", "apartman",
            "kredi kartı", "kredi", "ek hesap", "çek", "senet", "vergi", "MTV",
            "emlak vergisi", "SGK", "Bağ-Kur", "HGS", "trafik cezası", "pasaport harcı",
            "okul", "üniversite", "kurs", "servis", "hastane", "doktor", "dişçi",
            "eczane", "ilaç", "ayakkabı", "giyim", "market", "bakkal", "yemek",
            "benzin", "mobilya", "beyaz eşya", "elektronik", "tamir", "bakım",
            "avukat", "muhasebe", "Spotify", "Spottify", "YouTube Premium", "Netflix",
            "Disney Plus", "Amazon Prime", "BluTV", "Exxen", "Gain", "Mubi", "iCloud",
            "Google One", "Microsoft 365", "Adobe", "PlayStation Plus", "Xbox Game Pass",
        )
        subjects.forEach { subject->
            assertEquals(subject,Category.PAYMENT_DUE,parse("$subject 450 TL yarın")?.category)
            assertEquals(subject,Category.PAYMENT_DUE,parse("$subject ödemesi var")?.category)
        }
    }
    @Test fun NaturalTurkishReminderFamilies() {
        val fixtures=listOf(
            Category.PAYMENT_DUE to "Yarın kirayı öde",
            Category.PAYMENT_DUE to "Taksiti 12 Eylül'de yatırmayı unutma",
            Category.PAYMENT_DUE to "Elektrik 500 TL 12.09.2026",
            Category.APPOINTMENT to "Yarın sabah dişçi var",
            Category.APPOINTMENT to "Cuma 14:00 toplantı",
            Category.RESERVATION to "Rezervasyonumuz yarın akşam 8'de",
            Category.TRAVEL to "Uçuş yarın 06:30",
            Category.TICKET_EVENT to "Konser bileti 15 Eylül saat 20:00",
            Category.PACKAGE_DELIVERY to "Kargo yarın teslim edilecek",
            Category.PACKAGE_PICKUP to "Paketi cuma şubeden teslim al",
            Category.SUBSCRIPTION_RENEWAL to "Üyelik 17 Eylül yenilenecek",
            Category.RETURN_WINDOW to "İade için son gün 20 Eylül",
            Category.DEADLINE to "Başvuru son günü 30 Eylül",
            Category.OTHER to "Yarın annemi ara",
            Category.OTHER to "İlacı 30 dakika sonra içmeyi unutma",
            Category.OTHER to "Haftaya belgeleri götürmeyi unutma",
        )
        fixtures.forEach { (category,text)->assertEquals(text,category,parse(text)?.category) }
    }
    @Test fun StrongReminderMarkerAcceptsGenericHomeworkWithoutMoney() {
        val card=parse("Pazartesi ödevi unutma")!!
        assertEquals(Category.OTHER,card.category)
        assertTrue(card.title,TurkishCharFold.fold(card.title.lowercase()).contains("odevi"))
        assertEquals(LocalDate.of(2026,9,7),local(card.date)?.toLocalDate())
        assertTrue(card.review)
    }
    @Test fun WhatsAppPoliteBuyRequestAndOrdinaryChatAreSeparated() {
        fun whatsapp(text:String)=RuleEngine().parse(
            RawNotification(
                "com.whatsapp","conversation", "Kardeşim",text,posted,
                Locale.forLanguageTag("tr-TR"),zone,true,
            ),
        )
        val request=whatsapp("Duhan abi bana yarın silgi alırmısınn")!!
        assertEquals(Category.OTHER,request.category)
        assertTrue(request.title,TurkishCharFold.fold(request.title.lowercase()).contains("silgi"))
        assertEquals(LocalDate.of(2026,9,2),local(request.date)?.toLocalDate())
        assertTrue(request.review)
        val freshRequest=whatsapp("Duhan abi yarın kırmızı silgi alır mısın test 47")!!
        assertEquals(Category.OTHER,freshRequest.category)
        assertTrue(freshRequest.title,TurkishCharFold.fold(freshRequest.title.lowercase()).contains("silgi"))
        assertEquals(LocalDate.of(2026,9,2),local(freshRequest.date)?.toLocalDate())
        assertTrue(freshRequest.review)
        assertNull(whatsapp("Kaşlarımı bu sefer ben de beğenmedim biliyon mu aşkımm"))
    }

    @Test fun branchPickupAndPastRelativeLanguage() {
        val pickup=parse("PTT: Gönderi 987654321 şubede bekliyor, 2 gün kaldı")
        assertEquals(Category.PACKAGE_PICKUP,pickup?.category)
        assertEquals("987654321",pickup?.entities?.identifier)
        assertNotNull(pickup?.date?.instant)

        val past=parse("PTT: Kargonuz 10 gün önce şubeye ulaşmıştı")
        assertNull(past)
    }
    @Test fun InformalAndAsciiTurkishVariants() {
        assertEquals(Category.PAYMENT_DUE,parse("Yarin 500 TL dogalgaz odemesi var")?.category)
        assertEquals(Category.OTHER,parse("Yarinnn annemi ara")?.category)
        assertEquals(Category.OTHER,parse("Aklinda olsun 15 Eylul evraklari teslim et")?.category)
        assertNull(parse("Beni unutma"))
        assertNull(parse("Yarın hava sıcak olacak"))
        assertNull(parse("Doğalgaz ödendi"))
        assertNull(parse("Yarın 500 TL indirim"))
    }
    @Test fun InflectedActionFamiliesRemainPrecisionFirst() {
        val fixtures=listOf(
            Category.OTHER to "Yarın annemi aramayı hatırla",
            Category.OTHER to "Cuma evrakı göndermelisin",
            Category.OTHER to "Haftaya ilacı getirmeliyim",
            Category.DEADLINE to "Yarın 18:00'e kadar başvurmalısınız",
            Category.DEADLINE to "Taahhüt 20 Ekim tarihinde bitiyor",
        )
        fixtures.forEach { (category,text)->assertEquals(text,category,parse(text)?.category) }
        listOf(
            "Arama sonuçları yarın güncellenecek",
            "Yarın alarm 08:00'de çalar",
            "Gönderi teslim edildi 12 Eylül",
            "Ödeme alındı, teşekkürler",
        ).forEach { assertNull(it,parse(it)) }
    }
    @Test fun CompletedIntentNeverCreatesFutureTask() {
        listOf("Faturanız ödenmiştir. Son ödeme tarihi 12.09.2026","Payment received. Payment due tomorrow", "Your order was delivered.", "Randevunuz iptal edildi 12.09.2026").forEach { assertNull(parse(it)) }
    }
    @Test fun NumericLocaleRules() {
        assertEquals(9,local(date("09/08/2026",locale=Locale.US))?.monthValue)
        assertEquals(8,local(date("09/08/2026",locale=Locale.UK))?.monthValue)
        assertTrue(date("09/08/2026",locale=Locale.ENGLISH).ambiguous)
    }
    @Test fun MonthNamesAndIsoDates() {
        listOf("8 Eylül","08 Eylül 2026","September 8","Sep 8","September 8, 2026","2026-09-08").forEach { assertEquals(it,8,local(date(it))?.dayOfMonth) }
    }
    @Test fun LeapAndInvalidDates() {
        assertTrue(date("29.02.2026").invalid);assertTrue(date("31.04.2026").invalid)
        assertEquals(29,local(date("29.02.2028"))?.dayOfMonth)
        assertTrue(date("12.09.2026 25:70").invalid)
        assertNull(date("99.99.2026").instant)
    }
    @Test fun MissingYearRollover() {
        val dec=ZonedDateTime.of(2026,12,30,12,0,0,0,zone).toInstant().toEpochMilli()
        assertEquals(2027,local(date("2 Ocak",dec))?.year)
        assertEquals(2027,local(date("January 2",dec))?.year)
    }
    @Test fun RelativeUsesPostedTimeNotWallClock() {
        val old=ZonedDateTime.of(2020,6,1,12,0,0,0,zone).toInstant().toEpochMilli()
        assertEquals(2020,local(date("yarın",old))?.year);assertEquals(2,local(date("yarın",old))?.dayOfMonth)
        assertEquals(1,local(date("bugün",old))?.dayOfMonth)
        assertEquals(4,local(date("3 gün içinde",old))?.dayOfMonth)
    }
    @Test fun ConversationalDateAndTimeForms() {
        assertEquals(LocalDate.of(2026,9,4),local(date("cuma"))?.toLocalDate())
        assertEquals(LocalDate.of(2026,9,8),local(date("gelecek hafta"))?.toLocalDate())
        assertEquals(LocalDate.of(2026,9,15),local(date("ayın 15'inde"))?.toLocalDate())
        assertEquals(20,local(date("yarın akşam 8'de"))?.hour)
        assertEquals(9,local(date("bugün sabah"))?.hour)
        assertEquals(10,local(date("2 saat sonra"))?.hour)
        assertEquals(8,local(date("30 dakika sonra"))?.hour)
        assertEquals(30,local(date("30 dakika sonra"))?.minute)
    }
    @Test fun BusinessDaysSkipWeekend() {
        assertEquals(LocalDate.of(2026,9,9),BusinessDays.add(LocalDate.of(2026,9,4),3))
    }
    @Test fun ConflictingAndPastDatesRequireReview() {
        assertTrue(parse("Son ödeme tarihi 12.09.2026 veya 14.09.2026")!!.review)
        assertTrue(parse("Randevunuz 01.01.2020")!!.review)
        assertTrue(parse("Randevunuz 12.09.2026 10:30 veya 14:30")!!.review)
        assertTrue(parse("Randevunuz 99.99.2026")!!.review)
    }
    @Test fun DstGapAndOverlapRequireReview() {
        val berlin=ZoneId.of("Europe/Berlin")
        assertTrue(date("29.03.2026 02:30",z=berlin).ambiguous)
        assertTrue(date("25.10.2026 02:30",z=berlin).ambiguous)
    }
    @Test fun HourOnlyAndUnverifiedTimes() {
        assertEquals(14,local(date("tomorrow at 2 PM",locale=Locale.US))?.hour)
        assertTrue(date("yarın saat 25").ambiguous)
    }
    @Test fun TimeZoneConversionIsExplicit() {
        val utc=date("12.09.2026 10:30",z=ZoneId.of("UTC"))
        val istanbul=date("12.09.2026 10:30")
        assertEquals(3*3600000L,utc.instant!!-istanbul.instant!!)
    }
    @Test fun UnicodeNormalizationAndAmounts() {
        assertEquals("iş günü",TextNormalizer.normalize(" İŞ   GÜNÜ "))
        val e=EntityExtractor.extract(TextNormalizer.normalize("Tutar ₺549,90 takip no: ABC12345 adres: İstanbul"))
        assertEquals("549,90",e.amount);assertEquals("TRY",e.currency);assertEquals("abc12345",e.identifier);assertNotNull(e.location)
    }
    @Test fun DedupeWhitespaceAndDatesAndTtl() {
        val a=parse("Son ödeme tarihi 12.09.2026")!!
        val b=parse("Son   ödeme tarihi\n12.09.2026")!!
        assertEquals(a.fingerprint,b.fingerprint)
        assertNotEquals(a.fingerprint,parse("Son ödeme tarihi 13.09.2026")!!.fingerprint)
        assertTrue(DuplicateDetector.duplicate("a","b","a","c",100,200))
        assertFalse(DuplicateDetector.duplicate("a","b","a","b",100,ParserConfig.DEDUPE_TTL+101))
    }
    @Test fun ReminderPolicies() {
        val now=1_000_000L;val due=now+2*86400000
        assertEquals(2,ReminderPlan.calculate("ACTIVE",due,listOf(1440,60),null,now).size)
        assertTrue(ReminderPlan.calculate("DONE",due,listOf(60),null,now).isEmpty())
        assertTrue(ReminderPlan.calculate("ARCHIVED",due,listOf(60),null,now).isEmpty())
        assertTrue(ReminderPlan.calculate("REVIEW",due,listOf(60),null,now).isEmpty())
        assertTrue(ReminderPlan.calculate("ACTIVE",now-1,listOf(0),null,now).isEmpty())
        assertEquals(1,ReminderPlan.calculate("ACTIVE",due,listOf(60,60),null,now).size)
        assertEquals(now+100,ReminderPlan.calculate("SNOOZED",due,listOf(60),now+100,now).single().at)
        assertTrue(ReminderPlan.calculate("ACTIVE",null,listOf(0),null,now).isEmpty())
        val catchUp=ReminderPlan.calculate("ACTIVE",now+12*3600000,listOf(1440),null,now).single()
        assertEquals(now+ReminderPlan.CATCH_UP_DELAY_MILLIS,catchUp.at)
    }
    @Test fun FiltersDropOngoingSummaryOwnAndProgress() {
        assertFalse(NotificationEligibility.eligible(2,null,false,false))
        assertFalse(NotificationEligibility.eligible(512,null,false,false))
        assertTrue(NotificationEligibility.eligible(512,null,false,false,true))
        assertFalse(NotificationEligibility.eligible(0,null,false,true))
        assertFalse(NotificationEligibility.eligible(0,null,true,false))
        assertFalse(NotificationEligibility.eligible(0,"transport",false,false))
        assertTrue(NotificationEligibility.eligible(0,null,false,false))
    }
    @Test fun WhatsAppIsConversationalEvenWhenOemOmitsMessageMetadata() {
        assertTrue(MessagingNotificationDetector.isConversational("com.whatsapp",null,false,false))
        assertTrue(MessagingNotificationDetector.isConversational("com.whatsapp.w4b",null,false,false))
        assertTrue(MessagingNotificationDetector.isConversational("unknown",android.app.Notification.CATEGORY_MESSAGE,false,false))
        assertFalse(MessagingNotificationDetector.isConversational("com.example.shop",null,false,false))
    }
    @Test fun WhatsAppGroupSummaryUsesOnlyLatestSenderAndMessage() {
        val preview=MessagingGroupSummaryPreview.split("\u200eKız kardeşim: Abicim yarın doğalgaz ödemesi var 500 TL unutma")
        assertEquals("Kız kardeşim",preview?.first)
        assertEquals("Abicim yarın doğalgaz ödemesi var 500 TL unutma",preview?.second)
    }
}
