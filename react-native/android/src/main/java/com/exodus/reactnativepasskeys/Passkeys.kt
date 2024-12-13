package com.exodus.reactnativepasskeys

import android.app.Activity
import com.facebook.react.uimanager.ThemedReactContext
import android.content.Intent
import android.net.Uri
import android.util.AttributeSet
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.browser.customtabs.CustomTabsIntent

class Passkeys @JvmOverloads constructor(
    context: ThemedReactContext,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    private val activity: Activity,
    private val initialUrl: String = "https://dev.passkeys.foundation/playground?relay"
) : WebView(context, attrs, defStyleAttr) {

    companion object {
        const val CUSTOM_TAB_REQUEST_CODE = 100

        private var instance: Passkeys? = null

        fun getInstance(): Passkeys? {
            return instance
        }

        private var customTabCallback: (() -> Unit)? = null

        fun setOnCloseSignerCallback(callback: () -> Unit) {
            customTabCallback = callback
        }
    }

    init {
        // if (instance != null) throw IllegalStateException("Only one instance if Passkeys is allowed") // todo
        instance = this

        setupWebView()
        loadUrlWithBridge(initialUrl)
    }

    private fun setupWebView() {
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true

        addJavascriptInterface(
            JavaScriptBridge(
                onClose = { onCloseSigner() },
                onOpen = { url -> onOpenSigner(url) }
            ),
            "AndroidBridge"
        )

        webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                openInCustomTab(request.url.toString())
                return true // We handle the URL ourselves
            }
        }
    }

    private fun loadUrlWithBridge(url: String) {
        loadUrl(url)
        injectJavaScript()
    }

    private fun injectJavaScript() {
        evaluateJavascript(
            """
            if (!window.nativeBridge) {
                window.nativeBridge = {};
            }
            window.nativeBridge.closeSigner = function() {
                AndroidBridge.closeSigner();
            };
            window.nativeBridge.openSigner = function(url) {
                AndroidBridge.openSigner(url);
            };
        """
        ) { }
    }

    private fun onCloseSigner() {
        customTabCallback?.invoke()
    }

    private fun onOpenSigner(url: String) {
        openInCustomTab(url)
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode == CUSTOM_TAB_REQUEST_CODE) {
            reload()
        }
    }

    fun openInCustomTab(url: String) {
        val uri = Uri.parse(url)
        val customTabsIntent = CustomTabsIntent.Builder().build()
        val intent = customTabsIntent.intent
        intent.data = uri

        activity.startActivityForResult(intent, CUSTOM_TAB_REQUEST_CODE)
    }
}

class JavaScriptBridge(private val onClose: () -> Unit, private val onOpen: (String) -> Unit) {
    @android.webkit.JavascriptInterface
    fun closeSigner() {
        onClose()
    }

    @android.webkit.JavascriptInterface
    fun openSigner(url: String) {
        onOpen(url)
    }
}
