package com.essco.ziba

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val plugin = WallpaperPlugin(applicationContext)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WallpaperPlugin.CHANNEL
        ).setMethodCallHandler(plugin)
    }
}
