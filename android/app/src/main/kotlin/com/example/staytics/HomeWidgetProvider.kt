package com.example.staytics

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SmallHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
            widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views =
                    RemoteViews(context.packageName, R.layout.widget_layout_small).apply {
                        val todayHours = widgetData.getString("today_hours", "0.0")
                        val isTracking = widgetData.getBoolean("is_tracking", false)

                        setTextViewText(R.id.widget_today_hours_small, todayHours)
                        setTextViewText(
                                R.id.widget_status_text_small,
                                if (isTracking) "TRACKING" else "IDLE"
                        )

                        // Update status dot color (simulated by changing background or visibility)
                        // For simplicity, we might just toggle visibility or use different
                        // drawables if needed
                    }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class MediumHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
            widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views =
                    RemoteViews(context.packageName, R.layout.widget_layout_medium).apply {
                        val todayHours = widgetData.getString("today_hours", "0.0")
                        val breakTime = widgetData.getString("break_time_minutes", "0m")
                        val breakCount = widgetData.getString("break_count", "0")
                        val progress = widgetData.getInt("progress", 0)
                        val isTracking = widgetData.getBoolean("is_tracking", false)

                        setTextViewText(R.id.widget_today_hours_medium, todayHours)
                        setTextViewText(R.id.widget_break_time_medium, breakTime)
                        setTextViewText(R.id.widget_break_count_medium, breakCount)
                        setProgressBar(R.id.widget_progress_medium, 100, progress, false)

                        setTextViewText(
                                R.id.widget_status_text_medium,
                                if (isTracking) "IN" else "OUT"
                        )
                        // Set color for status text background if possible, or just text color
                    }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
