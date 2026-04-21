package com.example.tedu_qrcode

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MenuWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = HomeWidgetPlugin.getData(context)

        val date    = prefs.getString("flutter.menu_today_date", null)
        val summary = prefs.getString("flutter.menu_today_summary", null)

        val views = RemoteViews(context.packageName, R.layout.menu_widget)

        // Tap the widget → open MainActivity
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.menu_widget_date, pendingIntent)

        if (summary.isNullOrBlank()) {
            // Show empty state, hide all item rows
            views.setViewVisibility(R.id.menu_widget_empty, View.VISIBLE)
            listOf(R.id.menu_item_1, R.id.menu_item_2, R.id.menu_item_3, R.id.menu_item_4)
                .forEach { views.setViewVisibility(it, View.GONE) }
            views.setTextViewText(R.id.menu_widget_date, "—")
        } else {
            views.setViewVisibility(R.id.menu_widget_empty, View.GONE)
            views.setTextViewText(R.id.menu_widget_date, date ?: "")

            val itemIds = listOf(R.id.menu_item_1, R.id.menu_item_2, R.id.menu_item_3, R.id.menu_item_4)
            val lines   = summary.split("\n")

            itemIds.forEachIndexed { index, viewId ->
                val line = lines.getOrNull(index)
                if (!line.isNullOrBlank()) {
                    views.setTextViewText(viewId, "• $line")
                    views.setViewVisibility(viewId, View.VISIBLE)
                } else {
                    views.setViewVisibility(viewId, View.GONE)
                }
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
