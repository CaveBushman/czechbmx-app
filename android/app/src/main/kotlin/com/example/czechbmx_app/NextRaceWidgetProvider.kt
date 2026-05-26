package com.example.czechbmx_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.LocalDate
import java.time.temporal.ChronoUnit

class NextRaceWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs = HomeWidgetPlugin.getData(context)

            val eventName = prefs.getString("next_race_name", null)
            val eventDateStr = prefs.getString("next_race_date", null)

            val views = RemoteViews(context.packageName, R.layout.next_race_widget)

            if (eventName != null && eventDateStr != null) {
                views.setTextViewText(R.id.widget_event_name, eventName)

                val daysLeft = try {
                    val today = LocalDate.now()
                    val eventDate = LocalDate.parse(eventDateStr)
                    ChronoUnit.DAYS.between(today, eventDate)
                } catch (_: Exception) {
                    -1L
                }

                when {
                    daysLeft < 0 -> {
                        views.setTextViewText(R.id.widget_days_number, "–")
                        views.setTextViewText(R.id.widget_days_label, "")
                    }
                    daysLeft == 0L -> {
                        views.setTextViewText(R.id.widget_days_number, "Dnes!")
                        views.setTextViewText(R.id.widget_days_label, "")
                    }
                    else -> {
                        views.setTextViewText(R.id.widget_days_number, daysLeft.toString())
                        views.setTextViewText(R.id.widget_days_label, " dní")
                    }
                }
            } else {
                views.setTextViewText(R.id.widget_event_name, "Žádný závod")
                views.setTextViewText(R.id.widget_days_number, "–")
                views.setTextViewText(R.id.widget_days_label, "")
            }

            // Tap opens the app
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply { putExtra("route", "/events") }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent ?: Intent(),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_event_name, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
