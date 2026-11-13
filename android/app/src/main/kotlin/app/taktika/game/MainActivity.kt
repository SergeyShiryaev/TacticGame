package app.taktika.game

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.animation.DecelerateInterpolator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Системная заставка уходит плавно: растворяется и чуть растёт.
            // Анимация идёт поверх уже готового меню и старт не задерживает.
            splashScreen.setOnExitAnimationListener { provider ->
                val view = provider.view
                view.isClickable = false
                view.animate()
                    .alpha(0f)
                    .scaleX(1.08f)
                    .scaleY(1.08f)
                    .setDuration(SPLASH_EXIT_MS)
                    .setInterpolator(DecelerateInterpolator())
                    .withEndAction { provider.remove() }
                    .start()
            }
        }
    }

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

    private companion object {
        const val SPLASH_EXIT_MS = 250L
    }
}
