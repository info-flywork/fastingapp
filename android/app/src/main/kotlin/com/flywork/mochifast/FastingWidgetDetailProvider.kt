package com.flywork.mochifast

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class FastingWidgetDetailProvider : HomeWidgetProvider() {
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
                kind = "detail",
                imageKey = "fasting_widget_detail_image",
                maxWidth = 1000,
                requestCode = 16,
                provider = FastingWidgetDetailProvider::class.java,
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
