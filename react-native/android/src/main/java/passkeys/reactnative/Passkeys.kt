package passkeys.reactnative

import android.app.Activity
import android.net.Uri
import android.util.AttributeSet
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.browser.customtabs.CustomTabsIntent
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.util.UUID

class PasskeysMobileView @JvmOverloads constructor(
    context: android.content.Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    private val activity: Activity,
    private val initialUrl: String = "https://wallet-d.passkeys.foundation?relay"
) : WebView(context, attrs, defStyleAttr) {

    companion object {
        const val CUSTOM_TAB_REQUEST_CODE = 100

        private var instance: PasskeysMobileView? = null

        fun getInstance(): PasskeysMobileView? {
            return instance
        }

        private var customTabCallback: (() -> Unit)? = null

        fun setOnCloseSignerCallback(callback: () -> Unit) {
            customTabCallback = callback
        }
    }

    private val coroutineScope = MainScope()
    private val deferredResults = mutableMapOf<String, CompletableDeferred<JSONObject?>>()

    init {
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
                onOpen = { url -> onOpenSigner(url) },
                onResult = { id, result -> onJavaScriptResult(id, result) }
            ),
            "AndroidBridge"
        )

        webViewClient = object : WebViewClient() {}
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
                if (typeof url !== 'string') throw new Error('url is not a string');
                AndroidBridge.openSigner(url);
            };
            window.nativeBridge.resolveResult = function(id, result) {
                AndroidBridge.resolveResult(id, result);
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

    private fun onJavaScriptResult(id: String, result: String?) {
        try {
            val jsonObject = if (result.isNullOrBlank() || result == "undefined" || result == "null") {
                null
            } else {
                JSONObject(result)
            }
            deferredResults[id]?.complete(jsonObject)
        } catch (e: Exception) {
            deferredResults[id]?.completeExceptionally(e)
        } finally {
            deferredResults.remove(id)
        }
    }

    fun openInCustomTab(url: String) {
        val uri = Uri.parse(url)
        val customTabsIntent = CustomTabsIntent.Builder().build()
        val intent = customTabsIntent.intent
        intent.data = uri

        activity.startActivityForResult(intent, CUSTOM_TAB_REQUEST_CODE)
    }

    fun callAsyncJavaScript(script: String): CompletableDeferred<JSONObject?> {
        val deferredResult = CompletableDeferred<JSONObject?>()
        val uniqueId = UUID.randomUUID().toString()
        deferredResults[uniqueId] = deferredResult

        coroutineScope.launch {
            evaluateJavascript(
                """
                (async function() {
                    try {
                        const result = await (function() { $script })();
                        window.nativeBridge.resolveResult('$uniqueId', JSON.stringify(result));
                    } catch (e) {
                        window.nativeBridge.resolveResult('$uniqueId', null);
                    }
                })();
                """
            ) { }
        }

        return deferredResult
    }

    fun callMethod(method: String, data: JSONObject?, completion: (Result<JSONObject?>) -> Unit) {
        injectJavaScript()

        val dataJSON = data?.toString() ?: "{}"

        val script = "return window.$method($dataJSON);"

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

class JavaScriptBridge(
    private val onClose: () -> Unit,
    private val onOpen: (String) -> Unit,
    private val onResult: (String, String?) -> Unit
) {
    @android.webkit.JavascriptInterface
    fun closeSigner() {
        onClose()
    }

    @android.webkit.JavascriptInterface
    fun openSigner(url: String) {
        onOpen(url)
    }

    @android.webkit.JavascriptInterface
    fun resolveResult(id: String, result: String?) {
        onResult(id, result)
    }
}
