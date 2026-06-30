package com.example.civiclens_ai

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val diagnosticsChannel = "civiclens_ai/maps_diagnostics"
    private val mapsApiKeyMetadataName = "com.google.android.geo.API_KEY"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, diagnosticsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMapsApiKeyMetadata" -> result.success(getMapsApiKeyMetadata())
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun getMapsApiKeyMetadata(): Map<String, Any?> {
        val applicationInfo = packageManager.getApplicationInfo(
            packageName,
            PackageManager.GET_META_DATA,
        )
        val apiKey = applicationInfo.metaData?.getString(mapsApiKeyMetadataName)

        return mapOf(
            "packageName" to packageName,
            "metadataName" to mapsApiKeyMetadataName,
            "apiKey" to apiKey,
            "hasApiKey" to !apiKey.isNullOrBlank(),
        )
    }
}
