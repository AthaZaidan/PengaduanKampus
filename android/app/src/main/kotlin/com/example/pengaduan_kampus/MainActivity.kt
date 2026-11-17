package com.laporin.pengaduan_kampus

import io.flutter.embedding.android.FlutterActivity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("laporan_kampus", "Perkembangan laporan", NotificationManager.IMPORTANCE_DEFAULT)
            channel.description = "Pembaruan pengaduan dan klarifikasi fasilitas kampus"
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
