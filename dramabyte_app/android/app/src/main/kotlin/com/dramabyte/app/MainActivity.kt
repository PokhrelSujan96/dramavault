package com.dramabyte.app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.dramabyte.app/security"
        ).setMethodCallHandler { call, result ->
            if (call.method == "enableSecureMode") {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
