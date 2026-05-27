package com.example.czechbmx_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale

private const val TAG = "NextRaceWidget"

class NextRaceWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate: ids=${appWidgetIds.toList()}")
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
            Log.d(TAG, "updateWidget id=$widgetId")
            val views = RemoteViews(context.packageName, R.layout.next_race_widget)
            try {
                val prefs = HomeWidgetPlugin.getData(context)

                val eventName    = prefs.getString("next_race_name", null)
                val eventDateStr = prefs.getString("next_race_date", null)
                val sameDay      = prefs.getInt("next_race_same_day_count", 1)

                Log.d(TAG, "prefs: name=$eventName date=$eventDateStr sameDay=$sameDay")

                if (!eventName.isNullOrBlank() && !eventDateStr.isNullOrBlank()) {
                    val displayName = if (sameDay > 1) "$eventName +${sameDay - 1}" else eventName
                    views.setTextViewText(R.id.widget_event_name, displayName)

                    val daysLeft = try {
                        val today = LocalDate.now()
                        val eventDate = LocalDate.parse(eventDateStr)
                        val fmt = DateTimeFormatter.ofPattern("d. M.", Locale("cs"))
                        views.setTextViewText(R.id.widget_event_date, eventDate.format(fmt))
                        ChronoUnit.DAYS.between(today, eventDate)
                    } catch (e: Exception) {
                        Log.w(TAG, "date parse error: $e")
                        -1L
                    }

                    Log.d(TAG, "daysLeft=$daysLeft")

                    when {
                        daysLeft < 0  -> {
                            views.setTextViewText(R.id.widget_days_number, "–")
                            views.setTextViewText(R.id.widget_days_label, "")
                        }
                        daysLeft == 0L -> {
                            views.setTextViewText(R.id.widget_days_number, "0")
                            views.setTextViewText(R.id.widget_days_label, "dnes!")
                        }
                        daysLeft == 1L -> {
                            views.setTextViewText(R.id.widget_days_number, "1")
                            views.setTextViewText(R.id.widget_days_label, "zítra")
                        }
                        else -> {
                            views.setTextViewText(R.id.widget_days_number, daysLeft.toString())
                            views.setTextViewText(R.id.widget_days_label, "dní")
                        }
                    }
                } else {
                    Log.d(TAG, "no event data → showing placeholder")
                    views.setTextViewText(R.id.widget_event_name, "Žádný závod")
                    views.setTextViewText(R.id.widget_event_date, "")
                    views.setTextViewText(R.id.widget_days_number, "–")
                    views.setTextViewText(R.id.widget_days_label, "")
                }
            } catch (e: Exception) {
                Log.e(TAG, "exception in updateWidget: $e", e)
                views.setTextViewText(R.id.widget_event_name, "Czech BMX")
                views.setTextViewText(R.id.widget_event_date, "Otevřete aplikaci")
                views.setTextViewText(R.id.widget_days_number, "–")
                views.setTextViewText(R.id.widget_days_label, "")
            }

            val launchIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("czechbmx:///events"),
                context,
                MainActivity::class.java
            ).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            Log.d(TAG, "calling updateAppWidget id=$widgetId")
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "updateAppWidget done")
        }
    }
}
