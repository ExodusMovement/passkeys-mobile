package network.passkeys.client

import android.app.Activity
import android.net.Uri
import android.util.AttributeSet
import android.webkit.WebView
import android.webkit.WebViewClient
import android.content.Intent
import androidx.browser.customtabs.CustomTabsIntent
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.util.UUID

class Passkeys @JvmOverloads constructor(
    context: android.content.Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    private val initialUrl: String = "https://relay.passkeys.network"
) : WebView(context, attrs, defStyleAttr) {
    private var url: String = ""
    private var appId: String? = null

    companion object {
        const val CUSTOM_TAB_REQUEST_CODE = 100

        private var instance: Passkeys? = null

        fun getInstance(): Passkeys? {
            return instance
        }
        fun clearInstance() { instance = null }

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
        url = initialUrl
        loadUrlWithBridge()
    }

    fun setAppId(appId: String?) {
        this.appId = appId
        loadUrlWithBridge()
    }

    fun setUrl(url: String?) {
        this.url = url ?: initialUrl
        loadUrlWithBridge()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        if (instance === this) {
            clearInstance()
        }
    }

    private fun getActivity(context: android.content.Context): Activity? {
        if (context is Activity) {
            return context
        }

        try {
            val reactContextClass = Class.forName("com.facebook.react.bridge.ReactContext")
            if (reactContextClass.isInstance(context)) {
                // Use reflection to call getCurrentActivity
                return reactContextClass
                    .getMethod("getCurrentActivity")
                    .invoke(context) as? Activity
            }
        } catch (e: ClassNotFoundException) {
            // ReactContext class is not available; ignore
        }

        return null
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

    private fun loadUrlWithBridge() {
        val url = "${this.url}?appId=$appId"
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
            val jsonObject = when {
                result.isNullOrBlank() || result == "undefined" || result == "null" -> null
                result == "\"no-method\"" -> throw IllegalStateException("Unsupported browser")
                else -> JSONObject(result)
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

        val context = context
        val activity = getActivity(context)

        if (activity == null) {
            throw IllegalStateException("No activity available to open the URL")
        }

        if (hasCustomTabsSupport(context)) {
            activity.startActivityForResult(intent, CUSTOM_TAB_REQUEST_CODE)
        } else {
            // Fallback to opening the URL in the default browser
            val fallbackIntent = Intent(Intent.ACTION_VIEW, uri)
            activity.startActivity(fallbackIntent)
        }
    }

    private fun hasCustomTabsSupport(context: android.content.Context): Boolean {
        val packageManager = context.packageManager
        val activityIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.example.com"))
        val resolveInfoList = packageManager.queryIntentActivities(activityIntent, 0)

        for (resolveInfo in resolveInfoList) {
            val serviceIntent = Intent()
            serviceIntent.action = androidx.browser.customtabs.CustomTabsService.ACTION_CUSTOM_TABS_CONNECTION
            serviceIntent.setPackage(resolveInfo.activityInfo.packageName)

            if (packageManager.resolveService(serviceIntent, 0) != null) {
                return true
            }
        }
        return false
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
        if (appId == null) {
            completion(Result.failure(IllegalArgumentException("appId cannot be null")))
            return
        }
        injectJavaScript()

        val dataJSON = data?.toString() ?: "{}"

        val script = """if (!window.$method) return 'no-method';
        else return window.$method($dataJSON);"""

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
