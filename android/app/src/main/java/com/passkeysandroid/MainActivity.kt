package com.passkeysandroid

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import androidx.browser.customtabs.CustomTabsIntent

class MainActivity : AppCompatActivity() {

    private var closeCustomTabIntent: PendingIntent? = null
    private lateinit var webView: WebView
    private val CUSTOM_TAB_REQUEST_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        webView = findViewById(R.id.webView)
        setupWebView(webView)

        webView.loadUrl("https://dev.passkeys.foundation/playground?relay")
        webView.evaluateJavascript("""
            if (!window.uiControl) {
                window.uiControl = {};
            }
            window.uiControl.closeSigner = function() {
                AndroidBridge.closeSigner();
            };
        """) { }

        this.closeCustomTabIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun setupWebView(webView: WebView) {
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.addJavascriptInterface(JavaScriptBridge(this), "AndroidBridge")

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                openInCustomTab(this@MainActivity, request.url.toString())
                return true // indicate we handled the URL ourselves
            }
        }
    }

    private fun openInCustomTab(context: Context, url: String) {
        val uri = Uri.parse(url)
        val customTabsIntent = CustomTabsIntent.Builder().build()

        val intent = customTabsIntent.intent
        intent.data = uri
        startActivityForResult(intent, CUSTOM_TAB_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CUSTOM_TAB_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_CANCELED) {
                webView.reload()
            }
        }
    }

    fun onCloseSigner() {
        closeCustomTabIntent?.send()
    }
}

// JavaScript Bridge class for communication
class JavaScriptBridge(private val activity: MainActivity) {

    @android.webkit.JavascriptInterface
    fun closeSigner() {
        activity.runOnUiThread {
            activity.onCloseSigner()
        }
    }
}
