package passkeys.reactnative

import network.passkeys.client.Passkeys
import android.view.View
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
        return Passkeys(reactContext)
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
        if (view is Passkeys && Passkeys.getInstance() === view) {
            Passkeys.clearInstance()
        }
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
        if (passkeys == null || activity?.isFinishing == true || passkeys?.isAttachedToWindow == false) {
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
