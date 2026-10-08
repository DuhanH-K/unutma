package app.unutma.unutma.parser

import java.time.*
import java.util.Locale

object BusinessDays {
    fun add(date: LocalDate, count: Int): LocalDate {
        var result = date; var left = count
        while (left > 0) { result = result.plusDays(1); if (result.dayOfWeek != DayOfWeek.SATURDAY && result.dayOfWeek != DayOfWeek.SUNDAY) left-- }
        return result
    }
}

class DateParser {
    private val months = listOf(
        "ocak|january|jan", "subat|february|feb", "mart|march|mar", "nisan|april|apr",
        "mayis|may", "haziran|june|jun", "temmuz|july|jul", "agustos|august|aug",
        "eylul|september|sep|sept", "ekim|october|oct", "kasim|november|nov", "aralik|december|dec")
    private val weekdays = listOf(
        DayOfWeek.MONDAY to "pazartesi|monday",
        DayOfWeek.TUESDAY to "sali|tuesday",
        DayOfWeek.WEDNESDAY to "carsamba|wednesday",
        DayOfWeek.THURSDAY to "persembe|thursday",
        DayOfWeek.FRIDAY to "cuma|friday",
        DayOfWeek.SATURDAY to "cumartesi|saturday",
        DayOfWeek.SUNDAY to "pazar|sunday",
    )
    fun parse(text: String, postedAt: Long, locale: Locale, zone: ZoneId): DateEvidence {
        val posted = Instant.ofEpochMilli(postedAt).atZone(zone)
        val base = posted.toLocalDate()
        val match = MatchText.fold(text)
        Regex("(?<!\\d)(\\d{1,3})\\s*(dakika|minutes?|saat|hours?)\\s*(?:sonra|icinde|later|from now|within)").find(match)?.let {
            val count=it.groupValues[1].toLong()
            val instant=if(it.groupValues[2].startsWith("dakika") || it.groupValues[2].startsWith("minute")) posted.plusMinutes(count) else posted.plusHours(count)
            return DateEvidence(instant.toInstant().toEpochMilli(),true)
        }
        val dates = mutableListOf<LocalDate>()
        var invalid = false
        var ambiguous = false
        fun add(year: Int?, month: Int, day: Int) {
            try {
                var d = LocalDate.of(year ?: base.year, month, day)
                if (year == null && d.isBefore(base)) d = d.plusYears(1)
                dates.add(d)
            } catch (_: DateTimeException) { invalid = true }
        }
        val numeric = Regex("(?<!\\d)(\\d{1,2})([./])(\\d{1,2})[./](\\d{4})(?!\\d)")
        numeric.findAll(match).forEach { m ->
            val a=m.groupValues[1].toInt(); val b=m.groupValues[3].toInt()
            val us=locale.country == "US" && m.groupValues[2] == "/"
            if (locale.language == "en" && locale.country.isEmpty() && a <= 12 && b <= 12 && a != b) ambiguous=true
            add(m.groupValues[4].toInt(), if(us) a else b, if(us) b else a)
        }
        // Turkish messages frequently omit the year ("son ödemesi 14.09").
        // Keep these spans out of the clock parser below; otherwise 14.09 is
        // interpreted as 14:09 and may roll over to the following day.
        val shortNumeric = Regex("(?<!\\d)(\\d{1,2})([./])(\\d{1,2})(?![./]\\d)(?!\\d)")
        val shortNumericMatches=shortNumeric.findAll(match).filter { m ->
            val a=m.groupValues[1].toInt();val b=m.groupValues[3].toInt()
            val us=locale.country=="US" && m.groupValues[2]=="/"
            val month=if(us) a else b;val day=if(us) b else a
            day in 1..31 && month in 1..12 && runCatching {
                LocalDate.of(base.year,month,day)
            }.isSuccess
        }.toList()
        shortNumericMatches.forEach { m ->
            val a=m.groupValues[1].toInt();val b=m.groupValues[3].toInt()
            val us=locale.country=="US" && m.groupValues[2]=="/"
            add(null,if(us) a else b,if(us) b else a)
        }
        Regex("(?<!\\d)(\\d{4})-(\\d{2})-(\\d{2})(?!\\d)").findAll(match).forEach { add(it.groupValues[1].toInt(),it.groupValues[2].toInt(),it.groupValues[3].toInt()) }
        months.forEachIndexed { index, names ->
            Regex("(?<![\\p{L}\\d])(\\d{1,2}) (?:$names)(?:[ ,]+(\\d{4}))?(?![\\p{L}\\d])").findAll(match).forEach { add(it.groupValues[2].toIntOrNull(),index+1,it.groupValues[1].toInt()) }
            Regex("(?<!\\p{L})(?:$names) (\\d{1,2})(?:st|nd|rd|th)?(?:[ ,]+(\\d{4}))?(?!\\d)").findAll(match).forEach { add(it.groupValues[2].toIntOrNull(),index+1,it.groupValues[1].toInt()) }
        }
        Regex("(?:ayin\\s+)?(\\d{1,2})(?:['’]?(?:inde|inda|si|i))").find(match)?.let { day ->
            var target=base.withDayOfMonth(1)
            if(match.contains("gelecek ay") || match.contains("next month")) target=target.plusMonths(1)
            try {
                target=target.withDayOfMonth(day.groupValues[1].toInt())
                if(target.isBefore(base) && !match.contains("gelecek ay") && !match.contains("next month")) target=target.plusMonths(1)
                dates.add(target)
            } catch (_:DateTimeException) { invalid=true }
        }
        val relative=Regex("(?:(within|in) )?(\\d{1,3}) (is gunu|business days?|gun|days?)(?: (sonra|later|icinde|icerisinde|kaldi|left))?")
            .findAll(match)
            .firstOrNull { it.groupValues[1].isNotEmpty() || it.groupValues[4].isNotEmpty() }
        val weeks=Regex("(?<!\\d)(\\d{1,2}) (?:hafta|weeks?) (?:sonra|later)").find(match)
        when {
            relative != null -> {
                val count=relative.groupValues[2].toInt()
                dates.add(if(relative.groupValues[3].contains("is gunu") || relative.groupValues[3].contains("business")) BusinessDays.add(base,count) else base.plusDays(count.toLong()))
            }
            weeks != null -> dates.add(base.plusWeeks(weeks.groupValues[1].toLong()))
            match.contains("obur gun") || match.contains("ertesi gun") || match.contains("day after tomorrow") -> dates.add(base.plusDays(2))
            Regex("\\b(yarin|yarina kadar|tomorrow)\\b").containsMatchIn(match) -> dates.add(base.plusDays(1))
            Regex("\\b(bugun|today|bu aksam|bu gece|bu sabah|bu oglen)\\b").containsMatchIn(match) -> dates.add(base)
            Regex("\\b(haftaya|gelecek hafta|onumuzdeki hafta|next week)\\b").containsMatchIn(match) -> dates.add(base.plusWeeks(1))
            Regex("\\b(hafta sonu|weekend)\\b").containsMatchIn(match) -> {
                var delta=(DayOfWeek.SATURDAY.value-base.dayOfWeek.value+7)%7
                if(delta==0) delta=7
                dates.add(base.plusDays(delta.toLong()))
            }
            Regex("\\b(?:ayin sonuna|end of (?:the )?month) kadar\\b").containsMatchIn(match) -> dates.add(base.withDayOfMonth(base.lengthOfMonth()))
        }
        if(dates.isEmpty()) weekdays.forEach { (day,names) ->
            if(Regex("\\b(?:bu |gelecek |onumuzdeki |next )?(?:$names)(?:ya|ye)?(?: kadar)?\\b").containsMatchIn(match)) {
                var delta=(day.value-base.dayOfWeek.value+7)%7
                if(delta==0 && !Regex("\\bbu (?:$names)\\b").containsMatchIn(match)) delta=7
                dates.add(base.plusDays(delta.toLong()))
            }
        }
        fun isShortDate(range:IntRange)=shortNumericMatches.any { candidate ->
            range.first<=candidate.range.last && candidate.range.first<=range.last
        }
        val timesWithPeriod = Regex("(?<![\\d.])(\\d{1,2})(?::|\\.)(\\d{2})\\s*(am|pm)\\b")
            .findAll(match).filterNot { isShortDate(it.range) }.toList()
        val times = if(timesWithPeriod.isNotEmpty()) timesWithPeriod else
            Regex("(?<![\\d.])(\\d{1,2})(?::|\\.)(\\d{2})(?![\\d.])")
                .findAll(match).filterNot { isShortDate(it.range) }.toList()
        var time=LocalTime.of(9,0)
        var hasTime=false
        if (times.isNotEmpty()) {
            val m=times.first(); var h=m.groupValues[1].toInt(); val minute=m.groupValues[2].toInt()
            val ampm=m.groupValues.getOrNull(3).orEmpty()
            if (ampm.isNotEmpty()) { if(h !in 1..12) invalid=true; h=h%12 + if(ampm=="pm")12 else 0 }
            try { time=LocalTime.of(h,minute) } catch (_: DateTimeException) { invalid=true }
            if(times.map { it.value }.distinct().size>1) ambiguous=true
            hasTime=true
        } else {
            val hourOnly=Regex("(?<!\\d)(\\d{1,2})\\s*(am|pm)\\b").find(match)
            if(hourOnly!=null) {
                val h=hourOnly.groupValues[1].toInt()
                if(h !in 1..12)invalid=true else time=LocalTime.of(h%12+if(hourOnly.groupValues[2]=="pm")12 else 0,0)
                hasTime=true
            } else {
                val spoken=Regex("(?:\\b(?:saat|at)\\s*(\\d{1,2})(?![:.\\d])|(?<!\\d)(\\d{1,2})['’]?\\s*(?:te|ta|de|da)\\b)").find(match)
                if(spoken!=null) {
                    var h=spoken.groupValues[1].ifEmpty { spoken.groupValues[2] }.toInt()
                    val morning=Regex("\\b(?:sabah|morning)\\b").containsMatchIn(match)
                    val noon=Regex("\\b(?:oglen|noon)\\b").containsMatchIn(match)
                    val evening=Regex("\\b(?:aksam|gece|evening|tonight)\\b").containsMatchIn(match)
                    val periodUnspecified = !morning && !noon && !evening
                    if((noon||evening) && h in 1..11) h+=12
                    else if(!morning && h in 1..7) h+=12
                    if(h !in 0..23) { invalid=true;ambiguous=true } else time=LocalTime.of(h,0)
                    if(periodUnspecified) ambiguous=true
                    hasTime=true
                } else when {
                    Regex("\\b(?:sabah|morning)\\b").containsMatchIn(match) -> { time=LocalTime.of(9,0);hasTime=true }
                    Regex("\\b(?:oglen|noon)\\b").containsMatchIn(match) -> { time=LocalTime.of(12,0);hasTime=true }
                    Regex("\\b(?:aksam|evening)\\b").containsMatchIn(match) -> { time=LocalTime.of(19,0);hasTime=true }
                    Regex("\\b(?:gece|tonight)\\b").containsMatchIn(match) -> { time=LocalTime.of(21,0);hasTime=true }
                }
            }
        }
        if(dates.isEmpty() && hasTime && !invalid) {
            var inferred = base
            if(LocalDateTime.of(inferred,time).isBefore(posted.toLocalDateTime())) inferred=inferred.plusDays(1)
            dates.add(inferred)
            ambiguous=true
        }
        val unique=dates.distinct()
        if(unique.size>1) ambiguous=true
        val date=unique.firstOrNull() ?: return DateEvidence(null,hasTime,ambiguous,invalid)
        val local=LocalDateTime.of(date,time)
        // DST gaps and overlaps must be reviewed rather than silently shifted.
        if(zone.rules.getValidOffsets(local).size != 1) ambiguous=true
        if(date.isBefore(base)) ambiguous=true
        return DateEvidence(if(invalid) null else local.atZone(zone).toInstant().toEpochMilli(),hasTime,ambiguous,invalid)
    }
}
