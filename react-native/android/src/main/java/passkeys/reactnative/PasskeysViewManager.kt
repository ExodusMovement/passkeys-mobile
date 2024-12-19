package passkeys.reactnative

import android.app.Activity
import android.graphics.Color
import android.view.View
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.Promise
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.annotations.ReactProp
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class PasskeysViewManager : SimpleViewManager<View>() {

    override fun getName() = "PasskeysView"

    override fun createViewInstance(reactContext: ThemedReactContext): View {
        val activity = reactContext.currentActivity

        if (activity == null) {
            throw IllegalStateException("No activity available when creating PasskeysView")
        }
        return Passkeys(reactContext, null, 0, activity)
    }
}

private fun mapToWritableMap(map: Map<String, Any?>?): WritableMap {
    val writableMap = Arguments.createMap()
    map?.forEach { (key, value) ->
        when (value) {
            null -> writableMap.putNull(key)
            is Boolean -> writableMap.putBoolean(key, value)
            is Double -> writableMap.putDouble(key, value)
            is Int -> writableMap.putInt(key, value)
            is String -> writableMap.putString(key, value)
            is Map<*, *> -> writableMap.putMap(key, mapToWritableMap(value as Map<String, Any?>))
            is List<*> -> writableMap.putArray(key, listToWritableArray(value))
            else -> throw IllegalArgumentException("Unsupported type for key '$key': ${value::class.java}")
        }
    }
    return writableMap
}

private fun listToWritableArray(list: List<Any?>): WritableArray {
    val writableArray = Arguments.createArray()
    list.forEach { value ->
        when (value) {
            null -> writableArray.pushNull()
            is Boolean -> writableArray.pushBoolean(value)
            is Double -> writableArray.pushDouble(value)
            is Int -> writableArray.pushInt(value)
            is String -> writableArray.pushString(value)
            is Map<*, *> -> writableArray.pushMap(mapToWritableMap(value as Map<String, Any?>))
            is List<*> -> writableArray.pushArray(listToWritableArray(value))
            else -> throw IllegalArgumentException("Unsupported type: ${value::class.java}")
        }
    }
    return writableArray
}

private fun readableMapToMap(readableMap: ReadableMap): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>()
    val iterator = readableMap.keySetIterator()
    while (iterator.hasNextKey()) {
        val key = iterator.nextKey()
        result[key] = when (val value = readableMap.getType(key)) {
            ReadableType.Null -> null
            ReadableType.Boolean -> readableMap.getBoolean(key)
            ReadableType.Number -> readableMap.getDouble(key) // All numbers are treated as Double in ReadableMap
            ReadableType.String -> readableMap.getString(key)
            ReadableType.Map -> readableMapToMap(readableMap.getMap(key)!!)
            ReadableType.Array -> readableArrayToList(readableMap.getArray(key)!!)
        }
    }
    return result
}

private fun readableArrayToList(readableArray: ReadableArray): List<Any?> {
    val result = mutableListOf<Any?>()
    for (i in 0 until readableArray.size()) {
        result.add(
            when (val value = readableArray.getType(i)) {
                ReadableType.Null -> null
                ReadableType.Boolean -> readableArray.getBoolean(i)
                ReadableType.Number -> readableArray.getDouble(i) // All numbers are treated as Double in ReadableArray
                ReadableType.String -> readableArray.getString(i)
                ReadableType.Map -> readableMapToMap(readableArray.getMap(i)!!)
                ReadableType.Array -> readableArrayToList(readableArray.getArray(i)!!)
            }
        )
    }
    return result
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
        if (passkeys == null) {
            promise.reject("INVALID_VIEW", "Passkeys instance not initialized")
            return
        }

        coroutineScope.launch {
            passkeys.callMethod(method, readableMapToMap(data)) { result ->
                result.fold(
                    onSuccess = { promise.resolve(mapToWritableMap(it)) },
                    onFailure = { promise.reject("EXECUTION_ERROR", it) }
                )
            }
        }
    }
}
