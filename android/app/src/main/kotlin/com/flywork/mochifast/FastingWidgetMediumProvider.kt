package com.flywork.mochifast

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FastingWidgetMediumProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.water_widget).apply {
                setOnClickPendingIntent(
                    R.id.water_widget_root,
                    widgetLaunchIntent(context, "fastingapp://fasting?homeWidget", 15),
                )
                val imagePath = widgetData.getString("fasting_widget_medium_image", null)
                val bitmap = imagePath?.let { decodeWidgetBitmap(it, 1000) }
                if (bitmap != null) {
                    setImageViewBitmap(R.id.water_widget_image, bitmap)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
