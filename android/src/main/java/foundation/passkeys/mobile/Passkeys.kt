package foundation.passkeys.mobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.AttributeSet
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.browser.customtabs.CustomTabsIntent

class Passkeys @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    private val initialUrl: String = "https://dev.passkeys.foundation/playground?relay"
) : WebView(context, attrs, defStyleAttr) {

    private var customTabResultLauncher: ActivityResultLauncher<Intent>? = null
    private var customTabCallback: (() -> Unit)? = null

    companion object {
        const val CUSTOM_TAB_REQUEST_CODE = 100
    }

    init {

        setupWebView()
        setupDefaultLauncherIfNeeded()

        loadUrlWithBridge(initialUrl)
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

    private fun setupDefaultLauncherIfNeeded() {
        if (context is ComponentActivity) {
            val activity = context as ComponentActivity
            customTabResultLauncher = activity.registerForActivityResult(
                ActivityResultContracts.StartActivityForResult()
            ) { result ->
                if (result.resultCode == Activity.RESULT_CANCELED) {
                    reload()
                }
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

    fun registerCustomTabResultLauncher(launcher: ActivityResultLauncher<Intent>) {
        customTabResultLauncher = launcher
    }

    // Open a Custom Tab and launch it using the result launcher
    fun openInCustomTab(url: String) {
        val uri = Uri.parse(url)
        val customTabsIntent = CustomTabsIntent.Builder().build()
        val intent = customTabsIntent.intent
        intent.data = uri

        // Use the launcher (default or custom) to handle the intent
        customTabResultLauncher?.launch(intent)
            ?: throw IllegalStateException("No ActivityResultLauncher registered. Ensure you're using a ComponentActivity or register a custom launcher.")
    }
}


class JavaScriptBridge(private val onClose: () -> Unit) {
    @android.webkit.JavascriptInterface
    fun closeSigner() {
        onClose()
    }
}
