package com.flywork.fastingapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WaterWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.water_widget).apply {
                val pendingIntent =
                    widgetLaunchIntent(context, "fastingapp://water?homeWidget", 11)
                setOnClickPendingIntent(R.id.water_widget_root, pendingIntent)
                val imagePath = widgetData.getString("water_widget_image", null)
                val bitmap = imagePath?.let { decodeWidgetBitmap(it, 700) }
                if (bitmap != null) {
                    setImageViewBitmap(R.id.water_widget_image, bitmap)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

internal fun widgetLaunchIntent(
    context: Context,
    uri: String,
    requestCode: Int,
): PendingIntent {
    val intent = Intent(context, MainActivity::class.java)
    intent.data = Uri.parse(uri)
    intent.action = "es.antonborri.home_widget.action.LAUNCH"
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= 23) {
        flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    return PendingIntent.getActivity(context, requestCode, intent, flags)
}

internal fun decodeWidgetBitmap(path: String, maxWidth: Int): Bitmap? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    val width = bounds.outWidth
    if (width <= 0) return null
    var sample = 1
    while (width / (sample * 2) >= maxWidth) {
        sample *= 2
    }
    val decoded =
        BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return null
    if (decoded.width <= maxWidth) return decoded
    val targetHeight = decoded.height * maxWidth / decoded.width
    return Bitmap.createScaledBitmap(decoded, maxWidth, targetHeight, true)
}
