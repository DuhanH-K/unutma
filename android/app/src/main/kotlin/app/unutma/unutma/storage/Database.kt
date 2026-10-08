package app.unutma.unutma.storage

import android.content.Context
import androidx.room.*

@Entity(tableName="cards", indices=[Index("status"),Index("dueAt"),Index("category"),Index("sourcePackage"),Index("fingerprint"),Index("keyHash"),Index("createdAt")])
data class CardEntity(
    @PrimaryKey val id:String,
    val category:String, val title:String, val sourceLabel:String, val sourcePackage:String,
    val dueAt:Long?, val amount:String?, val currency:String?, val status:String,
    val confidence:Double, val createdAt:Long, val completedAt:Long?=null,
    val reminderOffsets:String="1440", val snoozedUntil:Long?=null,
    val parserVersion:Int=1, val note:String?=null, val revision:Long=1,
    val fingerprint:String, val keyHash:String, val encryptedPreview:ByteArray?=null
)
@Entity(tableName="sources")
data class SourceEntity(@PrimaryKey val packageName:String,val label:String,val ignored:Boolean=false)
@Entity(tableName="reminder_receipts", primaryKeys=["cardId","revision","slot"])
data class ReminderReceipt(val cardId:String,val revision:Long,val slot:String)
@Dao
interface CardDao {
    @Query("SELECT * FROM cards ORDER BY dueAt ASC, createdAt DESC") fun observe():kotlinx.coroutines.flow.Flow<List<CardEntity>>
    @Query("SELECT * FROM cards ORDER BY dueAt ASC, createdAt DESC") suspend fun all():List<CardEntity>
    @Query("SELECT * FROM cards WHERE id=:id") suspend fun get(id:String):CardEntity?
    @Insert(onConflict=OnConflictStrategy.REPLACE) suspend fun put(card:CardEntity)
    @Query("SELECT * FROM cards WHERE createdAt >= :since AND status IN ('REVIEW','ACTIVE','SNOOZED') AND (keyHash=:key OR fingerprint=:fingerprint) ORDER BY createdAt DESC LIMIT 1") suspend fun duplicate(key:String,fingerprint:String,since:Long):CardEntity?
    @Query("SELECT * FROM sources ORDER BY label") suspend fun sources():List<SourceEntity>
    @Query("SELECT * FROM sources WHERE packageName=:pkg") suspend fun source(pkg:String):SourceEntity?
    @Insert(onConflict=OnConflictStrategy.REPLACE) suspend fun putSource(source:SourceEntity)
    @Insert(onConflict=OnConflictStrategy.IGNORE) suspend fun receipt(receipt:ReminderReceipt):Long
    @Query("SELECT COUNT(*) FROM reminder_receipts WHERE cardId=:id AND revision=:revision AND slot=:slot") suspend fun delivered(id:String,revision:Long,slot:String):Int
    @Query("DELETE FROM reminder_receipts WHERE cardId=:id AND revision=:revision AND slot=:slot") suspend fun forgetDelivery(id:String,revision:Long,slot:String)
    @Query("UPDATE cards SET encryptedPreview=NULL WHERE id=:id") suspend fun clearPreview(id:String)
    @Query("DELETE FROM cards WHERE status IN ('DONE','ARCHIVED','EXPIRED') AND COALESCE(completedAt,createdAt)<:before") suspend fun purgeHistory(before:Long)
    @Query("DELETE FROM reminder_receipts WHERE cardId NOT IN (SELECT id FROM cards)") suspend fun purgeReceipts()
    @Query("DELETE FROM cards") suspend fun clearCards()
    @Query("DELETE FROM sources") suspend fun clearSources()
    @Query("DELETE FROM reminder_receipts") suspend fun clearReceipts()
}
@Database(entities=[CardEntity::class,SourceEntity::class,ReminderReceipt::class],version=1,exportSchema=true)
abstract class UnutmaDatabase:RoomDatabase() {
    abstract fun cards():CardDao
    companion object {
        @Volatile private var instance:UnutmaDatabase?=null
        fun get(context:Context):UnutmaDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(context.applicationContext,UnutmaDatabase::class.java,"unutma.db").build().also { instance=it }
        }
    }
}
