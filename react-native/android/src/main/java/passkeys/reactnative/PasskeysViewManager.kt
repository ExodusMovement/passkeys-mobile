package passkeys.reactnative

import network.passkeys.client.Passkeys
import android.view.View
import androidx.lifecycle.Observer
import androidx.lifecycle.LifecycleOwner
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.Promise
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.events.RCTEventEmitter
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.json.JSONArray

fun JSONObject?.toWritableMap(): WritableMap {
    val writableMap = Arguments.createMap()
    this?.keys()?.forEach { key ->
        when (val value = this.get(key)) {
            is JSONObject -> writableMap.putMap(key, value.toWritableMap())
            is JSONArray -> writableMap.putArray(key, value.toWritableArray())
            is Boolean -> writableMap.putBoolean(key, value)
            is Int -> writableMap.putInt(key, value)
            is Double -> writableMap.putDouble(key, value)
            is String -> writableMap.putString(key, value)
            null -> writableMap.putNull(key)
            else -> throw IllegalArgumentException("Unsupported type for key '$key': ${value::class.java}")
        }
    }
    return writableMap
}

fun JSONArray.toWritableArray(): WritableArray {
    val writableArray = Arguments.createArray()
    for (i in 0 until this.length()) {
        when (val value = this.get(i)) {
            is JSONObject -> writableArray.pushMap(value.toWritableMap())
            is JSONArray -> writableArray.pushArray(value.toWritableArray())
            is Boolean -> writableArray.pushBoolean(value)
            is Int -> writableArray.pushInt(value)
            is Double -> writableArray.pushDouble(value)
            is String -> writableArray.pushString(value)
            null -> writableArray.pushNull()
            else -> throw IllegalArgumentException("Unsupported type at index '$i': ${value::class.java}")
        }
    }
    return writableArray
}

class PasskeysViewManager : SimpleViewManager<View>() {

    override fun getName() = "PasskeysView"

    override fun createViewInstance(reactContext: ThemedReactContext): View {
        val activity = reactContext.currentActivity

        if (activity == null) {
            throw IllegalStateException("No activity available when creating PasskeysView")
        }
        val passkeys = Passkeys(reactContext)

        var lastIsLoading: Boolean? = null
        var lastLoadingErrorMessage: String? = null

        if (activity is LifecycleOwner) {
            passkeys.isLoading.observe(activity, Observer { isLoading ->
                if (passkeys.id != View.NO_ID && (isLoading != lastIsLoading || lastLoadingErrorMessage != passkeys.loadingErrorMessage)) {
                    sendLoadingUpdate(passkeys.id, reactContext, isLoading, passkeys.loadingErrorMessage)
                    lastIsLoading = isLoading
                    lastLoadingErrorMessage = passkeys.loadingErrorMessage
                }
            })
        }

        return passkeys
    }

    private fun sendLoadingUpdate(id: Int, reactContext: ThemedReactContext, isLoading: Boolean?, loadingErrorMessage: String? ) {
        val event = Arguments.createMap().apply {
            putBoolean("isLoading", isLoading ?: true)
            putString("loadingErrorMessage", loadingErrorMessage)
        }
        reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(id, "onLoadingUpdate", event)
    }

    @ReactProp(name = "appId")
    fun setAppId(view: Passkeys, appId: String?) {
        view.setAppId(appId)
    }

    @ReactProp(name = "url")
    fun setUrl(view: Passkeys, url: String?) {
        view.setUrl(url)
    }

    override fun onDropViewInstance(view: View) {
        super.onDropViewInstance(view)
        if (view is Passkeys) {
            view.onDestroy()
        }
    }

    fun onHostPause() {
        Passkeys.getInstance()?.onPause()
    }

    fun onHostResume() {
        Passkeys.getInstance()?.onResume()
    }

    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
        return mapOf("onLoadingUpdate" to mapOf("registrationName" to "onLoadingUpdate"))
    }
}

class PasskeysModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    private val coroutineScope = MainScope()

    override fun getName() = "PasskeysViewManager"

    @ReactMethod
    fun callMethod(method: String, data: ReadableMap, promise: Promise) {
        val activity = currentActivity
        if (activity == null) {
            promise.reject("INVALID_VIEW", "No activity available")
            return
        }

        val passkeys = Passkeys.getInstance()
        if (passkeys == null || activity.isFinishing || !passkeys.isAttachedToWindow) {
            promise.reject("INVALID_VIEW", "Passkeys instance not initialized")
            return
        }

        coroutineScope.launch {
            val jsonData = JSONObject(data.toHashMap() as Map<*, *>)
            passkeys.callMethod(method, jsonData) { result ->
                result.fold(
                    onSuccess = { promise.resolve(it?.toWritableMap()) },
                    onFailure = { promise.reject("EXECUTION_ERROR", it) }
                )
            }
        }
    }
}
