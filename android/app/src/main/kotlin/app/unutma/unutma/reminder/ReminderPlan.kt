package app.unutma.unutma.reminder

data class ReminderSlot(val id:String,val at:Long)
object ReminderPlan {
    const val SNOOZE_MILLIS = 24*60*60*1000L
    const val MAX_LATE_MILLIS = 24*60*60*1000L
    const val CATCH_UP_DELAY_MILLIS = 5_000L
    fun calculate(status:String,due:Long?,offsets:List<Long>,snooze:Long?,now:Long):List<ReminderSlot> {
        if(status !in listOf("ACTIVE","SNOOZED")) return emptyList()
        if(status=="SNOOZED") return if(snooze!=null && snooze>now) listOf(ReminderSlot("snooze",snooze)) else emptyList()
        if(due==null || due<=now) return emptyList()
        val valid=offsets.distinct().filter { it in 0..525600 }
        val future=valid.map { ReminderSlot(it.toString(),due-it*60000) }.filter { it.at>now }
        // If a card is created or confirmed after an offset has passed, do not
        // silently lose that reminder. Deliver the closest missed threshold
        // once, shortly after confirmation; receipts suppress later duplicates.
        val closestMissed=valid.filter { due-it*60000<=now }.minOrNull()
            ?.let { ReminderSlot(it.toString(),now+CATCH_UP_DELAY_MILLIS) }
        return listOfNotNull(closestMissed)+future
    }
    fun defaults(category:String):List<Long> = when(category) {
        "APPOINTMENT"->listOf(1440,60)
        "RETURN_WINDOW"->listOf(4320,1440)
        else->listOf(1440)
    }
}
