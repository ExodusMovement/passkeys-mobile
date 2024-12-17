package com.exodus.reactnativepasskeys

import android.app.Activity
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.bridge.Arguments
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
import java.util.UUID

private fun org.json.JSONObject.toMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    val keys = keys()
    while (keys.hasNext()) {
        val key = keys.next()
        val value = this[key]
        map[key] = when (value) {
            is org.json.JSONObject -> value.toMap()
            is org.json.JSONArray -> value.toList()
            else -> value
        }
    }
    return map
}

private fun org.json.JSONArray.toList(): List<Any?> {
    val list = mutableListOf<Any?>()
    for (i in 0 until length()) {
        val value = this[i]
        list.add(
            when (value) {
                is org.json.JSONObject -> value.toMap()
                is org.json.JSONArray -> value.toList()
                else -> value
            }
        )
    }
    return list
}

class Passkeys @JvmOverloads constructor(
    context: ThemedReactContext,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    private val activity: Activity,
    private val initialUrl: String = "https://wallet-d.passkeys.foundation?relay"
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
    private val deferredResults = mutableMapOf<String, CompletableDeferred<ReadableMap?>>()

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
                onOpen = { url -> onOpenSigner(url) },
                onResult = { id, result -> onJavaScriptResult(id, result) }
            ),
            "AndroidBridge"
        )

        webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                openInCustomTab(request.url.toString())
                return true
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
            val readableMap: ReadableMap? = if (result.isNullOrBlank() || result == "undefined" || result == "null") {
                null
            } else {
                val jsonObject = org.json.JSONObject(result)
                Arguments.makeNativeMap(jsonObject.toMap())
            }
            deferredResults[id]?.complete(readableMap)
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

    fun callAsyncJavaScriptWithId(script: String): CompletableDeferred<ReadableMap?> {
        val deferredResult = CompletableDeferred<ReadableMap?>()
        val uniqueId = java.util.UUID.randomUUID().toString()
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

    fun callMethod(method: String, data: ReadableMap?, completion: (Result<ReadableMap?>) -> Unit) {
        injectJavaScript()
        val dataJSON = try {
            data?.toHashMap()?.let { hashMap ->
                org.json.JSONObject(hashMap as Map<String, Any>).toString()
            } ?: "{}"
        } catch (e: Exception) {
            completion(Result.failure(e))
            return
        }

        val script = "return window.$method($dataJSON);"

        coroutineScope.launch {
            try {
                val result = callAsyncJavaScriptWithId(script).await()
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
