package com.passkeysandroid

import foundation.passkeys.mobile.PasskeysMobile

import android.app.PendingIntent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.RelativeLayout
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private var reopenMainActivityIntent: PendingIntent? = null
    private lateinit var passkeys: PasskeysMobile

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val rootLayout = findViewById<RelativeLayout>(R.id.root_layout)

        passkeys = PasskeysMobile(this, null, 0, this).apply {
            visibility = View.GONE // Initially hide the Passkeys view
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.MATCH_PARENT
            )
        }
        passkeys.visibility = View.GONE
        rootLayout.addView(passkeys)

        val connectButton = Button(this).apply {
            text = "Connect"
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.WRAP_CONTENT,
                RelativeLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                addRule(RelativeLayout.CENTER_IN_PARENT)
            }
            setOnClickListener {
                passkeys.callMethod("connect", null) { result ->
                    result.fold(
                        onSuccess = { println(it) },
                        onFailure = { println(it) }
                    )
                }
            }
        }

        rootLayout.addView(connectButton)
    }
}
