package com.passkeysandroid

import foundation.passkeys.mobile.PasskeysMobile

import android.app.PendingIntent
import android.os.Bundle
import android.widget.RelativeLayout
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private var reopenMainActivityIntent: PendingIntent? = null
    private lateinit var passkeys: PasskeysMobile

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val rootLayout = findViewById<RelativeLayout>(R.id.root_layout)
        passkeys = PasskeysMobile(this, null, 0, this)

        val layoutParams = RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.MATCH_PARENT,
            RelativeLayout.LayoutParams.MATCH_PARENT
        )
        passkeys.layoutParams = layoutParams

        rootLayout.addView(passkeys)
    }
}
