package com.ziba.app

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channel handler for setting wallpapers on Android.
 *
 * Usage from Dart:
 * ```dart
 * final channel = MethodChannel('com.ziba/wallpaper');
 * await channel.invokeMethod('setWallpaper', {
 *   'path': '/path/to/image.jpg',
 *   'target': 'both', // 'home', 'lock', or 'both'
 * });
 * ```
 *
 * Register in MainActivity:
 * ```kotlin
 * override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
 *     super.configureFlutterEngine(flutterEngine)
 *     WallpaperPlugin.registerWith(flutterEngine)
 * }
 * ```
 */
class WallpaperPlugin {
    companion object {
        private const val CHANNEL = "com.ziba/wallpaper"

        fun registerWith(@NonNull flutterEngine: FlutterEngine) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )

            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "setWallpaper" -> handleSetWallpaper(call, result)
                    "isSupported" -> result.success(true)
                    else -> result.notImplemented()
                }
            }
        }

        private fun handleSetWallpaper(call: MethodCall, result: MethodChannel.Result) {
            val path = call.argument<String>("path")
            val target = call.argument<String>("target") ?: "both"

            if (path == null) {
                result.error("INVALID_ARG", "Missing 'path' argument", null)
                return
            }

            try {
                val context = io.flutter.embedding.engine.FlutterEngineCache
                    .getInstance()
                    .get("main_engine")
                    ?.context
                    ?: throw Exception("No context available")

                val wallpaperManager = WallpaperManager.getInstance(context)
                val bitmap = BitmapFactory.decodeFile(path)
                    ?: throw Exception("Failed to decode image at $path")

                val flags = when (target) {
                    "home" -> WallpaperManager.FLAG_SYSTEM
                    "lock" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            WallpaperManager.FLAG_LOCK
                        } else {
                            WallpaperManager.FLAG_SYSTEM
                        }
                    }
                    "both" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                        } else {
                            WallpaperManager.FLAG_SYSTEM
                        }
                    }
                    else -> WallpaperManager.FLAG_SYSTEM
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    wallpaperManager.setBitmap(bitmap, null, true, flags)
                } else {
                    wallpaperManager.setBitmap(bitmap)
                }

                bitmap.recycle()
                result.success(true)
            } catch (e: Exception) {
                result.error("WALLPAPER_ERROR", e.message, e.stackTraceToString())
            }
        }
    }
}
