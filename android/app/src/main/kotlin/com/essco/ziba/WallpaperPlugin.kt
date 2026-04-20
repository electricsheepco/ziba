package com.essco.ziba

import android.app.WallpaperManager
import android.content.Context
import android.graphics.BitmapFactory
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class WallpaperPlugin(private val context: Context) : MethodCallHandler {

    companion object {
        const val CHANNEL = "com.ziba/wallpaper"
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setWallpaper" -> handleSetWallpaper(call, result)
            "isSupported" -> result.success(true)
            else -> result.notImplemented()
        }
    }

    private fun handleSetWallpaper(call: MethodCall, result: Result) {
        val path = call.argument<String>("path")
        val target = call.argument<String>("target") ?: "both"

        if (path == null) {
            result.error("INVALID_ARG", "Missing 'path' argument", null)
            return
        }

        try {
            val wallpaperManager = WallpaperManager.getInstance(context)
            val bitmap = BitmapFactory.decodeFile(path)
                ?: throw Exception("Failed to decode image at $path")

            val flags = when (target) {
                "home" -> WallpaperManager.FLAG_SYSTEM
                "lock" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    WallpaperManager.FLAG_LOCK
                } else {
                    WallpaperManager.FLAG_SYSTEM
                }
                else -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                } else {
                    WallpaperManager.FLAG_SYSTEM
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                wallpaperManager.setBitmap(bitmap, null, true, flags)
            } else {
                @Suppress("DEPRECATION")
                wallpaperManager.setBitmap(bitmap)
            }

            bitmap.recycle()
            result.success(true)
        } catch (e: Exception) {
            result.error("WALLPAPER_ERROR", e.message, e.stackTraceToString())
        }
    }
}
