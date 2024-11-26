// todo dedupe this file
package com.exodus.reactnativepasskeys

import android.app.Activity
import com.facebook.react.uimanager.ThemedReactContext
import android.content.Intent
import android.net.Uri
import android.util.AttributeSet
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.result.ActivityResultLauncher
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.app.ActivityCompat.startActivityForResult

class Passkeys @JvmOverloads constructor(
    context: ThemedReactContext,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    private val activity: Activity,
    private val initialUrl: String = "https://dev.passkeys.foundation/playground?relay"
) : WebView(context, attrs, defStyleAttr) {

    private var customTabResultLauncher: ActivityResultLauncher<Intent>? = null
    private var customTabCallback: (() -> Unit)? = null

    companion object {
        const val CUSTOM_TAB_REQUEST_CODE = 100
    }

    init {
        setupWebView()
        // setupDefaultLauncherIfNeeded() // todo

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

    // private fun setupDefaultLauncherIfNeeded() {
    //     if (context is ComponentActivity) {
    //         val activity = context as ComponentActivity
    //         customTabResultLauncher = activity.registerForActivityResult(
    //             ActivityResultContracts.StartActivityForResult()
    //         ) { result ->
    //             if (result.resultCode == Activity.RESULT_CANCELED) {
    //                 reload()
    //             }
    //         }
    //     }
    // }

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
      // Ensure the current Activity is available
      val uri = Uri.parse(url)
      val customTabsIntent = CustomTabsIntent.Builder().build()
      val intent = customTabsIntent.intent
      intent.data = uri

      activity.startActivityForResult(intent, CUSTOM_TAB_REQUEST_CODE)
    }
}


class JavaScriptBridge(private val onClose: () -> Unit) {
    @android.webkit.JavascriptInterface
    fun closeSigner() {
        onClose()
    }
}
