package app.taktika.game

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val prefs = getSharedPreferences("taktika", Context.MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taktika/storage")
            .setMethodCallHandler { call, result ->
                val key = call.argument<String>("key")
                if (key == null) {
                    result.error("bad_args", "key is required", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "read" -> result.success(prefs.getString(key, null))
                    "write" -> {
                        prefs.edit().putString(key, call.argument<String>("value")).apply()
                        result.success(null)
                    }
                    "remove" -> {
                        prefs.edit().remove(key).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
