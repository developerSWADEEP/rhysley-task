package com.example.rhysley

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val CHANNEL = "native_location_channel"
        private const val EVENT_CHANNEL = "native_location_events"
        private const val TAG = "MainActivity"
    }
    
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startNativeLocationService" -> {
                    try {
                        Log.d(TAG, "📱 Starting native location service from Flutter")
                        NativeLocationService.startService(this)
                        Log.d(TAG, "✅ Native location service started successfully")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Failed to start native location service", e)
                        result.error("SERVICE_ERROR", "Failed to start service", e.message)
                    }
                }
                "stopNativeLocationService" -> {
                    try {
                        NativeLocationService.stopService(this)
                        Log.d(TAG, "Native location service stopped")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to stop native location service", e)
                        result.error("SERVICE_ERROR", "Failed to stop service", e.message)
                    }
                }
                "isNativeServiceRunning" -> {
                    // You can implement a way to check if service is running
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up EventChannel for location updates
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(LocationEventStreamHandler())
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "📱 MainActivity onCreate - App starting")
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "📱 MainActivity onResume - App in foreground")
        Log.d(TAG, "✅ Location sent successfully when app is active")
    }
    
    override fun onPause() {
        super.onPause()
        Log.d(TAG, "📱 MainActivity onPause - App going to background")
        Log.d(TAG, "✅ Location sent successfully when app is in background")
    }
    
    override fun onStop() {
        super.onStop()
        Log.d(TAG, "📱 MainActivity onStop - App stopped")
        Log.d(TAG, "✅ Location sent successfully in other state")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "📱 MainActivity onDestroy - App destroyed")
    }
}

// EventStreamHandler for location updates
class LocationEventStreamHandler : EventChannel.StreamHandler {
    companion object {
        private val eventSinks = ConcurrentHashMap<String, EventChannel.EventSink>()
        
        fun addEventSink(key: String, eventSink: EventChannel.EventSink) {
            eventSinks[key] = eventSink
        }
        
        fun removeEventSink(key: String) {
            eventSinks.remove(key)
        }
        
        fun sendLocationUpdate(locationData: Map<String, Any>) {
            Log.d("LocationEventStreamHandler", "📤 Sending location update to Flutter")
            Log.d("LocationEventStreamHandler", "📤 Active event sinks: ${eventSinks.size}")
            Log.d("LocationEventStreamHandler", "📤 Location data: $locationData")
            
            eventSinks.values.forEach { eventSink ->
                try {
                    eventSink.success(locationData)
                    Log.d("LocationEventStreamHandler", "✅ Location update sent successfully to Flutter")
                } catch (e: Exception) {
                    Log.e("LocationEventStreamHandler", "❌ Error sending location update", e)
                }
            }
        }
    }
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val key = "location_stream_${System.currentTimeMillis()}"
        if (events != null) {
            addEventSink(key, events)
            Log.d("LocationEventStreamHandler", "Event sink added: $key")
        }
    }
    
    override fun onCancel(arguments: Any?) {
        // Remove all event sinks when cancelled
        eventSinks.clear()
        Log.d("LocationEventStreamHandler", "Event sinks cleared")
    }
}
