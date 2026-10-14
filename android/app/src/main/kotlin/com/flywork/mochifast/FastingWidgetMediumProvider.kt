package com.flywork.mochifast

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class FastingWidgetMediumProvider : HomeWidgetProvider() {
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
                kind = "medium",
                imageKey = "fasting_widget_medium_image",
                maxWidth = 1000,
                requestCode = 15,
                provider = FastingWidgetMediumProvider::class.java,
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
