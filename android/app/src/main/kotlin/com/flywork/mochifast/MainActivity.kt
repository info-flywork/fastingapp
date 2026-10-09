package com.flywork.mochifast

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// RevenueCat Paywalls (purchases_ui_flutter) FragmentActivity ister.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    /**
     * FCM kanalları (backend `infra/fcm.js`): normal bildirimler `default`, sessiz saatte
     * gönderilenler `quiet` (ses/titreşim yok). Kanal zaten varsa Android dokunmaz.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel(
                "default",
                getString(R.string.notification_channel_default),
                NotificationManager.IMPORTANCE_HIGH,
            ),
        )
        manager.createNotificationChannel(
            NotificationChannel(
                "quiet",
                getString(R.string.notification_channel_quiet),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                setSound(null, null)
                enableVibration(false)
            },
        )
    }
}
