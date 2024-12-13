package com.exodus.reactnativepasskeys

import android.app.Activity
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.bridge.ReadableMap
import android.content.Intent
import android.net.Uri
import android.util.AttributeSet
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.browser.customtabs.CustomTabsIntent
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class Passkeys @JvmOverloads constructor(
    context: ThemedReactContext,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    private val activity: Activity,
    private val initialUrl: String = "https://localhost:5172?relay"
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

    private val coroutineScope = MainScope()

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

    fun callAsyncJavaScript(script: String): CompletableDeferred<String?> {
        val deferredResult = CompletableDeferred<String?>()

        coroutineScope.launch {
            evaluateJavascript(script) { result ->
                deferredResult.complete(result)
            }
        }

        return deferredResult
    }

    fun callMethod(method: String, data: ReadableMap?, completion: (Result<String?>) -> Unit) {
        val dataJSON = try {
            data?.toHashMap()?.let { hashMap ->
                org.json.JSONObject(hashMap as Map<String, Any>).toString()
            } ?: "{}"
        } catch (e: Exception) {
            completion(Result.failure(e))
            return
        }

        val script = """
        const result = window.$method($dataJSON);
        if (result instanceof Promise) {
            result
                .then(resolved => resolved)
                .catch(error => { throw error; });
        } else {
            result;
        }
        """

        coroutineScope.launch {
            try {
                val result = callAsyncJavaScript(script).await()
                completion(Result.success(result))
            } catch (e: Exception) {
                completion(Result.failure(e))
            }
        }
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
