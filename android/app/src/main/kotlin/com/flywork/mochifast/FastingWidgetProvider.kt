package com.flywork.mochifast

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class FastingWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = FastingLive.views(
                context,
                appWidgetManager,
                widgetId,
                widgetData,
                kind = "small",
                imageKey = "fasting_widget_image",
                maxWidth = 700,
                requestCode = 14,
                provider = FastingWidgetProvider::class.java,
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
