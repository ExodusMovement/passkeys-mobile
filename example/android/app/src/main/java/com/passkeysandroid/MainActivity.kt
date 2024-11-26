package com.passkeysandroid

import foundation.passkeys.mobile.Passkeys

//import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private var reopenMainActivityIntent: PendingIntent? = null
    private lateinit var passkeys: Passkeys
    // private val CUSTOM_TAB_REQUEST_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        passkeys = findViewById(R.id.passkeys)
        passkeys.loadUrlWithBridge("https://wallet-d.passkeys.foundation/playground?relay")
        passkeys.setOnCloseSignerCallback {
            reopenMainActivity()
        }

        this.reopenMainActivityIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }


    // override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    //     super.onActivityResult(requestCode, resultCode, data)
    //     if (requestCode == CUSTOM_TAB_REQUEST_CODE) {
    //         if (resultCode == Activity.RESULT_CANCELED) {
    //             webView.reload()
    //         }
    //     }
    // }

    fun reopenMainActivity() {
        reopenMainActivityIntent?.send()
    }
}

