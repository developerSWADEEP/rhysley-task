package com.example.rhysley

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

class NativeLocationService : Service(), LocationListener {
    
    companion object {
        private const val TAG = "NativeLocationService"
        private const val NOTIFICATION_ID = 999
        private const val CHANNEL_ID = "native_location_channel"
        private const val CHANNEL_NAME = "Native Location Tracking"
        private const val LOCATION_UPDATE_INTERVAL = 1000L // 1 second
        private const val LOCATION_UPDATE_DISTANCE = 1f // 1 meter
        
        fun startService(context: Context) {
            val intent = Intent(context, NativeLocationService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, NativeLocationService::class.java)
            context.stopService(intent)
        }
    }
    
    private lateinit var locationManager: LocationManager
    private lateinit var notificationManager: NotificationManagerCompat
    private lateinit var wakeLock: PowerManager.WakeLock
    private var isServiceRunning = false
    private var lastLocation: Location? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "NativeLocationService onCreate")
        
        // Initialize location manager
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        // Initialize notification manager
        notificationManager = NotificationManagerCompat.from(this)
        
        // Create notification channel
        createNotificationChannel()
        
        // Initialize wake lock
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Rhysley::LocationWakeLock"
        )
        
        Log.d(TAG, "NativeLocationService initialized")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "🚀 NativeLocationService onStartCommand - Service starting")
        Log.d(TAG, "🚀 Intent: $intent, Flags: $flags, StartId: $startId")
        Log.d(TAG, "🚀 Service running: $isServiceRunning")
        
        if (!isServiceRunning) {
            Log.d(TAG, "🚀 Starting foreground service and location tracking")
            startForegroundService()
            startLocationTracking()
            isServiceRunning = true
            Log.d(TAG, "✅ Service started successfully")
        } else {
            Log.d(TAG, "⚠️ Service already running, skipping startup")
        }
        
        Log.d(TAG, "🚀 Returning START_STICKY to ensure service persistence")
        return START_STICKY // Restart service if killed
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "NativeLocationService onDestroy")
        
        stopLocationTracking()
        releaseWakeLock()
        serviceScope.cancel()
        isServiceRunning = false
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Continuous location tracking service"
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    
    private fun startForegroundService() {
        val notification = createForegroundNotification("Starting location tracking...")
        startForeground(NOTIFICATION_ID, notification)
        Log.d(TAG, "Foreground service started")
    }
    
    private fun createForegroundNotification(content: String): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Rhysley Location Tracking")
            .setContentText(content)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    private fun startLocationTracking() {
        Log.d(TAG, "📍 Starting location tracking")
        Log.d(TAG, "📍 Update interval: ${LOCATION_UPDATE_INTERVAL}ms")
        Log.d(TAG, "📍 Update distance: ${LOCATION_UPDATE_DISTANCE}m")
        
        // Acquire wake lock
        if (!wakeLock.isHeld) {
            wakeLock.acquire(10*60*1000L /*10 minutes*/)
            Log.d(TAG, "🔋 Wake lock acquired for 10 minutes")
        } else {
            Log.d(TAG, "🔋 Wake lock already held")
        }
        
        // Check permissions
        val fineLocationPermission = ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        val coarseLocationPermission = ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
        
        Log.d(TAG, "🔐 Fine location permission: $fineLocationPermission")
        Log.d(TAG, "🔐 Coarse location permission: $coarseLocationPermission")
        
        if (fineLocationPermission != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "❌ Location permission not granted")
            stopSelf()
            return
        }
        
        // Check if location services are enabled
        val locationEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val networkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        
        Log.d(TAG, "📍 GPS provider enabled: $locationEnabled")
        Log.d(TAG, "📍 Network provider enabled: $networkEnabled")
        
        // Request location updates
        try {
            if (locationEnabled) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    LOCATION_UPDATE_INTERVAL,
                    LOCATION_UPDATE_DISTANCE,
                    this
                )
                Log.d(TAG, "✅ GPS location updates requested")
            } else {
                Log.w(TAG, "⚠️ GPS provider not enabled")
            }
            
            if (networkEnabled) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    LOCATION_UPDATE_INTERVAL,
                    LOCATION_UPDATE_DISTANCE,
                    this
                )
                Log.d(TAG, "✅ Network location updates requested")
            } else {
                Log.w(TAG, "⚠️ Network provider not enabled")
            }
            
            Log.d(TAG, "✅ Location tracking started successfully")
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ Security exception requesting location updates", e)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception requesting location updates", e)
        }
    }
    
    private fun stopLocationTracking() {
        Log.d(TAG, "Stopping location tracking")
        locationManager.removeUpdates(this)
    }
    
    private fun releaseWakeLock() {
        if (wakeLock.isHeld) {
            wakeLock.release()
            Log.d(TAG, "Wake lock released")
        }
    }
    
    override fun onLocationChanged(location: Location) {
        Log.d(TAG, "📍 Location changed: ${location.latitude}, ${location.longitude}")
        Log.d(TAG, "📍 Accuracy: ${location.accuracy}m, Speed: ${location.speed}m/s")
        Log.d(TAG, "📍 Timestamp: ${location.time}")
        Log.d(TAG, "📍 Provider: ${location.provider}")
        
        // Update notification
        updateNotification(location)
        
        // Send to Flutter
        sendLocationToFlutter(location)
        
        // Send to server
        sendLocationToServer(location)
        
        // Show local notification
        showLocationNotification(location)
        
        lastLocation = location
    }
    
    private fun updateNotification(location: Location) {
        val content = "Lat: ${String.format("%.6f", location.latitude)}, " +
                "Lng: ${String.format("%.6f", location.longitude)}, " +
                "Accuracy: ${String.format("%.1f", location.accuracy)}m"
        
        val notification = createForegroundNotification(content)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun sendLocationToFlutter(location: Location) {
        try {
            val locationData = mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "accuracy" to location.accuracy,
                "speed" to location.speed,
                "timestamp" to location.time,
                "altitude" to location.altitude,
                "bearing" to location.bearing
            )
            
            Log.d(TAG, "📤 Sending location to Flutter via EventChannel")
            Log.d(TAG, "📤 Location data: $locationData")
            
            // Send location update via EventChannel
            LocationEventStreamHandler.sendLocationUpdate(locationData)
            
            Log.d(TAG, "✅ Location sent successfully to Flutter")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send location to Flutter", e)
        }
    }
    
    private fun sendLocationToServer(location: Location) {
        serviceScope.launch {
            try {
                Log.d(TAG, "🌐 Starting server communication")
                
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val userId = prefs.getInt("userId", -1)
                val token = prefs.getString("token", "")
                
                Log.d(TAG, "🌐 User ID: $userId, Token available: ${!token.isNullOrEmpty()}")
                
                if (userId == -1 || token.isNullOrEmpty()) {
                    Log.w(TAG, "⚠️ User not logged in, skipping server update")
                    return@launch
                }
                
                val json = JSONObject().apply {
                    put("user_id", userId)
                    put("lat", location.latitude)
                    put("lng", location.longitude)
                    put("accuracy", location.accuracy)
                    put("speed", location.speed)
                    put("timestamp", location.time)
                    put("altitude", location.altitude)
                    put("heading", location.bearing)
                }
                
                Log.d(TAG, "🌐 JSON payload: $json")
                
                val client = OkHttpClient.Builder()
                    .connectTimeout(30, TimeUnit.SECONDS)
                    .writeTimeout(30, TimeUnit.SECONDS)
                    .readTimeout(30, TimeUnit.SECONDS)
                    .build()
                
                val requestBody = json.toString().toRequestBody("application/json".toMediaType())
                val request = Request.Builder()
                    .url("https://your-api-endpoint.com/api/location") // Replace with your API endpoint
                    .post(requestBody)
                    .addHeader("Authorization", "Bearer $token")
                    .addHeader("Content-Type", "application/json")
                    .build()
                
                Log.d(TAG, "🌐 Sending HTTP request to server")
                val response = client.newCall(request).execute()
                
                if (response.isSuccessful) {
                    Log.d(TAG, "✅ Location sent successfully to server - Response: ${response.code}")
                    Log.d(TAG, "✅ Response body: ${response.body?.string()}")
                } else {
                    Log.w(TAG, "⚠️ Failed to send location to server: ${response.code}")
                    Log.w(TAG, "⚠️ Response body: ${response.body?.string()}")
                }
                response.close()
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending location to server", e)
            }
        }
    }
    
    private fun showLocationNotification(location: Location) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("📍 Location Updated")
            .setContentText("Lat: ${String.format("%.6f", location.latitude)}, " +
                    "Lng: ${String.format("%.6f", location.longitude)}")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("📍 New Location Update\n" +
                        "Latitude: ${String.format("%.6f", location.latitude)}\n" +
                        "Longitude: ${String.format("%.6f", location.longitude)}\n" +
                        "Accuracy: ${String.format("%.1f", location.accuracy)}m\n" +
                        "Speed: ${String.format("%.1f", location.speed)} m/s"))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setWhen(System.currentTimeMillis())
            .build()
        
        notificationManager.notify(
            System.currentTimeMillis().toInt(),
            notification
        )
    }
}
