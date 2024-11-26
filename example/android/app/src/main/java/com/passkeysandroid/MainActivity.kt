package com.passkeysandroid

import foundation.passkeys.mobile.Passkeys

import android.app.PendingIntent
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private var reopenMainActivityIntent: PendingIntent? = null
    private lateinit var passkeys: Passkeys

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

    fun reopenMainActivity() {
        reopenMainActivityIntent?.send()
    }
}

