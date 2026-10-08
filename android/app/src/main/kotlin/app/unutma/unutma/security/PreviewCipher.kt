package app.unutma.unutma.security

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class PreviewCipher {
    private val alias="unutma.preview.v1"
    private fun store()=KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    @Synchronized private fun key():SecretKey {
        val existing=store().getKey(alias,null) as? SecretKey
        if(existing!=null) return existing
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias,KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).setKeySize(256).build())
        }.generateKey()
    }
    fun encrypt(value:String,cardId:String):ByteArray {
        val cipher=Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE,key())
        cipher.updateAAD(cardId.toByteArray())
        return byteArrayOf(1)+cipher.iv+cipher.doFinal(value.toByteArray(Charsets.UTF_8))
    }
    fun decrypt(value:ByteArray,cardId:String):String {
        require(value.size>=29 && value[0]==1.toByte())
        val cipher=Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE,key(),GCMParameterSpec(128,value.copyOfRange(1,13)))
        cipher.updateAAD(cardId.toByteArray())
        return String(cipher.doFinal(value.copyOfRange(13,value.size)),Charsets.UTF_8)
    }
    fun deleteKey() { store().deleteEntry(alias) }
}
