// MainActivity.kt
package com.passkeysandroid

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebSettings
import androidx.appcompat.app.AppCompatActivity
import androidx.browser.customtabs.CustomTabsIntent

class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView
    private val CUSTOM_TAB_REQUEST_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        webView = findViewById(R.id.webView)
        setupWebView(webView)

        webView.loadUrl("https://passkeys.foundation/playground?relay&returnTo=passkeys%3A%2F%2F%0A")
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.data?.let { uri ->
            if (uri.scheme == "passkeys") {
                webView.reload()
            }
        }
    }

    private fun setupWebView(webView: WebView) {
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
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
}
