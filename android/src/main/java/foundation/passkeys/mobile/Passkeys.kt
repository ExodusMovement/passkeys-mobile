package foundation.passkeys.mobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.AttributeSet
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.browser.customtabs.CustomTabsIntent

class Passkeys @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : WebView(context, attrs, defStyleAttr) {

    private var customTabCallback: (() -> Unit)? = null
    private var onActivityResultCallback: ((requestCode: Int, resultCode: Int, data: Intent?) -> Unit)? = null

    companion object {
        const val CUSTOM_TAB_REQUEST_CODE = 100
    }

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

    private fun onCloseSigner() {
        customTabCallback?.invoke()
    }

    fun setOnCloseSignerCallback(callback: () -> Unit) {
        this.customTabCallback = callback
    }

    fun openInCustomTab(url: String) {
        val uri = Uri.parse(url)
        val customTabsIntent = CustomTabsIntent.Builder().build()
        val intent = customTabsIntent.intent
        intent.data = uri

        if (context is Activity) {
            (context as Activity).startActivityForResult(intent, CUSTOM_TAB_REQUEST_CODE)
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode == CUSTOM_TAB_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_CANCELED) {
                reload()
            }
        }
    }
}

class JavaScriptBridge(private val onClose: () -> Unit) {
    @android.webkit.JavascriptInterface
    fun closeSigner() {
        onClose()
    }
}
