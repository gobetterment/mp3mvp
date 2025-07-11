package com.bmpplayer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Google Sign-In 설정
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "plugins.flutter.io/google_sign_in")
            .setMethodCallHandler { call, result ->
                // Google Sign-In 플러그인이 자동으로 처리
                result.notImplemented()
            }
    }
} 