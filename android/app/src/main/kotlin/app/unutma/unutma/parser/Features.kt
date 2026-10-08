package app.unutma.unutma.parser

data class SignalFeatures(
    val hasDate:Boolean,val hasTime:Boolean,val hasAmount:Boolean,
    val hasPayment:Boolean,val hasAppointment:Boolean,val hasDelivery:Boolean,
    val hasPickup:Boolean,val hasRenewal:Boolean,val hasReturn:Boolean,
    val hasReservation:Boolean,val hasTravel:Boolean,val hasDeadline:Boolean,
    val negative:Boolean,val categoryConflict:Boolean
)
object FeatureExtractor {
    fun extract(text:String,date:DateEvidence,entities:Entities,categories:List<Category>):SignalFeatures {
        val primary=categories.firstOrNull()
        return SignalFeatures(date.instant!=null,date.hasTime,entities.amount!=null,
            categories.any {it==Category.BILL||it==Category.PAYMENT_DUE},Category.APPOINTMENT in categories,
            Category.PACKAGE_DELIVERY in categories,Category.PACKAGE_PICKUP in categories,
            Category.SUBSCRIPTION_RENEWAL in categories,Category.RETURN_WINDOW in categories,
            Category.RESERVATION in categories,Category.TRAVEL in categories,Category.DEADLINE in categories,
            NegativeSignals.reject(text),categories.filterNot { primary==Category.BILL && it==Category.PAYMENT_DUE }.size>1)
    }
}
object ConfidenceScorer {
    fun score(features:SignalFeatures,date:DateEvidence,postedAt:Long):Double {
        if(features.negative)return 0.0
        var value=ParserConfig.INTENT_WEIGHT
        if(features.hasDate&&!date.ambiguous&&!date.invalid)value+=ParserConfig.DATE_WEIGHT
        if(features.hasAmount)value+=ParserConfig.AMOUNT_WEIGHT
        if(features.categoryConflict||date.ambiguous||date.invalid||(date.instant!=null&&date.instant<postedAt))value=ParserConfig.INTENT_WEIGHT
        return value.coerceIn(0.0,1.0)
    }
}
