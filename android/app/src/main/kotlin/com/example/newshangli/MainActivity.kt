package com.example.newshangli

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "liji/app_update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installedVersion" -> result.success(
                        mapOf(
                            "version" to getString(R.string.liji_version_name),
                            "build" to getString(R.string.liji_build_number),
                        ),
                    )
                    "openRelease" -> {
                        val value = call.arguments as? String
                        val uri = value?.let { Uri.parse(it) }
                        if (uri == null || uri.scheme != "https" ||
                            uri.host != "github.com" || uri.port != -1 ||
                            uri.userInfo != null || uri.query != null || uri.fragment != null ||
                            uri.pathSegments.size != 5 ||
                            uri.pathSegments.take(4) != listOf("ztlgc", "NewShangli", "releases", "tag")
                        ) {
                            result.error("invalid_url", "更新页面地址无效", null)
                        } else {
                            try {
                                startActivity(
                                    Intent(Intent.ACTION_VIEW, uri)
                                        .addCategory(Intent.CATEGORY_BROWSABLE),
                                )
                                result.success(true)
                            } catch (_: ActivityNotFoundException) {
                                result.success(false)
                            } catch (_: SecurityException) {
                                result.error("open_failed", "无法打开更新页面", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
