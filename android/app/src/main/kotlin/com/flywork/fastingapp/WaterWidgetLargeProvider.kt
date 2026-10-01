package com.flywork.fastingapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WaterWidgetLargeProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.water_widget).apply {
                val pendingIntent =
                    widgetLaunchIntent(context, "fastingapp://water?homeWidget", 13)
                setOnClickPendingIntent(R.id.water_widget_root, pendingIntent)
                val imagePath = widgetData.getString("water_widget_large_image", null)
                val bitmap = imagePath?.let { decodeWidgetBitmap(it, 1000) }
                if (bitmap != null) {
                    setImageViewBitmap(R.id.water_widget_image, bitmap)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
