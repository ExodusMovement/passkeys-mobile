package foundation.passkeys.mobile

import android.content.Context
import android.net.Uri
import android.util.AttributeSet
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.browser.customtabs.CustomTabsIntent

class Passkeys @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : WebView(context, attrs, defStyleAttr) {

    private var customTabCallback: (() -> Unit)? = null

    init {
        setupWebView()
    }

    private fun setupWebView() {
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true

        addJavascriptInterface(JavaScriptBridge { onCloseSigner() }, "AndroidBridge")

        webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                openInCustomTab(request.url.toString())
                return true // We handle the URL ourselves
            }
        }
    }

    fun loadUrlWithBridge(url: String = "https://dev.passkeys.foundation/playground?relay") {
        loadUrl(url)
        injectJavaScript()
    }

    private fun injectJavaScript() {
        evaluateJavascript(
            """
            if (!window.uiControl) {
                window.uiControl = {};
            }
            window.uiControl.closeSigner = function() {
                AndroidBridge.closeSigner();
            };
        """
        ) { }
    }

    private fun openInCustomTab(url: String) {
        val uri = Uri.parse(url)
        val customTabsIntent = CustomTabsIntent.Builder().build()
        customTabsIntent.launchUrl(context, uri)
    }

    private fun onCloseSigner() {
        customTabCallback?.invoke()
    }

    fun setOnCloseSignerCallback(callback: () -> Unit) {
        this.customTabCallback = callback
    }
}

// JavaScript Bridge class for communication
class JavaScriptBridge(private val onClose: () -> Unit) {

    @android.webkit.JavascriptInterface
    fun closeSigner() {
        onClose()
    }
}
