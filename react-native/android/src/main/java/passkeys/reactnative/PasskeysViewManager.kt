package passkeys.reactnative

import android.app.Activity
import android.graphics.Color
import android.view.View
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
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
            passkeys.callMethod(method, data) { result ->
                result.fold(
                    onSuccess = { promise.resolve(it) },
                    onFailure = { promise.reject("EXECUTION_ERROR", it) }
                )
            }
        }
    }
}
