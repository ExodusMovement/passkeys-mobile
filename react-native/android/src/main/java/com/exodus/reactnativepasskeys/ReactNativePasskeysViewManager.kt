package com.exodus.reactnativepasskeys

import android.app.Activity
import android.graphics.Color
import android.view.View
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.annotations.ReactProp

class ReactNativePasskeysViewManager : SimpleViewManager<View>() {
  override fun getName() = "ReactNativePasskeysView"

  override fun createViewInstance(reactContext: ThemedReactContext): View {
    val activity = reactContext.currentActivity

    if (activity == null) {
        throw IllegalStateException("No activity available when creating ReactNativePasskeysView")
    }
    return Passkeys(reactContext, null, 0 , activity)
  }

  @ReactProp(name = "color")
  fun setColor(view: View, color: String) {
    view.setBackgroundColor(Color.parseColor(color))
  }
}
